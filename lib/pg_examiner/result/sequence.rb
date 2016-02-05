# frozen_string_literal: true

module PGExaminer
  class Result
    class Sequence < Item
      def diffable_lists
        {}
      end

      def diffable_attrs
        {}
      end
    end
  end
end
