module NCMCAuthorities
  module Names
    RSpec.describe SubmittedName do
      def quick_name(name_string)
        NCMCAuthorities::Names::SubmittedName.new(name: name_string)
      end

      let(:name_string) { 'Ferguson, James E. (James Elliott), 1942-' }
      let(:name) { quick_name(name_string) }

      describe '.initialize' do
        it 'accepts a minimal hash' do
          expect(NCMCAuthorities::Names::SubmittedName.new(name: name_string)).
            to eq(name)
        end

        it 'cleans name_type values' do
          name = NCMCAuthorities::Names::SubmittedName.new(name: name_string,
                                                           name_type: 'person')
          expect(name.type).to eq('personal')
        end

        describe '.clean_name_type' do
          it 'is not case sensitive' do
            name = NCMCAuthorities::Names::SubmittedName.new(name: name_string,
              name_type: 'Person')
            expect(name.type).to eq('personal')
          end
        end
      end
    end
  end
end
