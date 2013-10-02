module Domoz
  require 'yaml'
  require 'date'
  require 'rubygems'
  # Initialize the client & Google+ API
  require 'google/api_client'

  $:.unshift File.join( %w{ . / } )

  #require File.expand_path(File.join(File.dirname(__FILE__), '../google_oauth2'))
  require 'google_oauth2'
  #require File.expand_path(File.join(File.dirname(__FILE__), 'conf'))
  require 'conf'

  # https://github.com/puppetlabs/facter/blob/master/lib/facter/util/ec2.rb
  # Here and/or in calendar....

  class Calendar
    attr_accessor :wanted_temp, :message, :description, :loop_time
    
    def initialize args
      @wanted_temp = 0
      @message = ''
      @description = ''
      @configpath = args[:configpath]
      @loop_time = args[:looptime]
      @loop_time ||= 60

      @conf = Domoz::Conf.new( :path => @configpath, :file => 'domoz-auth' )

      @a_conf = @conf.conf
      @calendar_id = @a_conf[:google][:calendar_id]

      @oauth = Google_oauth2.new( :configpath => args[:configpath] )

      @client = Google::APIClient.new(
        :application_name => "DomoZ",
        :application_version => "0.0.1"
      )
      # @client.authorization.access_token = @oauth.access_token
      @calendar = @client.discovered_api('calendar', 'v3')

      #if get_auth
      #  get_wanted_temp
      #end

      #puts "And wanted_temp = #{@wanted_temp}"

      ObjectSpace.define_finalizer(self, Proc.new{ if @cal_thread.defined? then @cal_tread.join end })

