# frozen_string_literal: true

module PGExaminer
  class Result
    class Constraint < Item
      def diffable_attrs
        {
          "name"       => "name",
          "definition" => "constraint definition",
        }
      end
    end
  end
end
