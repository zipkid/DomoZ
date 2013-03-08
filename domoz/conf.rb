module Domoz
  require 'yaml'
  require 'time'
  require 'pp'

  class Conf
    #attr_accessor :conf
    attr :last_load, :read_conf

    def initialize args = nil
      args ||= {}
      args[:path] ||= './'
      args[:file] ||= 'domoz.yaml'
      @config_file = File.join(args[:path], args[:file])
    end

    def conf
      save_conf if need_saving
      load_conf if need_loading
      @conf
    end

    private

    def deep_copy(o)
      Marshal.load(Marshal.dump(o))
    end

    def need_saving
      if @conf != nil
        ! @read_conf.diff( @conf ).empty?
      end
    end

    def need_loading
      return true if @conf == nil
      return true if is_changed
    end

    def is_changed
      File.stat(@config_file).mtime > @last_load
    end

    def load_conf
      @read_conf = YAML::load_file File.join(@config_file)
      @conf = deep_copy @read_conf
      @last_load = Time.now
    end

    def save_conf
      File.open(File.join(@config_file), "w") {|f| f.write(@conf.to_yaml) }
    end
  end
end

class Hash
  def diff(other)
    (self.keys + other.keys).uniq.inject({}) do |memo, key|
      unless self[key] == other[key]
        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
          memo[key] = self[key].diff(other[key])
        else
          memo[key] = [self[key], other[key]] 
        end
      end
      memo
    end
  end
end
