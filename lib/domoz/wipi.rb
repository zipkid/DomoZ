module Domoz

  class WiPi
    require 'rubygems'
    require 'wiringpi'


    attr_accessor :active, :pins

    def initialize args
      @pins = args[:pins]

      @io = ::WiringPi::GPIO.new
      @pins.each {|p| @io.mode( p, OUTPUT ) }
    #rescue => e
      #puts e.message
    end

    def high
      @pins.each {|p| @io.write( p, HIGH ) }
    end

    def high?
      @io.read( @pins[0] ) == HIGH
    end

    def low?
      @io.read( @pins[0] ) == LOW
    end

    def low
      @pins.each {|p| @io.write( p, LOW ) }
    end

    def test
      io = ::WiringPi::GPIO.new
      pin = 0
      io.mode( pin, OUTPUT )
      io.write( pin, HIGH )
      read = io.read( pin )
      puts "read : #{read}"
      h = io.readAll
      puts h.inspect
      sleep 1
      io.write( pin, LOW )
      read = io.read( pin )
      puts "read : #{read}"
      h = io.readAll
      puts h.inspect
    end
  end
end

