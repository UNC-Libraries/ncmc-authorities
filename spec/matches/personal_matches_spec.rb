module NCMCAuthorities
  module Matching
    RSpec.describe Match do

      def spec_match(name1, name2)
        n1 = NCMCAuthorities::Names::Personal.new(name: name1)
        n2 = NCMCAuthorities::Names::Personal.new(name: name2)
        Match.new(n1, n2)
      end

      describe '#score' do
        before(:each) { @match = nil}
        after(:each) { |example| puts "\n--\n#{@match.explanation}" if example.exception}

        context 'scores at least weak:' do
          names = [
            ['Smith', 'Smith, P'],
            ['Smith, P', 'Smith, Pat'],
            ['Smith, Pat Lee', 'Smith, P L'],
            ['Smith, Part Lee', 'Smith, Pat L'],
            ['Shivashanmugam, Perumal.', 'Sivashanmugam, P'],
            ['Smith, Principal Lee', 'Smith, Principle L'],
            ['Jeyaraj, D Antony', 'Jeyaraj, Durairaj A'],
            #['Holmes, Billy', 'Holmes, William'],
            ['Joseph, Erold', 'Joseph, Hérold'],
            ['Miot, Joseph Serge', 'Miot, Serge'],
          ]

          names.each do |name_array|
            n1, n2 = name_array
            it "#{n1} -- #{n2}" do
              @match = spec_match(n1, n2)
              expect(@match.score).to be >= 0.70
            end
          end
        end

        context 'scores strong' do
          names = [
            ['Hariot, Thomas, 1560-1621', 'Harriot, Thomas, 1560-1621'],
          ]

          names.each do |name_array|
            n1, n2 = name_array
            it "#{n1} -- #{n2}" do
              @match = spec_match(n1, n2)
              expect(@match.score).to be >= 0.90
            end
          end
        end

        context 'scores at least moderate:' do
          names = [
            ['Guerre, Rockefeller', 'Guerre, Rockefeller, Madame'],
            ['Bouchereau, Guylène', 'Bouchereau, Guilène'],
            ['Smith, Pat Lee', 'Smith, Pat L'],
            ['Smith, Pat Lee', 'Smith, P L'],
            ['Smith, Pat Lee', 'Smith, Pat'],
            ['Harkema, Reinard', 'Harkema, Reinard, Mrs.'],
          ]

          names.each do |name_array|
            n1, n2 = name_array
            it "#{n1} -- #{n2}" do
              @match = spec_match(n1, n2)
              expect(@match.score).to be >= 0.80
            end
          end
        end

        context 'scores at most moderate:' do
          names = [
            ['Rubin, Larry, 1942-', 'Rubin, Barry'],
            ['Russell, Letty M.', 'Russell, Mackenzie L'],
            ['Smith, M. D.', 'Smith, M']
          ]

          names.each do |name_array|
            n1, n2 = name_array
            it "#{n1} -- #{n2}" do
              @match = spec_match(n1, n2)
              expect(@match.score).to be < 0.90
            end
          end
        end

        context 'scores at most weak:' do
          names = [
            ['Bartlett, David L.', 'Bartlett, Levi'],
            ['Beaker, H.J.', 'Baker, Henry'],
            ['Smith, Pat B', 'Smith, Pat L'],
            ['Smith, Pat Bee', 'Smith, Pat L'],
            ['Caldwell, Bettie D.', 'Caldwell, David'],
          ]

          names.each do |name_array|
            n1, n2 = name_array
            it "#{n1} -- #{n2}" do
              @match = spec_match(n1, n2)
              expect(@match.score).to be < 0.80
            end
          end
        end

        context 'scores bad:' do
          names = [
            ['Beaker, H.J.', 'Baker, N. C.']
          ]

          names.each do |name_array|
            n1, n2 = name_array
            it "#{n1} -- #{n2}" do
              @match = spec_match(n1, n2)
              expect(@match.score).to be < 0.70
            end
          end
        end
      end
    end
  end
end
