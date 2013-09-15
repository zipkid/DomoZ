#!/usr/bin/env ruby
require 'rubygems'
require 'wiringpi'

# Prepend RUBYLIB with our own libdir
$:.unshift File.join( %w{ . domoz } )

require 'wipi'

wpi = Domoz::WiPi.new( :pins => [ 0, 1, 2, 3 ] )
        
puts wpi.low?
wpi.low
puts wpi.low?
sleep( 0.5 )
wpi.high
puts wpi.low?
