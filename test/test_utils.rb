# encoding: utf-8
require_relative 'test_helper'
require 'minitest/autorun'
require 'domoz/utils'

describe Kernel do
  it 'must deep copy' do
    assert_equal([], deep_copy([]))
    a = []
    b = deep_copy(a)
    refute_equal(a.object_id, b.object_id)
  end
end
