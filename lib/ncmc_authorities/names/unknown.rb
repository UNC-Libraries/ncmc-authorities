module NCMCAuthorities
  module Names

    module UnknownParent
      attr_accessor :parent_name
    end

    class Unknown < SubmittedName
      attr_reader :personal, :corporate, :family, :meeting

      def initialize(*args)
        super
        @type = 'unknown'
        typed_name_children(*args).each do |child|
          child.extend UnknownParent
          child.parent_name = self
        end
        typed_name_children.each { |child| child.blocks }
      end

      def typed_name_children(*args)
        [@personal ||= Names::Personal.new(*args),
         @corporate ||= Names::Corporate.new(*args),
         @family ||= Names::Family.new(*args),
         @meeting ||= Names::Meeting.new(*args)]
      end

      CATEGORY_RANKS = {strong: 1, moderate: 2, weak: 3, bad: 4}

      def ranking
        return @ranking if @ranking

        acc = []
        [@personal, @corporate, @family, @meeting].each do |type_name|
          acc += type_name.ranking
          type_name.clear_ranking
        end

        @ranking = acc.sort_by { |m| [CATEGORY_RANKS[m.category], -m.score] }.
                       uniq { |m| m.other_name.respond_to?(:parent_name) ? m.other_name.parent_name : m.other_name }
      end

      def self.block(*args)
        # covered by initialization
      end
    end
  end
end
