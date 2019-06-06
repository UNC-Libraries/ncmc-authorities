module NCMCAuthorities
  module Matching
    RSpec.describe Match do
      describe '#rank' do
        let(:n1) { NCMCAuthorities::Names::Personal.new(name: 'Smith, Pat') }
        let(:n2) { NCMCAuthorities::Names::Personal.new(name: 'Smith, Pat') }
        let(:ranking) { Match.rank(n1, [n1, n2]) }

        it 'allows separate instances of the exact same name to match' do
          expect(ranking.select { |m| m.other_name.equal? n2}).not_to be_empty
        end

        it 'does not match the same instance of a submitted name with itself' do
          expect(ranking.select { |m| m.other_name.equal? n1}).to be_empty
          expect(ranking.length).to eq(1)
        end

      end
    end
  end
end
