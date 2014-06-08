module PGSchemaExaminer
  class Result
    class Schema
      attr_reader :result, :row

      def initialize(result, row)
        @result = result
        @row    = row
      end

      def name
        row['nspname']
      end

      def tables
        @tables ||= result.pg_class.select do |c|
          c['relnamespace'] == row['oid'] &&
          c['relkind'] == 'r'
        end.map { |row| Table.new(result, row) }
      end
    end
  end
end
