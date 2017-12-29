# frozen_string_literal: true

module PGExaminer
  class Result
    class Column < Item
      def initialize(*args)
        super
        @default_calculated = false
      end

      def diffable_methods
        {
          "type"    => "type",
          "default" => "default"
        }
      end

      def diffable_attrs
        {
          'name'       => "name",
          'attndims'   => "array dimensionality",
          'attnotnull' => "column is marked not-null",
          'atttypmod'  => "datatype information (atttypmod)",
        }
      end

      def type
        @type ||= result.pg_type.find{|t| t['oid'] == row['atttypid']}['name']
      end

      def default
        # Have to dance a bit so that the lack of a default becomes nil, but isn't recalculated each time.
        if @default_calculated
          @default
        else
          @default_calculated = true
          @default = result.pg_attrdef.find{|d| d['adrelid'] == row['attrelid'] && d['adnum'] == row['attnum']}['default'] if row['atthasdef'] == 't'
        end
      end
    end
  end
end
