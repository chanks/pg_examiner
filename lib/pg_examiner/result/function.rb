module PGExaminer
  class Result
    class Function < Base
      COMPARISON_COLUMNS = %w(name proargmodes)

      def argument_types
        @argument_types ||= @row['proargtypes'].split.map do |oid|
          result.pg_type.find{|t| t['oid'] == oid}['name']
        end
      end

      def return_type
        @return_type ||= result.pg_type.find{|t| t['oid'] == @row['prorettype']}['name']
      end

      def ==(other)
        super &&
          argument_types == other.argument_types &&
          return_type    == other.return_type
      end
    end
  end
end
