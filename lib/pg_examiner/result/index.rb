module PGExaminer
  class Result
    class Index < Item
      def diffable_attrs
        [:name, :filter, :indisunique, :indisprimary]
      end

      def diffable_methods
        [:expression]
      end

      def expression
        @row['expression'] || @row['indkey'].split.map{|i| parent.columns.find{|c| c.row['attnum'] == i}}.map(&:name)
      end
    end
  end
end
