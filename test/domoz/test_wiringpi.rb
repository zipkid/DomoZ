# encoding: utf-8
require_relative '../test_helper'
require 'minitest/autorun'
require 'domoz/wiringpi'
require 'pp'

describe Domoz::Wiringpi do
  before do
    @domoz = Domoz::Wiringpi.new
  end

  describe 'creating a new instance' do
    it 'must be an instance of Domoz::Wiringpi' do
      @domoz.must_be_instance_of Domoz::Wiringpi
    end
  end
end
