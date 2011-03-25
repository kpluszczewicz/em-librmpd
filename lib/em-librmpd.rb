#!/usr/bin/env ruby

$LOAD_PATH << '.'

require "rubygems"
require "thread"
require "eventmachine"

require "connection.rb"


# Main class em-libmpd library
class MPD 
  attr_accessor :player, :current_song

  def initialize(address = "localhost", port = 6600)
    @player = nil
    @address = address
    @port = port
  end

  # Connection functions

  def connect
    # EM needs to be run in new thread
    @player_thread = Thread.new do
      EM.run do
        EM.set_quantum 5

        EM.connect(@address, @port, Connection) do |c|
          @player = c
        end #-- em_connect

        #EM.add_periodic_timer(1) {
          #puts Time.new
        #}
      end #-- em_run
    end #-- player_thread
  end

  def disconnect
    @player.close_connection
  end

  def connected?
    @player.connected?
  end

  def state
    @player.state
  end

  # Player functions

  def pause
    if state != "stop"
      if state == "play"
        @player.hb_difference = Time.new.to_f - @player.hb_time
        @player.hb_difference = @player.hb_difference.ceil - @player.hb_difference
        @player.elapsed += 1
      end

      method "pause"
      @player.state_change "pause"
    end
  end

  def play
    if state != "play"
      @player.state_change "play"
      method "play"
    end
  end

  def next
    @player.elapsed = 0
    method "next"
  end

  def previous
    @player.elapsed = 0
    method "previous"
  end

  def stop
    if state != "stop"
      @player.elapsed = 0
      @player.state_change "stop"
      method "stop"
    end
  end

  def playlist
    @player.playlist
  end

  def current_song
    @player.current_song
  end
  
  private

  def method(cmd)
    #debug "\t-#{__method__}"
    @player.execute cmd
  end

end


