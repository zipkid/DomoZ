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

path = File.expand_path(File.dirname(__FILE__))
config_path = File.expand_path(File.join(File.dirname(__FILE__), 'config'))

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
snmp_exec_time = Time.at(0)
cal_exec_time = Time.at(0)
thermostat_exec_time = Time.at(0)

lower_drop_temp = 0.5
higher_rise_temp = 0.5 

snmp_loop_time = 5
cal_loop_time = 120
thermostat_loop_time = 30

#conf_domoz = Conf.new( :path => config_path, :file => 'domoz' ) if ! conf_domoz
#conf_oauth = Conf.new( :path => config_path, :file => 'domoz-oauth' ) if ! conf_oauth

oauth = nil
calendar = nil
ows = nil
wpi = nil

calendar = Domoz::Calendar.new( :configpath => config_path )

while true

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

