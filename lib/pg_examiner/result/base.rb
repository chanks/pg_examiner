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

      def name
        @row['name']
      end

      def ==(other)
        columns = self.class::COMPARISON_COLUMNS
        self.class == other.class && row.values_at(*columns) == other.row.values_at(*columns)
      end

      def inspect
        "#<#{self.class} @row=#{@row.inspect}>"
      end
    end
  end
end
