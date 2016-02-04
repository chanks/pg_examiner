# frozen_string_literal: true

module PGExaminer
  class Result
    class Language < Item
      def diffable_attrs
        {
          "name" => "name"
        }
      end
    end
  end
end
