module PGExaminer
  class Result
    class Function < Base
      COMPARISON_COLUMNS = %w(name)

      def argument_types
        @argument_types ||= @row['proargtypes'].split.map do |oid|
          result.pg_type.find{|t| t['oid'] == oid}['name']
        end
      end

      def ==(other)
        super &&
          argument_types == other.argument_types
      end
    end
  end
end
