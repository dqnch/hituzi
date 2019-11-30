# frozen_string_literal: true

module Hituzi
  class Trie
    def initialize(ary = nil)
      @root = {}
      ary&.each { |elm| add(elm) }
    end

    def add(str)
      node = @root
      str.each_byte do |b|
        node[b] = {} unless node.key?(b)
        node = node[b]
      end
      node[:terminate] = true
    end

    def member?(str)
      node = @root
      str.each_byte do |b|
        return false unless node.key?(b)

        node = node[b]
      end
      node.key?(:terminate)
    end

    def members
      members_sub(@root)
    end

    def split_into_terms(str, num = nil)
      result = []
      return result unless str

      while !str.empty? && (!num.is_a?(Numeric) || result.size < num)
        prefix = longest_prefix_subword(str)
        if prefix
          result << prefix
          str = str[prefix.size..-1]
        else
          chr = /./m.match(str)[0]
          result << chr if num
          str = Regexp.last_match.post_match
        end
      end
      result
    end

    def longest_prefix_subword(str)
      node = @root
      result = nil
      idx = 0
      str.each_byte do |b|
        result = str[0, idx] if node.key?(:terminate)
        return result unless node.key?(b)

        node = node[b]
        idx += 1
      end

      node.key?(:terminate) ? str : result
    end

    def delete(str)
      node = @root
      ary = []
      str.each_byte do |b|
        return false unless node.key?(b)

        ary << [node, b]
        node = node[b]
      end
      return false unless node.key?(:terminate)

      ary << [node, :terminate]
      ary.reverse_each do |n, b|
        node.delete(b)
        break unless n.empty?
      end
      true
    end

    private

    def members_sub(node, str = '')
      node.map do |k, v|
        if k == :terminate
          str
        else
          members_sub(v, str + k.chr)
        end
      end.flatten
    end
  end
end
