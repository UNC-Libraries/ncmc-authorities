module NCMCAuthorities
  module Names
    RSpec.describe Personal do
      def quick_name(name_string)
        NCMCAuthorities::Names::Personal.new(name: name_string)
      end

      let(:name_string) { 'Ferguson, James E. (James Elliott), 1942-' }
      let(:name) { quick_name(name_string) }

      describe 'parsed_name' do
        it 'returns hash of name components' do
          expected = {
            dates: ['1942'],
            forename: 'james e',
            forename_initials: 'je',
            forename_variant: 'james elliott',
            initials: 'fje',
            supplemental: '',
            surname: 'ferguson',
            variant_initials: 'je'
          }
          expect(name.parsed_name).to eq(expected)
        end
      end

      describe '#surnames' do
        it 'returns tokenized surname' do
          name_string = 'Ferguson Walters, Pat'
          name = quick_name(name_string)
          expect(name.surnames).to eq(%w[ferguson walters])
        end
      end

      describe '#forename' do
        it 'returns forename string without variants' do
          expect(name.forename).to eq('james e')
        end
      end

      describe '#forenames' do
        it 'returns tokenized forename' do
          expect(name.forenames).to eq(%w[james e])
        end
      end

      describe '#supplemental' do
        it 'returns string of anything not included in surname/forename/dates' do
          name_string = 'A, B, foo, bar, 1942, baz'
          name = quick_name(name_string)
          expect(name.supplemental).to eq('foo bar baz')
        end
      end

      describe '#forename_initials' do
        it 'returns forename initials without whitespace' do
          expect(name.forename_initials).to eq('je')
        end
      end

      describe '#initials' do
        it 'returns surname/forename initials without whitespace' do
          expect(name.initials).to eq('fje')
        end
      end

      describe '#dates' do
        it 'returns array of date components' do
          expect(name.dates).to eq(['1942'])
        end
      end
    end
  end
end
