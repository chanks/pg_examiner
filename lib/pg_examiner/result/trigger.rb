# frozen_string_literal: true

module PGExaminer
  class Result
    class Trigger < Item
      def diffable_attrs
        {
          "name"   => "name",
          "tgtype" => "trigger firing conditions (tgtype)",
        }
      end

      def diffable_methods
        {
          "function" => "function"
        }
      end

      def function
        @function ||= result.pg_proc.find{|f| f['oid'] == @row['tgfoid']}['name']
      end
    end
  end
end