#    rescue Faraday::Error::ConnectionFailed => e
#      puts 'Connection Failed'
#      puts e.message
#    rescue => e
#      puts 'Something else bad happened in initialize'
#      puts e.message
#      puts e.backtrace
#      puts '------'
    end

    def run
      @cal_thread = Thread.new do
        cal_exec_time = Time.at(0)
        cal_loop_time = @loop_time
        while true
          if( (Time.now - cal_exec_time) > cal_loop_time )
            puts "+ Cal run"
            get_wanted_temp
            #puts "msg:#{@message}"
            #puts "des:#{@description}"
            set_current_msg( @message, @description )
            cal_exec_time = Time.now
            puts "- Cal run"
          end
        end
      end
    end
    
    def get_auth
      @oauth.get_auth
    end

    def get_wanted_temp
      return unless get_auth
      wanted_temp = 16 # @default_wanted_temp 
      calendar_default_temp = false
      override_wanted_temp = false
      events = get_events
      events.each do |e|
        next if e.summary.downcase.match(/^current/)
        
        if m = e.summary.downcase.match(/([\.\d]+)\s*-\s*default$/)
          calendar_default_temp = m[1] 
        elsif m = e.summary.downcase.match(/([\.\d]+)$/)
          override_wanted_temp = m[1]
        end

        #puts e.id
        #puts e.summary
        #puts e.start["dateTime"]
        #puts e.end["dateTime"]
        puts

      end

      wanted_temp = calendar_default_temp if calendar_default_temp
      wanted_temp = override_wanted_temp if override_wanted_temp
      @wanted_temp = wanted_temp.to_f

      wanted_temp
    end

    def set_current_msg( summary, description = '' )
      current_events = get_events( :query => 'Current' )
      if current_events.empty?
        insert_current_event( summary, description )
      else
        current_events.each do |event|
          update_current_event( event, summary, description )
        end
      end
    end

    private

    def refresh_auth
      @oauth.refresh_auth
      @client.authorization.access_token = @oauth.access_token
    end

    def insert_current_event( summary, description = '' )
      event = {
        'summary' => "Current : #{summary}",
        'description' => description,
        'start' => { 'dateTime' => DateTime.now },
        'end' => { 'dateTime' => DateTime.now + (20/1440.0) }
      }
      @client.authorization.access_token = @oauth.access_token
      result = @client.execute(
        :api_method => @calendar.events.insert,
        :parameters => {'calendarId' => @calendar_id },
        :body => JSON.dump(event),
        :headers => {'Content-Type' => 'application/json'}
      )
      check_result result  
      #puts result.data.id
    rescue OauthRefreshError => e
      puts e.message
      refresh_auth
      retry
    rescue Faraday::Error::ConnectionFailed => e
      puts 'Connection Failed'
      puts e.message
    rescue => e
      puts 'Something else bad happened in insert_current_event'
      puts e.message
      puts e.backtrace
    end

    def update_current_event( event, summary, description = '' )
      @client.authorization.access_token = @oauth.access_token
      result = @client.execute(
        :api_method => @calendar.events.get,
        :parameters => {'calendarId' => @calendar_id, 'eventId' => event.id }
      )
      check_result result  
      ev = result.data
      ev.summary = "Current : #{summary}"
      ev.description = description
      ev.start = { 'dateTime' => DateTime.now },
      ev.end = { 'dateTime' => DateTime.now + (20/1440.0) }
      result = @client.execute(
        :api_method => @calendar.events.update,
        :parameters => {'calendarId' => @calendar_id, 'eventId' => ev.id},
        :body_object => ev,
        :headers => {'Content-Type' => 'application/json'}
      )
      check_result result  
      #puts result.data.updated
    rescue OauthRefreshError => e
      puts e.message
      refresh_auth
      retry
    rescue Faraday::Error::ConnectionFailed => e
      puts 'Connection Failed'
      puts e.message
    rescue => e
      puts 'Something else bad happened in update_current_event'
      puts e.message
      puts e.backtrace
    end

    def check_result( result )
      if result.error? 
        puts "error: "+result.error_message
        puts "Return val: "+result.response.status.to_s
        if result.response.status == 401
          raise OauthRefreshError, "#{Time.now}: oauth failed, need to attempt refresh"
        #else
        #  raise CheckResultError, "Something is wrong with the result"
        end
      end
    end

    def get_week_events
      events = get_events :timemax => DateTime.now + 7 , :timemin => DateTime.now  
       
    end

    def get_events args = {}
      args[:timemax] ||= DateTime.now + (1/1440.0)
      args[:timemin] ||= DateTime.now
      @client.authorization.access_token = @oauth.access_token
      result = @client.execute(
        :api_method => @calendar.events.list,
        :parameters => {
          'calendarId' => @calendar_id ,
          'singleEvents' => true,
          'timeMax' => args[:timemax],
          'timeMin' => args[:timemin],
          'q' => args[:query]
         }
      )

      check_result result  

      events = result.data.items

      #events.each do |e|
      #  puts e.id
      #  puts e.summary
      #  puts e.start['dateTime']
      #  puts e.end['dateTime']
      #  puts
      #end

      events
    rescue OauthRefreshError => e
      puts e.message
      refresh_auth
      retry
    rescue Faraday::Error::ConnectionFailed => e
      puts 'Connection Failed'
      puts e.message
    rescue => e
      puts 'Something else bad happened in get_events'
      puts e.message
      puts e.backtrace
      puts e.class
      # Faraday::Error::ConnectionFailed
      puts e.message
    end

    # No need for this if using 'singleEvents' on the events.list
    def get_event_instances( event_id )
      @client.authorization.access_token = @oauth.access_token
      result = @client.execute(
        :api_method => @calendar.events.instances,
        :parameters => {
          'calendarId' => @calendar_id, 
          'eventId' => event_id  
         }
      )

      check_result result  

      events = result.data.items
      events.each do |e|
        puts "\t"+e.inspect
        #puts "\t"+e.description
        puts
      end
    rescue OauthRefreshError => e
      puts e.message
      refresh_auth
      retry
    rescue Faraday::Error::ConnectionFailed => e
      puts 'Connection Failed in get_event_instances'
      puts e.message
    rescue => e
      puts 'Something else bad happened in get_event_instances'
      puts e.message
      puts e.backtrace
    end
    
  end

  class OauthRefreshError < StandardError
    def initialize(msg = "Oauth failed, need to attempt refresh")
      super
    end
  end

end
