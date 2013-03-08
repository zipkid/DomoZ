require 'rubygems'
# Initialize the client & Google+ API
require 'google/api_client'
require 'rest_client'
require 'json'
require 'time'

class Google_oauth2
   
  attr_reader :connected, :client_id, :client_secret, :device_code, :user_code, :verification_url, :refresh_token, :interval, :id_token, :access_token, :verification_interval, :verification_expires_in, :verification_interval_start

  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def get_auth
    if ! @device_code
      get_user_code
    end
    if ! @access_token
      get_access_code
    end
    ! @access_token.empty?
  end

  def refresh_auth
    refresh_token
  end

  def to_hash
    Hash[instance_variables.map { |name| [name.to_s.delete("@").to_sym,  instance_variable_get(name)] } ]
  end

  private

  # Step 1, get device code.
  def get_user_code
    data = {
      :client_id => @client_id,
      :scope => 'https://www.googleapis.com/auth/calendar',
    }
    json = RestClient.post "https://accounts.google.com/o/oauth2/device/code", data
    #response = JSON.parse(RestClient.post "https://accounts.google.com/o/oauth2/device/code", data)
    response = JSON.parse(json)
    #puts response.inspect
    if response["device_code"]
      puts "go to #{response["verification_url"]} and use code #{response["user_code"]}"
      @device_code = response["device_code"]
      @user_code = response["user_code"]
      @verification_url = response["verification_url"]
      @verification_interval = response["interval"].to_i
      @verification_expires_in = response["expires_in"].to_i
      @verification_interval_start = Time.now
    else
      # No Token
    end
  rescue RestClient::BadRequest => e
    puts 'Bad request'
    puts e.backtrace
  rescue => e
    puts 'Something else bad happened'
    puts e.backtrace
  end

  # Step 2, get access token. This requires the cal owners approval
  def get_access_code
    data = {
      :client_id => @client_id,
      :client_secret => @client_secret,
      :code => @device_code,
      :grant_type => 'http://oauth.net/grant_type/device/1.0',
    }
    
    keep_trying = true 
    
    while keep_trying
      sleep ( @verification_interval + 1 )
      keep_trying = false if (Time.now - @verification_interval_start) > @verification_expires_in 
      if keep_trying
        json = RestClient.post "https://accounts.google.com/o/oauth2/token", data
        response = JSON.parse(json)
        #puts response.inspect
        
        if response["error"]
          if response["error"] == "authorization_pending"
            puts "Still waiting for user authorization"
          elsif response["error"] == "slow_down"
            puts "requesting too fast!"
          end
        elsif response["access_token"]
          #puts "got #{response["access_token"]}"
          @refresh_token = response["refresh_token"]
          @id_token = response["id_token"]
          @access_token = response["access_token"]
          @expires_in = response["expires_in"]
          keep_trying = false
        else
          # No Token
        end
      else
        puts "Verification interval expired and no access token recieved"
      end
    end
  rescue RestClient::BadRequest => e
    puts "Bad request during 'refresh_token'"
    puts e.backtrace
  rescue => e
    puts "Something else bad happened during 'refresh_token'" 
    puts e.backtrace
  end

  def refresh_token
    data = {
      :client_id => @client_id,
      :client_secret => @client_secret,
      :refresh_token => @refresh_token,
      :grant_type => "refresh_token"
    }
    puts "Refreshing Token..."
    response = JSON.parse(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
    #puts response.inspect
    if response["access_token"]
      @access_token = response["access_token"]
      # Save your token
    else
      # No Token
    end
  rescue RestClient::BadRequest => e
    puts "Bad request during 'refresh_token'"
    puts e.backtrace
  rescue => e
    puts "Something else bad happened during 'refresh_token'" 
    puts e.backtrace
  end

end
