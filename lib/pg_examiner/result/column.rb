module PGExaminer
  class Result
    class Column < Base
      COMPARISON_COLUMNS = %w(name attndims attnotnull atttypmod)

      def type
        @type ||= result.pg_type.find{|t| t['oid'] == row['atttypid']}['name']
      end

      def default
        # Have to dance a bit so that the lack of a default becomes nil, but isn't recalculated each time.
        if @default_calculated
          @default
        else
          @default_calculated = true
          @default = result.pg_attrdef.find{|d| d['adrelid'] == row['attrelid']}['default'] if row['atthasdef'] == 't'
        end
      end

      def ==(other)
        super &&
          type == other.type &&
          default == other.default
      end
    end
  end
end
