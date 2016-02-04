# frozen_string_literal: true

module PGExaminer
  class Result
    class Trigger < Item
      def diffable_attrs
        [:name, :tgtype]
      end

      def diffable_methods
        [:function]
      end

      def function
        @function ||= result.pg_proc.find{|f| f['oid'] == @row['tgfoid']}['name']
      end
    end
  end
end
