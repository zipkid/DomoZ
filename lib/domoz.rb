# encoding: utf-8
require 'domoz/version'

class Domoz
  # Your code goes here...
  def initialize(*_options)
    @stop = false

    # ows
    # calendar
    # wiringpi
    # calc the lot
  end

  def stop
    @stop = true
    sleep 2
  end

  def run
    loop do
      return if @stop
      sleep 0.1
    end
  end


end
