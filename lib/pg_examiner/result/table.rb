module PGExaminer
  class Result
    class Table < Base
      COMPARISON_COLUMNS = %w(relname)

      def name
        row['relname']
      end

      def columns
        @columns ||= result.pg_attribute.select do |c|
          c['attrelid'] == row['oid'] &&
          c['attnum'].to_i > 0 # System columns have negative numbers.
        end.sort_by{|c| c['attnum'].to_i}.map { |row| Column.new(result, row) }
      end

      def ==(other)
        super && columns == other.columns
      end
    end
  end
end
