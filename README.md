# Em-librmpd
Copyright (C) 2011 by Kamil Pluszczewicz

Em-librmpd is a going to be simple, powerful, event-oriented library for the
[Music Player Daemon](http://www.musicpd.org), written in Ruby.

# Goals 

Em-librmpd in opposite to the most known mpd ruby library 'librmpd', uses eventmachine to communite to mpd daemon. 

The old librmpd uses polling to execute it's callbacks. That trick simply generates much net traffic. That is the main reason i decided to write another mpd library.

## Progress level

At the time being, em-librmpd make possible to succesfully establish connection to mpd daemon. You can perform simple operations, such as play, pause, stop, next, previous. Also playlist is available as a ruby hash. 

Methods implemented so far:

- play
- pause
- next
- previous
- stop
- get\_playlist
- connect
- disconnect

## MPD Potocol ##

The Music Player Daemon protocol is implemented in the MPD class. This class
contains most of the commands used in communicating with the server. Some of
the commands were removed/modified to make the usage more transparent. Gone
are the confusing `lsinfo` and `listallinfo` variations on listing data
from the server. Instead these are replaced with straightforward methods,
such as `artists` to get all artists and `songs` to get all songs.

## Usage ##

All functionality is contained in the MPD class. Creating an instance of this
class is as simple as

    require 'rubygems'
    require 'librmpd-em' # when this library is shipped as a gem ;)
    
    mpd = MPD.new 'localhost', 6600

(params 'localhost' and 6600 are default)

Once you have an instance of the MPD class, start by connecting to the server:

    mpd.connect

When you are done, disconnect by calling disconnect

    mpd.disconnect

## Aims and vision

In em-librmpd, main mechanism to communicate with server, are intended to be callback functions. I plan to implement bunch of them, to minimize front-end programmers effort. When I was working with old 'librmpd', i found some methods pretty problematic. For example: user stops player, apropriate message is sent to server, then callback is executed and player app status is changed from playing to stopped. This is something weird. In my opinion, it would be better, if user application reacts as a first, and then message would be sent to server. In a brief: don't execute callbacks on own application. Instead: perform action, then send message to mpd. In old librmpd there were also problems with callbacks loopping - in other words: action, then callback, then callback to previous callback and so on. This forces programmer to perform additional protective coding.

Em-librmpd is going to be as simple and intuitive as possible. And no additional, redundant coding.

# License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
