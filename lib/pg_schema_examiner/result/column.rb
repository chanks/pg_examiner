module PGSchemaExaminer
  class Result
    class Column
      attr_reader :result, :row

      def initialize(result, row)
        @result = result
        @row    = row
      end

      def name
        row['attname']
      end

      def type
        @type ||= result.pg_type.find{|t| t['oid'] == row['atttypid']}['typname']
      end

      def default
        # Have to dance a bit so that the lack of a default becomes nil, but isn't recalculated each time.
        if @default_calculated
          @default
        else
          @default_calculated = true
          @default = result.pg_attrdef.find{|d| d['adrelid'] == row['attrelid']}['adsrc'] if row['atthasdef'] == 't'
        end
      end
    end
  end
end
