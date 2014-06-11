module PGExaminer
  class Result
    class Schema < Base
      def name
        row['nspname']
      end

      def tables
        @tables ||= result.pg_class.select do |c|
          c['relnamespace'] == oid && c['relkind'] == 'r'
        end.map{|row| Table.new(result, row)}.sort_by(&:name)
      end
    end
  end
end
