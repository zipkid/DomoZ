#!/usr/bin/env ruby
require 'rubygems'        # if you use RubyGems
require 'yaml'
require 'time'
require 'getoptlong'

# Prepend RUBYLIB with our own libdir
$:.unshift File.join( %w{ . domoz } )

require 'conf'
require 'calendar'

path = File.expand_path(File.dirname(__FILE__))
config_path = File.join( path, 'config')

wanted_temp = 17

calendar = Domoz::Calendar.new( :configpath => config_path, :wanted_temp => wanted_temp )
puts calendar.wanted_temp
