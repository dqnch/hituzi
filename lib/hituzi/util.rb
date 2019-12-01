# frozen_string_literal: true

module Hituzi
  module Util
    def self.roulette_select(hash)
      return nil if hash.empty?

      sum = hash.values.inject(:+)
      return hash.keys.sample if sum.zero?

      r = rand * sum
      hash.each do |key, value|
        r -= value
        return key if r <= 0
      end

      hash.keys.sample
    end

    def self.message_normalize(str)
      paren_h = {}

      %w[「」 『』 （） ()].each do |paren|
        paren.scan(/./) do |ch|
          paren_h[ch] = paren.scan(/./)
        end
      end

      re = /[「」『』()（）]/
      ary = str.scan(re)
      cnt = 0
      paren = ''
      str2 = str.gsub(re) do |ch|
        res = if cnt == ary.size - 1 && ary.size.odd?
                ''
              elsif cnt.even?
                paren = paren_h[ch][1]
                paren_h[ch][0]
              else
                paren
              end
        cnt += 1
        res
      end
      str2.gsub(/「」/, '')
          .gsub(/（）/, '')
          .gsub(/『』/, '')
          .gsub(/\(\)/, '')
    end

    def self.markov(src, keywords, trie)
      mar = markov_generate(src, trie)
      markov_select(mar, keywords)
    end

    MARKOV_KEY_SIZE = 2

    def markov_generate(src, trie)
      return '' if src.size.zero?

      ary = trie.split_into_terms(src.join("\n") + "\n", true)
      size = ary.size
      ary.concat(ary[0, MARKOV_KEY_SIZE + 1])
      table = {}

      size.times do |idx|
        key = ary[idx, MARKOV_KEY_SIZE]
        table[key] = [] unless table.key?(key)
        table[key] << ary[idx + MARKOV_KEY_SIZE]
      end

      uniq = {}
      backup = {}

      table.each do |k, v|
        if v.size == 1
          uniq[k] = v[0]
        else
          backup[k] = table[k].dup
        end
      end

      key = ary[0, MARKOV_KEY_SIZE]
      result = key.join('')
      10_000.times do
        if uniq.key?(key)
          str = uniq[key]
        else
          table[key] = backup[key].dup if table[key].empty?
          idx = rand(table[key].size)
          str = table[key][idx]
          table[key][idx] = nil
          table[key].compact!
        end
        result << str
        key = (key.dup << str)[1, MARKOV_KEY_SIZE]
      end
      result
    end

    def markov_split(str)
      result = []
      # while /\A(.{25,}?)([。、．，]+|[?!.,]+[\s　])[ 　]*/.match(str)
      while /\A(.{25,}?)([。、．，]+|[?!.,]+[\s　])[ 　]*/ =~ str
        match = Regexp.last_match
        m = match[1]
        m += match[2].gsub(/、/, '。').gsub(/，/, '．') if match[2]
        result << m
        str = match.post_match
      end
      result << str if str.size.positive?
      result
    end

    def markov_select(result, keywords)
      tmp = result.split(/\n/) || ['']
      result_ary = tmp.map { |str| markov_split(str) }.flatten.uniq
      result_ary.delete_if { |a| a.size.zero? || /\0/.match(a) }
      result_hash = {}
      trie = Trie.new(keywords.keys)
      result_ary.each do |str|
        terms = trie.split_into_terms(str).uniq
        result_hash[str] = terms.map { |kw| keywords[kw] }.inject(:+) || 0
      end

      if Rails.env.development?
        sum = result_hash.values.inject(:+).to_f
        tmp = result_hash.sort_by { |k, v| [-v, k] }
        Rails.logger.debug("-(候補数: #{result_hash.size})----")
        tmp.first(10).each do |k, v|
          Rails.logger.debug(format("%<val>5.2f%%: %<key>s\n", val: (v / sum * 100) || 0, key: k))
        end
      end
      roulette_select(result_hash) || ''
    end

    module_function :markov_select, :markov_generate, :markov_split
  end
end
