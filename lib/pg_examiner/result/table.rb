module PGExaminer
  class Result
    class Table < Base
      COMPARISON_COLUMNS = %w(relname relpersistence reloptions)

      def name
        row['relname']
      end

      def columns
        @columns ||= result.pg_attribute.select do |c|
          c['attrelid'] == oid &&
          c['attnum'].to_i > 0 # System columns have negative numbers.
        end.sort_by{|c| c['attnum'].to_i}.map { |row| Column.new(result, row) }
      end

      def indexes
        @indexes ||= result.pg_index.select do |c|
          c['indrelid'] == oid
        end.map{|row| Index.new(result, row)}.sort_by(&:name)
      end

      def ==(other)
        super &&
          columns == other.columns &&
          indexes == other.indexes
      end
    end
  end
end
