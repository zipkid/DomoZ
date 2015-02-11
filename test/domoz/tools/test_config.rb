# encoding: utf-8
require_relative '../../test_helper'
require 'minitest/autorun'
require 'domoz/tools/config'
require 'pp'

describe Domoz::Config do
  before do
    @config = Domoz::Config.new
  end

  describe 'creating a new instance' do
    it 'must be an instance of Domoz::Config' do
      @config.must_be_instance_of Domoz::Config
    end
  end
end
