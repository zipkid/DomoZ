#!/usr/bin/env ruby

#http://www.jstorimer.com/2012/04/19/intro-to-ruby-ipc.html

require 'socket'
include Socket::Constants

require 'rubygems'        # if you use RubyGems
require 'daemons'

child_socket, parent_socket = Socket.pair( AF_UNIX, SOCK_DGRAM, 0 )
maxlen = 1000

puts "hi"

task1 = Daemons.call do
  # first server task

  puts "d hi 1"

  parent_socket.close
  10.times do
    instruction = child_socket.recv(maxlen)
    child_socket.send("#{instruction} accomplished!", 0)
  end 

end

puts "hi 2"

# the parent process continues to run

#fork do
#  parent_socket.close
#  10.times do
#    instruction = child_socket.recv(maxlen)
#    child_socket.send("#{instruction} accomplished!", 0)
#  end 
#end 
child_socket.close

puts "hi 3"

5.times do
  parent_socket.send("Heavy lifting", 0)
end 

puts "hi 4"

5.times do
  parent_socket.send("Feather lifting", 0)
end 

puts "hi 5"

10.times do
  puts "hi 55"
  $stdout.puts parent_socket.recv(maxlen)
end 

puts "hi 6"

# we can even control our tasks, for example stop them
task1.stop

