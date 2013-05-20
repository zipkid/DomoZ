#!/usr/bin/env ruby
require 'rubygems'        # if you use RubyGems
require 'daemons'
require 'yaml'
require 'time'

#require File.expand_path(File.join(File.dirname(__FILE__), 'lib/google_oauth2'))
#require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/conf'))
#require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/calendar'))
#require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/owSnmp'))
#require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/wiringpi'))

debug = ARGV[0]

# Prepend RUBYLIB with our own libdir
$:.unshift File.join( %w{ . lib } )
$:.unshift File.join( %w{ . domoz } )

require 'google_oauth2'
require 'conf'
require 'calendar'
require 'owSnmp'
require 'wiringpi'

require 'pp'

path = File.expand_path(File.dirname(__FILE__))
#config_path = File.expand_path(File.join(File.dirname(__FILE__), 'config'))
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

#puts "Got Auth, now move on"

start_time = Time.now
thermostat_exec_time = Time.at(0)

lower_drop_temp = 0.5
higher_rise_temp = 0.5 

thermostat_loop_time = 30

calendar = nil
ows = nil
wpi = nil


@wanted_temp = 0
@curr_temp = 0
@curr_msg = 'No current temperature data yet...'
@curr_description = 'Description not set yet'

ows_thread = Thread.new do
  snmp_exec_time = Time.at(0)
  snmp_loop_time = 5
  while true
    if( (Time.now - snmp_exec_time) > snmp_loop_time )
      ows = Domoz::OwSnmp.new
      temp_data = ows.get_temp
      
      pp temp_data

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
    end
  end
end

cal_thread = Thread.new do
  cal_exec_time = Time.at(0)
  cal_loop_time = 120
  cal_loop_time = 60
  while true
    if( (Time.now - cal_exec_time) > cal_loop_time )
      calendar = Domoz::Calendar.new( :configpath => config_path, :wanted_temp => @wanted_temp )
      @wanted_temp = calendar.get_wanted_temp
      calendar.set_current_msg( @curr_msg, @curr_description )
      puts "Calendar run finished - #{@wanted_temp}"
      cal_exec_time = Time.now
    end
  end
end

out = Thread.new do
  while true
    sleep 3
    puts "...... - Wanted_temp  : #{@wanted_temp}"
    puts "...... - Current_temp : #{@current_temp}"
  end
end


cal_thread.join
ows_thread.join
out.join



#while true
while false

  ows = Domoz::OwSnmp.new if ! ows
  wpi = Domoz::WiringPiDomoz.new( :pins => [ 0, 1 ] ) if ! wpi

  if calendar.get_auth

    if( (Time.now - snmp_exec_time) > snmp_loop_time )
      temp_data = ows.get_temp
      sensors = config[:sensors]
      msg = ''
      description = ''
      if temp_data
        temp_data.each do |t|
          rom = t[:owDeviceROM] 
          if sensors[rom.to_sym][:main] == true
            msg = t[:owDS18S20Temperature]
            current_temp = t[:owDS18S20Temperature].to_f
          end
          description += sensors[rom.to_sym][:name]
          description += " : "
          description +=  t[:owDS18S20Temperature] 
          description +=  "\n"
        end
      end
      snmp_exec_time = Time.now
    end

    if( (Time.now - cal_exec_time) > cal_loop_time )
      wanted_temp = calendar.get_wanted_temp.to_f
      calendar.set_current_msg( msg, description )
      config[:oauth2] = oauth.to_hash
      conf.save_conf
      cal_exec_time = Time.now
    end

    if( (Time.now - thermostat_exec_time) > thermostat_loop_time )

      puts "#{current_temp}  #{wanted_temp} - #{lower_drop_temp}  or + #{higher_rise_temp}"
      # thermostat decision
      if current_temp <= ( wanted_temp - lower_drop_temp )
        if ! wpi.active?
          puts "#{Time.now}: Current: #{current_temp} - Wanted: #{wanted_temp} - #{lower_drop_temp} (#{wanted_temp - lower_drop_temp}) : Activating... " 
          wpi.activate
        end
      elsif current_temp >= ( wanted_temp + higher_rise_temp )
        if wpi.active?
          puts "#{Time.now}: Current: #{current_temp} - Wanted: #{wanted_temp} + #{higher_rise_temp} (#{wanted_temp + higher_rise_temp}) : Deactivating..."
          wpi.deactivate
        end
      end
      thermostat_exec_time = Time.now
    end

    sleep 1
  end  
end

