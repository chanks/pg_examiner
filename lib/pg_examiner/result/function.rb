module PGExaminer
  class Result
    class Function < Base
      COMPARISON_COLUMNS = %w(name proargmodes definition)

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

      def ==(other)
        super &&
          argument_types == other.argument_types &&
          return_type    == other.return_type &&
          language       == other.language
      end
    end
  end
end
