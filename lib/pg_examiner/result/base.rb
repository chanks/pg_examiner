module PGExaminer
  class Result
    class Base
      attr_reader :result, :row

      def initialize(result, row)
        @result, @row = result, row
      end

      def oid
        @row['oid']
      end
    end
  end
end
