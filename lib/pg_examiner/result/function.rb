# frozen_string_literal: true

module PGExaminer
  class Result
    class Function < Item
      def diffable_attrs
        {
          "name"        => "name",
          "proargmodes" => "argument modes",
          "definition"  => "function definition",
        }
      end

      def diffable_methods
        {
          "argument_types" => "argument types",
          "return_type"    => "return type",
          "language"       => "language",
        }
      end

      def argument_types
        @argument_types ||= @row['proargtypes'].split.map do |oid|
          result.pg_type.find{|t| t['oid'] == oid}['name']
        end
      end

      def return_type
        @return_type ||= result.pg_type.find{|t| t['oid'] == @row['prorettype']}['name']
      end

      def language
        @language ||= result.pg_language.find{|l| l['oid'] == @row['prolang']}['name']
      end
    end
  end
end
