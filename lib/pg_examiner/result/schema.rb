module PGExaminer
  class Result
    class Schema < Base
      COMPARISON_COLUMNS = %w(name)

      def tables
        @tables ||= result.pg_class.select do |c|
          c['relnamespace'] == oid && c['relkind'] == 'r'
        end.map{|row| Table.new(result, row, self)}.sort_by(&:name)
      end

      def functions
        @functions ||= result.pg_proc.select do |c|
          c['pronamespace'] == oid
        end.map{|row| Function.new(result, row, self)}.sort_by(&:name)
      end

      def ==(other)
        super &&
          tables    == other.tables &&
          functions == other.functions
      end
    end
  end
end
