# frozen_string_literal: true

module Hituzi
  class Core
    attr_accessor :dic

    def initialize(dic)
      @dic = dic
    end

    def talk(str = nil, weight = {})
      if str
        keywords = @dic.split_into_keywords(str)
      else
        keywords = Hash.new(0)
        @dic.text.last(10).each do |s|
          keywords.each { |k, _v| keywords[k] *= 0.5 }
          @dic.split_into_keywords(s).each { |k, v| keywords[k] += v }
        end
      end

      weight.keys.each do |kw|
        if keywords.key?(kw)
          if weight[kw].zero?
            keywords.delete(kw)
          else
            keywords[kw] *= weight[kw]
          end
        end
      end

      if Rails.env.development?
        sum = keywords.values.inject(:+)
        tmp = keywords.sort_by { |k, v| [-v, k] }
        Rails.logger.debug('-(term)----')
        tmp.each do |k, v|
          Rails.logger.debug(format(' %<key>s(%<val>6.3f%%), ', key: k, val: v / sum * 100))
        end
        Rails.logger.debug('----------')
      end
      message_markov(keywords)
    end

    def memorize(lines)
      @dic.store_text(lines)
      @dic.save_dictionary if @dic.learn_from_text
    end

    def message_markov(keywords)
      lines = []
      unless keywords.empty?
        if keywords.size > 10
          keywords.sort_by { |_k, v| -v }[10..-1].each do |k, _v|
            keywords.delete(k)
          end
        end
        sum = keywords.values.inject(:+)
        keywords.each { |k, v| keywords[k] = v / sum } if sum.positive?
        keywords.keys.map do |kw|
          ary = @dic.lines(kw).sort_by { rand }
          ary[0, 10].each do |idx|
            lines << idx
          end
        end.flatten
      end
      10.times do
        lines << rand(@dic.text.size)
      end
      lines.uniq!
      source = lines.map { |k, _v| @dic.text[k, 5] }.sort_by { rand }.flatten.compact.uniq
      msg = Util.markov(source, keywords, @dic.trie)
      Util.message_normalize(msg)
    end
  end
end
