module PGExaminer
  class Result
    class Base
      attr_reader :result, :row, :parent

      def initialize(result, row, parent = nil)
        @result, @row, @parent = result, row, parent
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
