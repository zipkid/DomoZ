#!/usr/bin/env ruby
#


class Test1

end

class Test2

end


reader, writer = IO.pipe

#writer.write("Into the pipe I go...")
#writer.close
#puts reader.read

fork do
  reader.close
  
  10.times do
    # heavy lifting
    sleep 1
    writer.puts "Another one bites the dust"
  end
end

writer.close
while message = reader.gets
  $stdout.puts message
end


t1 = Test1.new
t2 = Test2.new

