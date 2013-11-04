#!/usr/bin/env ruby
$:.unshift File.join( File.dirname(__FILE__), '..', 'lib' )
$:.unshift File.join( File.dirname(__FILE__), '..', 'lib', 'domoz' )

require 'calendar'
require "test/unit"

class TestDomozCalendar < Test::Unit::TestCase
  
  def test_initialize
    cal = Domoz::Calendar.new
  end


end
