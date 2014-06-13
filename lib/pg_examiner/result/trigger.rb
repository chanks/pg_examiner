module PGExaminer
  class Result
    class Trigger < Base
      COMPARISON_COLUMNS = %w(name tgtype)

      def function
        @function ||= result.pg_proc.find{|f| f['oid'] == @row['tgfoid']}['name']
      end

      def ==(other)
        super &&
          function == other.function
      end
    end
  end
end
