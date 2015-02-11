# encoding: utf-8
require 'yaml'
require 'time'
require 'pp'
require 'domoz/utils'

class Domoz
  class Config
    attr_reader :last_load, :read_conf

    def initialize(options = {})
      options[:path] ||= './config'
      options[:file] ||= 'domoz'
      options[:ext]  ||= 'yaml'
      @config_file = File.join(options[:path], options[:file] + '.' + options[:ext])
    end

    def conf(*config)
      @config = config unless config.nil?
      save_conf if need_saving
      load_conf if need_loading
      @config
    end

    private

    # def deep_copy(o)
    #   Marshal.load(Marshal.dump(o))
    # end

    def need_saving
      ! @read_conf.diff(@config).empty? unless @config.nil?
    end

    def need_loading
      true if @config.nil? || changed?
    end

    def changed?
      File.stat(@config_file).mtime > @last_load
    end

    def load_conf
      # puts "Loading conf from #{@config_file}"
      @read_conf = YAML.load_file File.join(@config_file)
      @read_conf ||= {}
      @conf = deep_copy @read_conf
      @last_load = Time.now
    end

    def save_conf
      # puts "Saving conf to #{@config_file}"
      File.open(File.join(@config_file), 'w') { |f| f.write(@config.to_yaml) }
      load_conf
    end
  end
end

class Hash
  def diff(other)
    (keys + other.keys).uniq.inject({}) do |memo, key|
      unless self[key] == other[key]
        if self[key].is_a?(Hash) &&  other[key].is_a?(Hash)
          memo[key] = self[key].diff(other[key])
        else
          memo[key] = [self[key], other[key]]
        end
      end
      memo
    end
  end
end
