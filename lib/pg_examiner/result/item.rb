# frozen_string_literal: true

module PGExaminer
  class Result
    class Item < Base
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

      def inspect
        "#<#{self.class} @row=#{@row.inspect}>"
      end
    end
  end
end
