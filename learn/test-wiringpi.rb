#!/usr/bin/env ruby
require 'rubygems'        # if you use RubyGems
require 'getoptlong'

#$:.unshift File.join( %w{ .. domoz } )

require 'wiringpi'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--debug', '-d', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--pin', '-p', GetoptLong::REQUIRED_ARGUMENT ],
)

pin = nil

debug = ARGV[0]
opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
domoz.rb [OPTION]

-h, --help:
   show help

--debug [level]:
  Debug level
      EOF
    when '--debug'
      if arg == ''
        debug = 1
      else
        debug = arg
      end
    when '--pin'
     pin = arg
  end
end

pin = pin.to_i

io = WiringPi::GPIO.new
io.mode( pin, OUTPUT )
io.write( pin, LOW )
read = io.read( pin )
puts "read : #{read}"
h = io.readAll
puts h.inspect
sleep 1
io.write( pin, HIGH )
read = io.read( pin )
puts "read : #{read}"
h = io.readAll
puts h.inspect

#wpi = Domoz::WiringPiDomoz.new( :pins => [ pin ] )

#wpi.activate

#sleep 3

#wpi.deactivate

