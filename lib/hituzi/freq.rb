# frozen_string_literal: true

module Hituzi
  class Freq
    def self.extract_terms(buf, limit)
      new(buf).extract_terms(limit)
    end

    def initialize(buf)
      buf = buf.join("\0") if buf.is_a?(Array)
      @buf = buf
    end

    def extract_terms(limit)
      terms = extract_terms_sub(limit)
      terms = terms.map { |t, n| [t.reverse.strip, n] }.sort
      terms2 = []
      (terms.size - 1).times do |idx|
        if terms[idx][0].size >= terms[idx + 1][0].size ||
           terms[idx][0] != terms[idx + 1][0][0, terms[idx][0].size]
          terms2 << terms[idx]
        elsif terms[idx][1] >= terms[idx + 1][1] + 2
          terms2 << terms[idx]
        end
      end
      terms2 << terms[-1] unless terms.empty?
      terms2.map { |t, _n| t.reverse }
    end

    def extract_terms_sub(limit, str = '', num = 1, width = false)
      h = freq(str)
      flag = (h.size <= 4)
      result = []
      if limit.positive?
        h.delete(str) if h.key?(str)
        h.to_a.delete_if { |_k, v| v < 2 }.sort.each do |k, v|
          result.concat(extract_terms_sub(limit - 1, k, v, flag))
        end
      end
      return [[str.downcase, num]] if result.empty? && width

      result
    end

    def freq(str)
      freq = Hash.new(0)
      if str.size.zero?
        regexp = /([!-~])[!-~]*|([ァ-ヴ])[ァ-ヴー]*|([^ー\0])/i
        @buf.scan(regexp) { |ary| freq[ary[0] || ary[1] || ary[2]] += 1 }
      else
        regexp = /#{Regexp.quote(str)}[^\0]?/i
        @buf.scan(regexp) { |s| freq[s] += 1 }
      end
      freq
    end
  end
end
