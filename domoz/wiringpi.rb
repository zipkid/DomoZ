module Domoz
  require 'rubygems'

  class WiringPiDomoz

    attr_accessor :active, :pins

    def initialize args
      require 'wiringpi'
      @pins = args[:pins]
      @io = WiringPi::GPIO.new
      @pins.each {|p| @io.mode( p, OUTPUT ) }
    rescue => e
      puts e.message
    end

    def activate
      @pins.each {|p| @io.write( p, HIGH ) }
    end

    def active?
      @io.read( @pins[0] ) == 1
    end

    def deactivate
      @pins.each {|p| @io.write( p, LOW ) }
    end

    def test
      io = WiringPi::GPIO.new
      pin = 0
      io.mode( pin, OUTPUT )
      io.write( pin, HIGH )
      read = io.read( pin )
      puts "read : #{read}"
      sleep 1
      io.write( pin, LOW )
      read = io.read( pin )
      puts "read : #{read}"
      h = io.readAll
      puts h.inspect
    end
  end
end

