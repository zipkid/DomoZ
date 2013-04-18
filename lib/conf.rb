#require 'yaml'
#
#class Conf_xxxxxxx
#  attr_accessor :conf
#
#  def initialize( path )
#    @path = path
#    load_conf
#  end
#
#  def load_conf
#    @conf = YAML::load_file File.join(@path,"domoz.yaml")
#    @conf[:oauth2] = {} if ! @conf[:oauth2] 
#  end
#
#  def save_conf
#    File.open(File.join(@path,"domoz.yaml"), "w") {|f| f.write(@conf.to_yaml) }
#  end
#
#end
#
#class Hash
#  def diff(other)
#    (self.keys + other.keys).uniq.inject({}) do |memo, key|
#      unless self[key] == other[key]
#        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
#          memo[key] = self[key].diff(other[key])
#        else
#          memo[key] = [self[key], other[key]] 
#        end
#      end
#      memo
#    end
#  end
#end_xxxxxx
