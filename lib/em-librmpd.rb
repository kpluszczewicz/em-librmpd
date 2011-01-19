require "rubygems"
require "thread"
require "eventmachine"
require "gtk2"

def debug(msg)
  puts "[DEBUG:: #{msg}]"
end

class Connection < EventMachine::Connection
  def initialize *args
    super args
    @callbacks = []
    @stack = []
  end

  def receive_data(msg)
    debug "receive_data"
    puts msg
    if @stack.empty?
      # To znaczy, że callback
      debug "Wykonujemy funkcje zwrotna"
      send_data("idle\n");
    else
      # To znaczy, że cos zrobilismy
      action = @stack.pop
      # Zrob cos
      unless action != "noidle"
        # Wykonaj callback
        debug "Pobieramy wyniki"
        debug "Wyniki:"
        puts msg
        send_data("idle\n");
      else
        debug "Noidle - ok"
      end
    end
  end

  def execute(msg)
    debug "execute(#{msg})"
    @stack.push "noidle", msg
    send_data("noidle\n#{msg}\n")
  end

end

class MPD 
  attr_accessor :player, :current_song


  def initialize(address = "localhost", port = 6600)
    @player = nil
    @address = address
    @port = port
    @current_song = nil
  end

  def connect
    @player_thread = Thread.new do
      EM.run do
        EM::connect @address, @port, Connection do |c|
          debug "new connection"
          @player = c
        end #-- em_connect
      end #-- em_run
    end #-- player_thread
  end

  def disconnect
    EM.stop_event_loop
  end

  def pause
    @player.execute "pause"
  end

  def play
    @player.execute "play"
  end

  def next
    @player.execute "next"
  end

  def previous
    @player.execute "previous"
  end

  def stop
    @player.execute "stop"
  end

  def get_playlist
    @player.execute ""
  end

  def playlist
    
  end

end


