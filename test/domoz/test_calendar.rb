# encoding: utf-8
require_relative '../test_helper'
require 'minitest/autorun'
require 'domoz/calendar'
require 'pp'

describe Domoz::Calendar do
  before do
    @domoz = Domoz::Calendar.new
  end

  describe 'creating a new instance' do
    it 'must be an instance of Domoz::Calendar' do
      @domoz.must_be_instance_of Domoz::Calendar
    end
  end
end
