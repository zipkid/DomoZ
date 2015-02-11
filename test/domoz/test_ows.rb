# encoding: utf-8
require_relative '../test_helper'
require 'minitest/autorun'
require 'domoz/ows'
require 'pp'

describe Domoz::Ows do
  before do
    @domoz = Domoz::Ows.new
  end

  describe 'creating a new instance' do
    it 'must be an instance of Domoz::Ows' do
      @domoz.must_be_instance_of Domoz::Ows
    end
  end
end
