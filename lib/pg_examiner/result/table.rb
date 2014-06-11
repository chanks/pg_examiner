module PGExaminer
  class Result
    class Table < Base
      COMPARISON_COLUMNS = %w(name relpersistence reloptions)

      def columns
        @columns ||= result.pg_attribute.select do |c|
          c['attrelid'] == oid
        end.sort_by{|c| c['attnum'].to_i}.map { |row| Column.new(result, row, self) }
      end

      def indexes
        @indexes ||= result.pg_index.select do |c|
          c['indrelid'] == oid
        end.map{|row| Index.new(result, row, self)}.sort_by(&:name)
      end

      def ==(other)
        super &&
          columns == other.columns &&
          indexes == other.indexes
      end
    end
  end
end
