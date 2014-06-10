module PGExaminer
  class Result
    class Extension
      attr_reader :result, :row

      def initialize(result, row)
        @result = result
        @row    = row
      end

      def name
        row['extname']
      end

      def schema
        @schema ||= result.schemas.find { |s| s.oid == row['extnamespace'] }
      end
    end
  end
end
