# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hituzi::Dictionary do
  describe '#initialize_dictionary' do
    let(:dic) { described_class.find_or_create_by(name: 'default') }

    context '辞書データなし' do
      it '初期化されている' do
        expect(dic.textdata).to eq ''
        expect(dic.dict).to eq "line_num: 0\n"
      end
    end

    context '辞書データあり' do
      before do
        h = Hituzi.new(dic)
        h.memorize('ふ')
        h.memorize('が')
        h.memorize('ほ')
        h.memorize('げ')
      end

      it '辞書を取得する' do
        expect(dic.textdata).to eq "ふ\n" + "が\n" + "ほ\n" + 'げ'
        expect(dic.dict).to eq "line_num: 0\n"
      end
    end
  end
end
