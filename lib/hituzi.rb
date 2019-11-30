# frozen_string_literal: true

require 'hituzi/engine'
require 'hituzi/util'
require 'hituzi/core'
require 'hituzi/dictionary'
require 'hituzi/freq'
require 'hituzi/trie'

module Hituzi
  def self.new(*args)
    Core.new(*args)
  end
end
