# encoding: utf-8
require 'domoz/version'
require 'domoz/calculator'
require 'domoz/calendar'
require 'domoz/ows'
require 'domoz/wiringpi'

class Domoz
  # Your code goes here...
  def initialize(*_options)
    @running = false
    @stop = false
    @threads = {
      ows: nil,
      wiringpi: nil,
      calendar: nil,
      calculator: nil
    }

    # ows
    # calendar
    # wiringpi
    # calc the lot
  end

  def stop
    p 'stop request recieved'
    @stop = true
  end

  def stopped?
    @running == false
  end

  def run
    @threads.each do |k, _|
      @threads[k] = Thread.new do
        start_plugin k
      end
    end

    @threads.each do |_, t|
      t.join
    end
    monitor_threads
  end

  def start_plugin(name)
    class_name = "Domoz::#{name.capitalize}"
    puts "Plugin #{class_name} starting"
    obj = Object.const_get(class_name).new
    obj.run
  end

  def monitor_threads
    loop do
      puts "1 stop .#{@stop}"
      @threads.each do |_, t|
        if @stop
          p t.status
          # send stop to all threads
          # wait for join
        else
          p t.status
        end
      end
      puts "2 stop .#{@stop}"
      sleep 0.1
    end
  end
end
