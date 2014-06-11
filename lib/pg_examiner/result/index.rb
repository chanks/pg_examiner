module PGExaminer
  class Result
    class Index < Base
      COMPARISON_COLUMNS = %w(name filter)

      def column_names
        @row['indkey'].split.map{|i| parent.columns.find{|c| c.row['attnum'] == i}}.map(&:name)
      end

      def ==(other)
        super &&
          column_names == other.column_names
      end
    end
  end
end
