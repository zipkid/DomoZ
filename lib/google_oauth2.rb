require 'rubygems'
# Initialize the client & Google+ API
require 'google/api_client'
require 'rest_client'
require 'json'
require 'time'
require 'pp'

require File.expand_path(File.join(File.dirname(__FILE__), '../domoz/conf'))

class Google_oauth2
   
  attr_reader :connected, :access_token

  def initialize args
    #args.each do |k,v|
    #  instance_variable_set("@#{k}", v) unless v.nil?
    #end
    @a_c = Domoz::Conf.new( :path => args[:configpath], :file => 'domoz-auth' )

    @oa_c = Domoz::Conf.new( :path => args[:configpath], :file => 'domoz-oauth' )

    @a_conf = @a_c.conf[:google]

    @conf = @oa_c.conf
    @conf[:oauth] ||= Hash.new 
  end

  def get_auth
    if ! @conf[:oauth][:device_code]
      get_user_code || return
      #puts "get_user_code"
      #pp @conf
      @oa_c.conf @conf
    end
    if ! @conf[:oauth][:access_token]
      get_access_code || return
      #puts "get_access_code"
      #pp @conf
      @oa_c.conf @conf
    end
    @access_token = @conf[:oauth][:access_token]
    @access_token && ! @access_token.empty?
  end

  def refresh_auth
    refresh_token || return
    @access_token = @conf[:oauth][:access_token]
    #puts "refresh_auth"
    #pp @conf
    @oa_c.conf @conf
  end

  #def to_hash
  #  Hash[instance_variables.map { |name| [name.to_s.delete("@").to_sym,  instance_variable_get(name)] } ]
  #end

  private

  # Step 1, get device code.
  def get_user_code
    data = {
      :client_id => @a_conf[:client_id],
      :scope => 'https://www.googleapis.com/auth/calendar',
    }
    #puts "Data for get_user_code"
    #pp data

    json = RestClient.post "https://accounts.google.com/o/oauth2/device/code", data
    response = JSON.parse(json)
    #puts response.inspect
    if response["device_code"]
      puts "__________ go to #{response["verification_url"]} and use code #{response["user_code"]} _________"
      @conf[:oauth][:device_code] = response["device_code"]
      @conf[:oauth][:user_code] = response["user_code"]
      @conf[:oauth][:verification_url] = response["verification_url"]
      @conf[:oauth][:verification_interval] = response["interval"].to_i
      @conf[:oauth][:verification_expires_in] = response["expires_in"].to_i
      @conf[:oauth][:verification_interval_start] = Time.now
    else
      # No Token
    end
  rescue RestClient::BadRequest => e
    puts "Bad request for 'get_user_code'"
    puts e.message
    #puts e.backtrace
  rescue => e
    puts 'Something else bad happened during get_user_code'
    puts e.message
    #puts e.backtrace
  end

  # Step 2, get access token. This requires the cal owners approval
  def get_access_code
    data = {
      :client_id => @a_conf[:client_id],
      :client_secret => @a_conf[:client_secret],
      :code => @conf[:oauth][:device_code],
      :grant_type => 'http://oauth.net/grant_type/device/1.0',
    }
    #puts "Data for get_access_code"
    #pp data

    keep_trying = true 

    while keep_trying
      sleep ( @conf[:oauth][:verification_interval] + 1 )
      keep_trying = false if (Time.now - @conf[:oauth][:verification_interval_start]) > @conf[:oauth][:verification_expires_in] 
      if keep_trying
        json = RestClient.post "https://accounts.google.com/o/oauth2/token", data
        response = JSON.parse(json)

        if response["error"]
          if response["error"] == "authorization_pending"
            puts "Still waiting for user authorization"
          elsif response["error"] == "slow_down"
            puts "requesting too fast!"
          else
            puts "Unknow error response : '#{response["error"]}'"
          end
        elsif response["access_token"]
          #puts "got #{response["access_token"]}"
          @conf[:oauth][:refresh_token] = response["refresh_token"]
          @conf[:oauth][:token_type] = response["token_type"]
          @conf[:oauth][:access_token] = response["access_token"]
          @conf[:oauth][:expires_in] = response["expires_in"]
          keep_trying = false
          return true
        else
          # No Token
        end
      else
        puts "Verification interval expired and no access token received"
        @conf[:oauth] = Hash.new
      end
    end
  rescue RestClient::BadRequest => e
    puts "Bad request for 'get_access_code'"
    puts e.message
    #puts e.backtrace
  rescue => e
    puts "Something else bad happened during 'get_access_code'" 
    puts e.message
    #puts e.backtrace
  end

  def refresh_token
    data = {
      :client_id => @a_conf[:client_id],
      :client_secret => @a_conf[:client_secret],
      :refresh_token => @conf[:oauth][:refresh_token],
      :grant_type => "refresh_token"
    }
    puts "Refreshing Token..."
    response = JSON.parse(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
    #puts response.inspect
    if response["access_token"]
      @conf[:oauth][:access_token] = response["access_token"]
      # Save your token
      return true
    else
      # No Token
    end
  rescue RestClient::BadRequest => e
    puts "Bad request for 'refresh_token'"
    puts e.message
    #puts e.backtrace
  rescue => e
    puts "Something else bad happened during 'refresh_token'" 
    puts e.message
    #puts e.backtrace
  end

end
