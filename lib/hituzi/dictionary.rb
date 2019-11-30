# frozen_string_literal: true

module Hituzi
  class Dictionary < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    self.table_name = 'hituzi_dictionaries'

    DICT_INIT = "line_num: 0\n"
    LTL = 3
    WINDOW_SIZE = 500

    attr_reader :text, :trie

    after_initialize :initialize_dictionary

    def reset
      self.textdata = ''
      self.dict = DICT_INIT
    end

    def save_text
      Rails.logger.debug("#{self.class}#save_text was called!")
      self.textdata = @text.join("\n")
      save!
    end

    def save_dictionary
      Rails.logger.debug("#{self.class}#save_dictionary was called!")
      self.dict = to_s
      save!
    end

    def learn_from_text(progress = nil)
      modified = false
      read_size = 0
      buf_prev = []
      end_flag = false
      idx = @line_num
      loop do
        buf = []
        if progress
          idx2 = read_size / WINDOW_SIZE**2
          if (idx2 % 100_000).zero?
            Rails.logger.debug("#{self.class}#learn_from_text: #{format("\n%5dk ", idx2 / 1000)}")
          elsif (idx2 % 20_000).zero?
            Rails.logger.debug("#{self.class}#learn_from_text: *")
          elsif (idx2 % 2_000).zero?
            Rails.logger.debug("#{self.class}#learn_from_text: .")
          end
        end
        tmp = read_size
        while tmp / WINDOW_SIZE == read_size / WINDOW_SIZE
          if idx >= @text.size
            end_flag = true
            break
          end
          buf << @text[idx]
          tmp += @text[idx].size
          idx += 1
        end
        read_size = tmp
        break if end_flag

        unless buf_prev.empty?
          learn(buf_prev + buf, @line_num)
          modified = true
          @line_num += buf_prev.size
        end
        buf_prev = buf
      end
      modified
    end

    def store_text(lines)
      ary = []
      lines.each_line { |line| ary << line.gsub(/\s+/, ' ').strip }
      ary.each { |line| @text << line }
      self.textdata += "\n" if textdata.present?
      self.textdata += ary.map(&:chomp).join("\n")
      save!
    end

    def split_into_keywords(str)
      result = Hash.new(0)
      split_into_terms(str).each { |term| result[term] += weight(term) }
      result
    end

    def split_into_terms(str, num = nil)
      @trie.split_into_terms(str, num)
    end

    def to_s
      result = ''
      result << "line_num: #{@line_num}\n"
      result << "\n"
      @occur.delete_if { |_k, v| v.empty? }
      @occur.each { |k, v| @occur[k] = v[-100..-1] if v.size > 100 }
      tmp = @occur.keys.sort_by do |k|
        [-@occur[k].size, @rel[k][:num], k.length, k]
      end
      tmp.each do |k|
        result << format("%s\t\%s\t\%s\t%s\n",
                         k,
                         @rel[k][:num],
                         @rel[k][:sum],
                         @occur[k].join(','))
      end
      result
    end

    def weight(word)
      if !@rel.key?(word) || @rel[word][:sum].zero?
        0
      else
        num = @rel[word][:num]
        sum = @rel[word][:sum].to_f
        num / (sum * (sum + 100))
      end
    end

    def lines(word)
      @occur[word] || []
    end

    private

    def initialize_dictionary
      @occur = {}
      @rel = {}
      @trie = Trie.new
      @text = []
      @line_num = 0
      self.dict = DICT_INIT if dict.blank?
      load_text
      load_dictionary
    end

    def load_text
      self.textdata ||= ''
      textdata.each_line { |line| @text << line.chomp }
    end

    def load_dictionary
      dict.each_line do |line|
        line.chomp!
        case line
        when /^$/
          break
        when /line_num:\s*(.*)\s*$/i
          @line_num = Regexp.last_match(1).to_i
        else
          Rails.logger.warn("Unknown_header #{line}")
        end
      end

      dict.each_line do |line|
        line.chomp!
        word, num, sum, occur = line.split(/\t/)
        next unless occur

        @occur[word] = occur.split(/,/).collect(&:to_i)
        add_term(word)
        @rel[word] = Hash.new(0)
        @rel[word][:num] = num.to_i
        @rel[word][:sum] = sum.to_i
      end
    end

    def learn(lines, idx = nil)
      new_terms = Freq.extract_terms(lines, 30)
      new_terms.each { |term| add_term(term) }
      return unless idx

      words_all = []
      lines.each_with_index do |line, i|
        num = idx + i
        words = split_into_terms(line)
        words_all.concat(words)
        words.each do |term|
          Rails.logger.debug('<' * 40)
          Rails.logger.debug(term)
          Rails.logger.debug(@occur[term])
          @occur[term] = [] if @occur[term].nil?
          Rails.logger.debug('>' * 40)
          @occur[term] << num if @occur[term].empty? || num > @occur[term][-1]
        end
      end
      weight_update(words_all)
      terms.each do |term|
        occur = @occur[term]
        size = occur.size
        del_term(term) if size < 4 && size.positive? && occur[-1] + size * 150 < idx
      end
    end

    def weight_update(words)
      width = 20
      words.each do |term|
        @rel[term] = Hash.new(0) unless @rel.key?(term)
      end
      size = words.size
      (size - width).times do |idx1|
        word1 = words[idx1]
        (idx1 + 1).upto(idx1 + width) do |idx2|
          @rel[word1][:num] += 1 if word1 == words[idx2]
          @rel[word1][:sum] += 1
        end
      end
      (width + 1).times do |idx1|
        word1 = words[-idx1]
        next unless word1

        (idx1 - 1).downto(1) do |idx2|
          @rel[word1][:num] += 1 if word1 == words[-idx2]
          @rel[word1][:sum] += 1
        end
      end
    end

    def terms
      @occur.keys
    end

    def add_term(str)
      @occur[str] = [] unless @occur.key?(str)
      @trie.add(str)
      @rel[str] = Hash.new(0) unless @rel.key?(str)
    end

    def del_term(str)
      occur = @occur[str]
      @occur.delete(str)
      @trie.delete(str)
      @rel.delete(str)
      tmp = split_into_terms(str)
      tmp.each { |w| @occur[w] = @occur[w].concat(occur).uniq.sort }
      weight_update(tmp) if tmp.size.positive?
    end
  end
end
