# frozen_string_literal: true

module PGExaminer
  class Result
    class Index < Item
      def diffable_attrs
        {
          "name"         => "name",
          "filter"       => "filter expression",
          "indisunique"  => "index is unique",
          "indisprimary" => "index is primary key",
        }
      end

      def diffable_methods
        {
          "expression" => "expression"
        }
      end

      def expression
        @row['expression'] || @row['indkey'].split.map{|i| parent.columns.find{|c| c.row['attnum'] == i}}.map(&:name)
      end
    end
  end
end
