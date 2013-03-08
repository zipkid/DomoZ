#!/usr/bin/env ruby
require 'rubygems'        # if you use RubyGems
require 'daemons'
require 'yaml'
require 'time'

debug = ARGV[0]

require File.expand_path(File.join(File.dirname(__FILE__), 'lib/google_oauth2'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib/conf'))
require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/calendar'))
require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/owSnmp'))
require File.expand_path(File.join(File.dirname(__FILE__), 'domoz/wiringpi'))

$path = File.expand_path(File.dirname(__FILE__))

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

conf = nil
oath = nil
calendar = nil
ow = nil
wp = nil

while true

  # load settings
  conf = Conf.new( $path ) if ! conf
  config = conf.conf

  current_temp ||= 0
  wanted_temp ||= config[:thermostat][:minimum_temp]

  lower_drop_temp = 0.5
  higher_rise_temp = 0.5 

  # if mtime settings file .... hmm?  

  snmp_loop_time = 5
  cal_loop_time = 120
  thermostat_loop_time = 30

  oauth = Google_oauth2.new( config[:credentials].merge( config[:oauth2] ) ) if ! oath
  calendar = Domoz::Calendar.new( 
                                 :calendar_id => config[:calendar][:calendar_id], 
                                 :oauth => oauth,
                                 :wanted_temp => wanted_temp
                                ) if ! calendar
  ow = Domoz::OwSnmp.new if ! ow
  wp = Domoz::WiringPiDomoz.new( :pins => [ 0, 1 ] ) if ! wp

  if oauth.get_auth

    if( (Time.now - snmp_exec_time) > snmp_loop_time )
      temp_data = ow.get_temp
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
        if ! wp.active?
          puts "#{Time.now}: Current: #{current_temp} - Wanted: #{wanted_temp} - #{lower_drop_temp} (#{wanted_temp - lower_drop_temp}) : Activating... " 
          wp.activate
        end
      elsif current_temp >= ( wanted_temp + higher_rise_temp )
        if wp.active?
          puts "#{Time.now}: Current: #{current_temp} - Wanted: #{wanted_temp} + #{higher_rise_temp} (#{wanted_temp + higher_rise_temp}) : Deactivating..."
          wp.deactivate
        end
      end
      thermostat_exec_time = Time.now
    end

    sleep 1
  end  
end

