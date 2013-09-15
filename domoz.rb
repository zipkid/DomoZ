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

@wanted_temp = 0
@curr_temp = 0
@curr_msg = ''
@curr_description = ''

run_ows = true
#run_ows = false
run_cal = true 
#run_cal = false 
run_wpi = true 
#run_wpi = false

if run_ows
  ows_thread = Thread.new do
    snmp_exec_time = Time.at(0)
    snmp_loop_time = 10
    while true
      if( (Time.now - snmp_exec_time) > snmp_loop_time )
        puts "starting OWS Run"
        ows = Domoz::OwSnmp.new
        temp_data = ows.get_temp
        
        conf = Domoz::Conf.new( :path => config_path, :file => 'domoz' )
        config = conf.conf
        sensors = config[:sensors]

        msg = ''
        description = ''
        if temp_data
          temp_data.each do |t|
            rom = t[:owDeviceROM] 
            if sensors[rom.to_sym][:main] == true
              @curr_msg = t[:owDS18S20Temperature]
              @curr_temp = t[:owDS18S20Temperature].to_f
            end
            description += sensors[rom.to_sym][:name]
            description += " :::: "
            description +=  t[:owDS18S20Temperature] 
            description +=  "\n"
            @curr_description = description
          end
        end
        snmp_exec_time = Time.now
        puts "OWS run finished"
      end
    end
  end
end

if run_cal
  cal_thread = Thread.new do
    cal_exec_time = Time.at(0)
    cal_loop_time = 120
    cal_loop_time = 30
    while true
      if( (Time.now - cal_exec_time) > cal_loop_time )
        puts "Starting Calendar run"
        calendar = Domoz::Calendar.new( :configpath => config_path, :wanted_temp => @wanted_temp )
        @wanted_temp = calendar.wanted_temp
        if ! @curr_msg.empty? 
          calendar.set_current_msg( @curr_msg, @curr_description )
        end
        cal_exec_time = Time.now
        puts "Calendar run finished - #{@wanted_temp}"
      end
    end
  end
end

if run_wpi
  wpi_thread = Thread.new do
    thermostat_exec_time = Time.at(0)
    thermostat_loop_time = 30

    lower_drop_temp = 0.5
    higher_rise_temp = 0.5 
    while true
      if( (Time.now - thermostat_exec_time) > thermostat_loop_time )
        puts "Starting WiPi run"

        wpi = Domoz::WiPi.new( :pins => [ 0 ] )
        led = Domoz::WiPi.new( :pins => [ 5 ] )
        #wpi.test_ports

        puts "#{Time.now}: #{@curr_temp}  #{@wanted_temp} - #{lower_drop_temp}  or + #{higher_rise_temp}"
        # thermostat decision
        if @curr_temp <= ( @wanted_temp - lower_drop_temp )
          if ! wpi.low?
            puts "#{Time.now}: Current: #{@curr_temp} - Wanted: #{@wanted_temp} - #{lower_drop_temp} (#{@wanted_temp - lower_drop_temp}) : Activating... " 
            wpi.low
            led.high
          end
        elsif @curr_temp >= ( @wanted_temp + higher_rise_temp )
          if wpi.low?
            puts "#{Time.now}: Current: #{@curr_temp} - Wanted: #{@wanted_temp} + #{higher_rise_temp} (#{@wanted_temp + higher_rise_temp}) : Deactivating..."
            wpi.high
            led.low
          end
        end
        thermostat_exec_time = Time.now
        puts "WiPi run finished"
      end 
    end
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
