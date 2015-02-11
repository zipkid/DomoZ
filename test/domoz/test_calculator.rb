# encoding: utf-8
require_relative '../test_helper'
require 'minitest/autorun'
require 'domoz/calculator'
require 'pp'

describe Domoz::Calculator do
  before do
    @domoz = Domoz::Calculator.new
  end

  describe 'creating a new instance' do
    it 'must be an instance of Domoz::Calculator' do
      @domoz.must_be_instance_of Domoz::Calculator
    end
  end
end
