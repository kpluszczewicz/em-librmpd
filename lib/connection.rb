require "rubygems"
require "eventmachine"

def debug(msg)
  puts ":: #{msg}"
end

class Connection < EventMachine::Connection
  # needed
  attr_accessor :current_song, :state, :playlist
  attr_accessor :volume, :repeat, :random
  attr_accessor :elapsed, :total

  # helpers
  attr_accessor :queue
  attr_accessor :hb_difference, :hb_time

  def initialize
    super 
    debug "\t\t-new connection"
    a = %w[connection playlist playlistinfo status
    idle noidle idle_after_our_action 
    stop pause play next previous]

    @actions = {}
    a.each { |e| @actions[e] = self.method("handle_" + e) }

    @callbacks = []
    @connected = false
    @queue = EM::Queue.new

    debug "connection"
    @queue.push "connection"
  end

  # Instead of polling mpd's state, use 'idle' command
  def connection_completed
    debug "\t\t-connection_completed"
    @playlist = {}

    a = %w[status playlistinfo idle]
    a.each { |e| @queue.push e }
    a.each { |e| send_command e }
    @connected = true
  end

  # Perform actions on new data from server
  def receive_data(msg)
    debug "\t\t-receive_data"
    debug "------------"
    debug msg
    debug "------------"

    msgs = split_message msg
    debug "How many messages: #{msgs.size}"

    msgs.each { |msg|
      debug "Each #{msg}"

      @queue.pop { |action|
        debug "pop #{action}"
        @actions[action].call(msg)
        debug "po pop #{action}"
      }
    }
  end

  def unbind
    debug "Poszlo w dupe *****)#($&*@#"
    @connected = false
  end

  def execute(msg)
    debug "\t\t-execute(#{msg})"

    @queue.push "noidle"
    @queue.push msg

    debug "noidle\n#{msg}\n"
    send_command "noidle"
    send_command msg
  end

  def connected?
    @connected
  end

  def state_change(command=nil)
    @ticks = 0
    current_state = @state
    if command
      if command == "pause"
        if current_state == "play" 
          cancel_ticker
          @state = "pause"
        else
          schedule_ticker
          @state = "play"
        end
      elsif command == "stop"
        @state = "stop"
        cancel_ticker
      elsif command == "play"
        if current_state == "stop"
          start_ticker
        else
          schedule_ticker
        end
        @state = "play"
      end
    else
      if current_state == "play"
        cancel_ticker
        schedule_ticker
      else
        cancel_ticker
      end
    end

  end

  def test
    puts "TEST"
  end

  private

  def cancel_ticker
    if @ticker
      @ticker.cancel
      @ticker = nil
    end

    if @scheduled_ticker
      @scheduled_ticker.cancel
    end
  end

  def schedule_ticker
    if ! @ticker
      puts "DIFFERENCE #{@hb_difference}"
      @elapsed = @elapsed.ceil
      @dupa = Time.new.to_f
      puts "dupa #{@dupa}"
      if @hb_difference > 0.1
        puts "Shot Timer"
        m = @elapsed / 60
        s = @elapsed % 60
        @scheduled_ticker = EM::Timer.new(@hb_difference) { 
          puts "ELAPSED TIME: #{m}:#{s} (#{@elapsed}), time #{@dupa}"
          start_ticker
        }
      else
        start_ticker
      end # @difference
    end # @ticker
  end

  def start_ticker
      @ticks = 0
      @ticker = EM::PeriodicTimer.new(1) do
        @hb_time = Time.new.to_f
        @ticks += 1 
        @elapsed += 1
        m = @elapsed / 60
        s = @elapsed % 60
        @dupa = Time.new.to_f - @dupa
        puts "ELAPSED TIME: #{m}:#{s} (#{@elapsed}), beats: #{@ticks}, time #{@dupa}"
        if @ticks > 15
          execute "status"
          send_idle
          @ticks = 0
        end
      end # EM::PeriodicTimer
  end

  def send_command(cmd)
    debug "SEND : #{cmd}"
    send_data cmd + "\r\n"
  end

  def split_message(msg)
    messages = []
    str = ""
    msg.each_line { |line| 
      if line =~ /^OK.*$/
        messages.push str
      else
        str += line
      end
    }
    return messages
  end

  def handle_playlistinfo(msg)
    return if msg == "" 

    a = []
    song = {}
    msg.each_line do |line| 
      key, value = line.split ': '
      song[key] = value[0..-2]
      if line =~ /^Id:/
        a.push song
        song = {}
      end
    end

    debug "PlAYLISTA: " + a.inspect
    @playlist["songs"] = a
  end

  def handle_playlist(msg)
    a = []
    song = {}

    msg.each_line { |line| 
      i, type, file = line.split ":"
      song[id], song[type], song[file] = i, type, file[1..-1]
      a.push song
    }

    @playlist["songs"] = a
    debug a.inspect
  end

  def handle_next(msg)
  end

  def handle_previous(msg)
  end

  def handle_status(msg)
    debug "1"
    status = {}
    msg.each_line { |line| 
      k, v = line.split ": "
      status[k] = v[0..-2]
    }


    # If there is a song in list that is current
    if status["song"]
      @current_song = status["song"].to_i
      @current_songid = status["songid"].to_i
      @bitrate = status["bitrate"].to_i
      @elapsed = status["elapsed"].to_f
      @hb_difference = @elapsed.ceil - @elapsed
    end

    puts "#{Time.new.to_f}"
    @state = status["state"]
    state_change

    @volume = status["volume"].to_i
    @repeat = status["repeat"] == "1" ? true : false
    @random = status["random"] == "1" ? true : false

    @playlist["version"] = status["playlist"].to_i
    @playlist["length"] = status["playlistlength"].to_i

    puts status.inspect
  end

  def handle_connection(msg)
    debug "action: Connection"
  end

  def handle_idle(msg)
    if msg == ""
      debug "Noidle when idle"
      @queue.pop { |el| puts "tak to jest" }
    else
      debug "WE HAVE A SITUATION HERE! EXTERNAL ACTION!"
      # Maybe there is a need to update data
      # But for now send idle

      #@queue.push "status"
      changed = msg.split ": "
      if changed[1] = "player\n"
        @queue.push "status"
        send_command "status"
      end

      send_idle

    end
  end

  def handle_idle_after_our_action(msg)
    send_idle
  end

  def handle_noidle(msg)
    debug "Don't be lazy"
  end

  def handle_pause(msg)
    @queue.push "idle_after_our_action"
    send_command "idle"
  end

  def handle_play(msg)
    @queue.push "idle_after_our_action"
    send_command "idle"
  end

  def handle_stop(msg)
    @queue.push "idle_after_our_action"
    send_command "idle"
  end

  def send_idle
      @queue.push "idle"
      send_command "idle"
  end

end
