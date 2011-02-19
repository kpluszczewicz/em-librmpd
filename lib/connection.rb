require "rubygems"
require "eventmachine"

def debug(msg)
  puts ":: #{msg}"
end

class Connection < EventMachine::Connection
  # needed
  attr_accessor :playlist, :current_song, :state
  attr_accessor :volume, :repeat, :random
  attr_accessor :elapsed, :total

  # helpers
  attr_accessor :queue

  def initialize
    super 
    debug "\t\t-new connection"
    a = %w[connection playlist playlistinfo status
    idle noidle idle_after_our_action 
    stop pause play]

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
    puts "------------"
    puts msg
    puts "------------"

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

  def state_change(command)
    current_state = @state
    if command == "pause"
      if current_state == "play" 
        cancel_timer
        @state = "pause"
      else
        start_timer
        @state = "play"
      end
    elsif command == "stop"
      @state = "stop"
      cancel_timer
    elsif command == "play"
      start_timer
      @state = "play"
    end

  end

  def test
    puts "TEST"
  end

  private

  def cancel_timer
    if @timer
      @timer.cancel
      @timer = nil
    end
  end

  def start_timer
    @timer = EM::PeriodicTimer.new(1) do
      puts Time.now
    end
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

    puts "PlAYLISTA: " + a.inspect
    @playlist = a
  end

  def handle_playlist(msg)
    a = []
    song = {}

    msg.each_line { |line| 
      i, type, file = line.split ":"
      song[id] = i
      song[type] = type
      song[file] = file[1..-1]
      a.push song
    }

    @playlist["songs"] = a
    puts a.inspect
  end


  def handle_status(msg)
    status = {}
    msg.each_line { |line| 
      k, v = line.split ": "
      status[k] = v[0..-2]
    }

    # If there is a song in list that is current
    if status["song"]
      @current_song = status["song"]
      @current_songid = status["songid"].to_i
      @bitrate = status["bitrate"].to_i
    end

    @volume = status["volume"].to_i
    @repeat = status["repeat"] == "1" ? true : false
    @random = status["random"] == "1" ? true : false
    @playlist["length"] = status["playlistlength"].to_i
    @playlist["version"] = status["playlist"].to_i
    @state = status["state"]

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
      @queue.push "idle"

      #send_command "status"
      send_command "idle"
    end
  end

  def handle_idle_after_our_action(msg)
    @queue.push "idle"
    send_command "idle"
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

end
