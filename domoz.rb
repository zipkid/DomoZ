#!/usr/bin/env ruby
require 'rubygems'        # if you use RubyGems
require 'daemons'
require 'yaml'
require 'time'
require 'getoptlong'
require 'wiringpi'


# Prepend RUBYLIB with our own libdir
$:.unshift File.join( %w{ . domoz } )

require 'conf'
require 'calendar'
require 'owSnmp'
require 'wipi'

require 'pp'


opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--debug', '-d', GetoptLong::OPTIONAL_ARGUMENT ]
)

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
  end
end


path = File.expand_path(File.dirname(__FILE__))
config_path = File.join( path, 'config')

options = {
  :backtrace  => true,
  :app_name   => 'domoz',
  :ontop      => debug,
  :log_output => true,
  :dir_mode   => :normal,
  :dir        => '.',
  :log_output => true
}

Daemons.daemonize(options)

@activate_heater = false

run_calc = true

run_ows = true
run_cal = true 
run_wpi = true 

if run_ows
  ows = Domoz::OwSnmp.new
  ows.loop_time = 20
  ows.run
end

if run_cal
  calendar = Domoz::Calendar.new( :configpath => config_path )
  calendar.loop_time = 60
  calendar.run
end

if run_wpi
  wpi_thread = Thread.new do
    thermostat_exec_time = Time.at(0)
    thermostat_loop_time = 5

    lower_drop_temp = 0.5
    higher_rise_temp = 0.5 
    while true
      if( (Time.now - thermostat_exec_time) > thermostat_loop_time )
        puts "+ WiPi run"

        wpi = Domoz::WiPi.new( :pins => [ 0 ] )
        led = Domoz::WiPi.new( :pins => [ 5 ] )
        if @activate_heater
          if ! wpi.low?
            puts "#{Time.now}: Activating" 
            wpi.low
            led.high
          end
        elsif ! @activate_heater
          if wpi.low?
            puts "#{Time.now}: Deactivating"
            wpi.high
            led.low
          end
        end
        thermostat_exec_time = Time.now
        puts "- WiPi run"
      end 
    end
  end
end

if run_calc
  lower_drop_temp = 0.5
  higher_rise_temp = 0.5 
  current_temperature = 20
  message = ''
  while true
    puts '================================================='

    conf = Domoz::Conf.new( :path => config_path, :file => 'domoz' )
    config = conf.conf
    sensors = config[:sensors]
    sensor_data = Hash.new

    puts " = Last OWS update time: #{ows.update_time}"
    description = ''
    cnt = 0
    ows.devices_data.each do |t|
      cnt += 1
      puts "cnt:#{cnt}"
      rom = t[:owDeviceROM] 
      if sensors[rom.to_sym][:main] == true
        message = t[:owDS18S20Temperature]
        current_temperature = t[:owDS18S20Temperature].to_f
        calendar.message = message.dup
      end
      description += sensors[rom.to_sym][:name]
      description += " :::: "
      description +=  t[:owDS18S20Temperature] 
      description +=  "\n"
      sensor_data[sensors[rom.to_sym][:name].to_sym] = t[:owDS18S20Temperature]
    end
    calendar.description = description.dup

    wanted_temperature = calendar.wanted_temp

    puts " = #{Time.now}: #{current_temperature}  #{wanted_temperature} - #{lower_drop_temp}  or + #{higher_rise_temp}"
    if current_temperature <= ( wanted_temperature - lower_drop_temp )
      if ! @activate_heater
        @activate_heater = true
        puts " = Activation needed"
      end
    elsif current_temperature >= ( wanted_temperature + higher_rise_temp )
      if @activate_heater
        @activate_heater = false
        puts " = De-Activation needed"
      end
    end


    puts '================================================='
    sleep 5
  end
end

if run_ows
  ows_thread.join
end
if run_cal
  cal_thread.join
end
if run_wpi
  wpi_thread.join
end
