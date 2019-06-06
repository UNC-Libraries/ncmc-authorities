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
      end
    end
  end
end
