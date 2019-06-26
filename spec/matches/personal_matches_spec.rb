module NCMCAuthorities
  RSpec.describe Match do

    def spec_match(name1, name2)
      n1 = NCMCAuthorities::Names::Personal.new(name: name1)
      n2 = NCMCAuthorities::Names::Personal.new(name: name2)
      Match.new(n1, n2)
    end

    describe 'blah' do
      it 'Gove, Anna M. (Anna Maria), 1867-1948' do
        n1 = NCMCAuthorities::Names::Personal.new(name: 'Gove, Anna M. (Anna Maria), 1867-1948')
        n2 = NCMCAuthorities::Names::Unknown.new(name: 'Gove, Anna Maria')
        match = Match.new(n1, n2.personal)
        expect(match.score).to eq(1.0)
      end
    end

    describe 'surname only cap' do
      it 'does not apply to exact matches' do
        n1 = NCMCAuthorities::Names::Personal.new(name: 'Boston Bookbinding Company')
        n2 = NCMCAuthorities::Names::Personal.new(name: 'Boston Bookbinding Company')
        match = Match.new(n1, n2)
        expect(match.score).to eq(1.0)
      end
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
          ['Smith, Pat Lee', 'Smith, P L (Pat Lee)']
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
          ['Smith, M. D.', 'Smith, M'],
          ['Bacon, Henry, 1866-1924.', 'Bacon, Henry, 1839-1912']
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

    describe '#score treatment of dates' do
      context 'only one name contains dates' do
        it 'dates do not affect scoring' do
          match1 = spec_match('Graham, William A., 1875-1911', 'Graham, William A.')
          match2 = spec_match('Graham, William A.', 'Graham, William A.')
          expect(match1.score).to eq(match2.score)
        end
      end

      context 'both names contain dates' do

        context 'a name contains more than two dates' do
          it 'does not compare dates' do
            match1 = spec_match('Graham, William A., 1875-1911-1999', 'Graham, William B. 1600-1605')
            match2 = spec_match('Graham, William A.', 'Graham, William B.')
          expect(match1.score).to eq(match2.score)
          end
        end

        context 'one name contains 1 date, the other 2 dates' do
          context 'the one date matches either of the 2 dates' do
            it 'the score is increased' do
              match1 = spec_match('Graham, William A., 1875', 'Graham, William B. 1600-1875')
              match2 = spec_match('Graham, William A.', 'Graham, William B.')
              expect(match1.score).to be > match2.score
            end
          end

          context 'the one date does not have a match' do
            it 'the score is penalized' do
              match1 = spec_match('Graham, William A., 1875', 'Graham, William B. 1600-1605')
              match2 = spec_match('Graham, William A.', 'Graham, William B.')
              expect(match1.score).to be < match2.score
            end
          end
        end

        context 'the names have the same number of dates' do
          it 'the nth dates of each name are compared with each other' do
            match1 = spec_match('Graham, William A., 1875-1600', 'Graham, William B. 1600-1875')
            match2 = spec_match('Graham, William A.', 'Graham, William B.')
            expect(match1.score).to be < match2.score
          end

          context 'both dates match' do
            it 'the score is increased' do
              match1 = spec_match('Graham, William A., 1600-1875', 'Graham, William B. 1600-1875')
              match2 = spec_match('Graham, William A.', 'Graham, William B.')
              expect(match1.score).to be > match2.score
            end
          end

          context 'one date does not match' do
            it 'the score is unaffected' do
              match1 = spec_match('Graham, William A., 1870-1875', 'Graham, William B. 1600-1875')
              match2 = spec_match('Graham, William A.', 'Graham, William B.')
              expect(match1.score).to eq(match2.score)
            end
          end

          context 'two dates do not match' do
            it 'the score is penalized' do
              match1 = spec_match('Graham, William A., 1870-1875', 'Graham, William B. 1600-1605')
              match2 = spec_match('Graham, William A.', 'Graham, William B.')
              expect(match1.score).to be < match2.score
            end
          end
        end

        it 'dates "match" if they are within one year' do
          match1 = spec_match('Graham, William A., 1600-1875', 'Graham, William B. 1601-1876')
          match2 = spec_match('Graham, William A.', 'Graham, William B.')
          expect(match1.score).to be > match2.score
        end
      end
    end

    describe '.variant_switcher' do
      context 'both names contain variant/qualifier forenames' do
        it 'uses the variant names as the forename' do
          match = spec_match('Lewis, Alcinda L. (Alcinda Long)',
                              'Lewis, A. L. (Abraham Lincoln), 1865-1947.')
          expect(match.explanation).to have_key(:variant_forename_used)
        end
      end

      context 'one name contains variant/qualifier forenames' do
        context 'when the forename lacking variant is more than just initials' do
          it 'uses the longest of the non-variant and variant forenames' do
            match = spec_match('Lewis, Alcinda L.',
                                'Lewis, A. L. (Abraham Lincoln), 1865-1947.')
            match2 = spec_match('Lewis, Alcinda L.',
                                'Lewis, Abraham Lincoln (A. L.), 1865-1947.')
            expect(match.explanation).to include(:variant_forename_used)
            expect(match2.explanation).not_to include(:variant_forename_used)
          end
        end

        context 'when the forename lacking variant is just initials' do
          it 'uses the shortest of the non-variant and variant forenames' do
            match = spec_match('Lewis, A. L.',
                                'Lewis, A. L. (Abraham Lincoln), 1865-1947.')
            match2 = spec_match('Lewis, A. L.',
                                'Lewis, Abraham Lincoln (A. L.), 1865-1947.')
            expect(match.explanation).not_to have_key(:variant_forename_used)
            expect(match2.explanation).to have_key(:variant_forename_used)
          end
        end
      end

      context 'neither names contains variant/qualifier forenames' do
        it 'does nothing' do
          n1 = NCMCAuthorities::Names::Personal.new(name: 'Lewis, A. L.')
          n2 = NCMCAuthorities::Names::Personal.new(name: 'Lewis, A. L.')
          expect(NCMCAuthorities::Match.variant_switcher(n1, n2)).
            to eq([n1.forename, n2.forename, false])
        end
      end
    end
  end
end
