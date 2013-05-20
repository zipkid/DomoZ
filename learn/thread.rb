#!/usr/bin/ruby

@cnt = 0

def func1
  sleep(1)
  @cnt += 1
  puts "func1 at: #{Time.now} - setting #{@cnt}"
end

def func2
  sleep(5)
  puts "func2 at: #{Time.now} - using #{@cnt}"
end

while true
  puts "Started At #{Time.now}"
  
  t1=Thread.new{func1()}
  t2=Thread.new{func2()}
  sleep 1
end

t1.join
t2.join
puts "End at #{Time.now}"

