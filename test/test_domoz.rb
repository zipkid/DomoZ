# encoding: utf-8
require 'minitest/autorun'
require 'domoz'
require 'pp'

describe Domoz do
  before do
    @domoz = Domoz.new
  end

  describe 'creating a new instance' do
    it 'must be an instance of Domoz' do
      @domoz.must_be_instance_of Domoz
    end
  end
end
