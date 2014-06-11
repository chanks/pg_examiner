module PGExaminer
  class Result
    class Index < Base
      COMPARISON_COLUMNS = %w(name filter)

      def expression
        @row['expression'] || @row['indkey'].split.map{|i| parent.columns.find{|c| c.row['attnum'] == i}}.map(&:name)
      end

      def ==(other)
        super &&
          expression == other.expression
      end
    end
  end
end
