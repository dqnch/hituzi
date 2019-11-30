# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hituzi::Core do
  let(:h) { described_class.new(Hituzi::Dictionary.find_or_create_by(name: 'default')) }

  describe '#talk' do
    context '辞書登録なし' do
      it '何も言わない' do
        expect(h.talk).to eq ''
      end
    end

    context '辞書登録あり' do
      before { h.memorize('おはようございます') }

      it '何か言う' do
        expect(h.talk).to be_truthy
      end
    end
  end
end
