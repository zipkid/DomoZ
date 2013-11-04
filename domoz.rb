#!/usr/bin/env ruby
require 'rubygems'        # if you use RubyGems
require 'daemons'
require 'yaml'
require 'time'
require 'getoptlong'
require 'wiringpi'
require 'net/http'
require 'json'
require 'pp'

# Prepend RUBYLIB with our own libdir
#require File.expand_path(File.join(File.dirname(__FILE__), 'conf'))
$:.unshift File.join( File.dirname(__FILE__), 'lib' )
$:.unshift File.join( File.dirname(__FILE__), 'lib', 'domoz' )

require 'conf'
require 'calendar'
require 'owSnmp'
require 'wipi'

Thread.abort_on_exception=true

threads = Hash.new

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
  :ontop      => debug,
  :backtrace  => true,
  :app_name   => 'domoz',
  :log_output => true,
  :dir_mode   => :normal,
  :dir        => '.',
}

Daemons.daemonize(options)

def post_to_dashing hash 
  begin
    @host = 'domoz.zipkid.eu'
    @port = '3030'

    @post_ws = "/widgets/#{hash[:widget]}"

    hash[:auth_token] = "TAXdJCicponbq8BEfoWibx2abjsjqW"

    @payload = hash.to_json

    req = Net::HTTP::Post.new(@post_ws, initheader = {'Content-Type' =>'application/json'})
    req.body = @payload
    response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
  rescue => e
    puts "#{Time.now}: #{__LINE__} - #{e.class} : #{e.message}"
  end
end

@wanted_temperature = 15
@activate_heater = false

run_ows = true
run_cal = true 
run_wpi = true 
run_calc = true

@ows = nil
@calendar = nil

begin 
  if run_ows
    threads[:ows] = Thread.new do
      begin
        @ows = Domoz::OwSnmp.new
        @ows.loop_time = 20
        @ows.run
      rescue => e
        puts "#{__LINE__} - #{e.class} : #{e.message}"
        puts e.backtrace
      end
    end
  end

  if run_cal
    threads[:cal] = Thread.new do
      begin
        @calendar = Domoz::Calendar.new( :configpath => config_path )
        @calendar.loop_time = 60
        @calendar.run
      rescue => e
        puts "#{__LINE__} - #{e.class} : #{e.message}"
        puts e.backtrace
      end
    end
  end

  if run_wpi
    threads[:wpi] = Thread.new do
      begin
        thermostat_exec_time = Time.at(0)
        thermostat_loop_time = 5

        lower_drop_temp = 0.5
        higher_rise_temp = 0.5 
        while true
          if( (Time.now - thermostat_exec_time) > thermostat_loop_time )
            print "+w"

            wpi = Domoz::WiPi.new( :pins => [ 3 ] )
            led = Domoz::WiPi.new( :pins => [ 5 ] )
            if @activate_heater
              if ! wpi.low?
                puts '',"#{Time.now}: Activating" 
                wpi.low
                led.high
                post_to_dashing( :widget => 'welcome', :text => Time::now, :title => 'Activated' )
              end
            elsif ! @activate_heater
              if wpi.low?
                puts '',"#{Time.now}: Deactivating"
                wpi.high
                led.low
                post_to_dashing( :widget => 'welcome', :text => Time::now, :title => 'De-Activated' )
              end
            end
            print "-w"

            thermostat_exec_time = Time.now
          end 
        end
      rescue => e
        puts "#{__LINE__} - #{e.class} : #{e.message}"
        puts e.backtrace
      end
    end # Thread.new
  end

  if run_calc
    threads[:calc] = Thread.new do
      begin
        calc_exec_time = Time.at(0)
        calc_loop_time = 5

        points_all = Hash.new

        lower_drop_temp = 0.5
        higher_rise_temp = 0.5 
        current_temperature = 20
        while true
          if( (Time.now - calc_exec_time) > calc_loop_time )

            conf = Domoz::Conf.new( :path => config_path, :file => 'domoz' )
            config = conf.conf
            sensors = config[:sensors]
            sensor_data = Hash.new

            config = conf.conf
            sensors = config[:sensors]
            sensor_data = Hash.new

            description = ''

            @ows.devices_data.each do |t|
              
              rom = t[:owDeviceROM] 
              name = sensors[rom.to_sym][:name]
              temp = t[:owDS18S20Temperature]
              
              if sensors[rom.to_sym][:main] == true
                message = t[:owDS18S20Temperature]
                current_temperature = t[:owDS18S20Temperature].to_f
                @calendar.message = message.dup
              end
              
              post_to_dashing( :widget => name, :value => temp )
              
              if ! points_all.has_key?(name.to_sym)
                points_all[name.to_sym] = Array.new
              end
              points_all[name.to_sym] << { x: Time.now.to_i, y: temp }
              
              points_all[name.to_sym].shift while points_all[name.to_sym].length > 100

              #pp points_all[name.to_sym]
              post_to_dashing( :widget => "#{name}_Gr", :points => points_all[name.to_sym] )

              description += name
              description += " :::: "
              description +=  temp
              description +=  "\n"
              sensor_data[sensors[rom.to_sym][:name].to_sym] = t[:owDS18S20Temperature]
            end

            if ! @calendar.nil?
              @calendar.description = description.dup
              @wanted_temperature = @calendar.wanted_temp
            end

            #puts '', " = #{Time.now}: #{current_temperature}  #{@wanted_temperature} - #{lower_drop_temp}  or + #{higher_rise_temp}"
            
            if current_temperature <= ( @wanted_temperature - lower_drop_temp )
              if ! @activate_heater
                @activate_heater = true
                puts '',"#{Time.now}: = Activation needed"
              end
            elsif current_temperature >= ( @wanted_temperature + higher_rise_temp )
              if @activate_heater
                @activate_heater = false
                puts '',"#{Time.now}: = De-Activation needed"
              end
            end

            calc_exec_time = Time.now
          end
          sleep 1
        end # While true
      rescue => e
        puts "#{Time.now}: #{__LINE__} - #{e.class} : #{e.message}"
        puts e.backtrace
      end
    end # Thread.new
  end # run calc

rescue => e
  puts "#{Time.now}: #{__LINE__} - #{e.class} : #{e.message}"
  puts e.backtrace
end

threads.each do |k,t|
  t.join
end

puts "When do we get here...?"
