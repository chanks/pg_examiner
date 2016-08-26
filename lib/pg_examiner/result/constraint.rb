# frozen_string_literal: true

module PGExaminer
  class Result
    class Constraint < Item
      def diffable_attrs
        {
          "name"          => "name",
          "contype"       => "constraint type",
          "condeferrable" => "constraint is deferrable",
          "condeferred"   => "constraint is initially deferred",
          "convalidated"  => "constraint is validated",
          "connoinherit"  => "constraint is not inheritable",
          "confupdtype"   => "foreign key on update",
          "confdeltype"   => "foreign key on delete",
          "confmatchtype" => "foreign key match type",
          "consrc"        => "check constraint definition",
        }
      end

      def diffable_methods
        {
          "type"                        => "type",
          "index"                       => "index",
          "foreign_table_name"          => "table referenced by foreign key",
          "constrained_columns"         => "local constrained columns",
          "foreign_constrained_columns" => "foreign constrained columns",
        }
      end

      def type
        @type ||= result.pg_type.find{|t| t['oid'] == row['contypid']}['name'] if row['contypid'] != '0'
      end

      def index
        @index ||= result.pg_index.find{|i| i['indexrelid'] == row['conindid']}['name'] if row['conindid'] != '0'
      end

      def foreign_table_name
        foreign_table.name if foreign_table
      end

      def foreign_table
        if row['confrelid'] != '0'
          @foreign_table ||= begin
            table  = parent
            schema = table.parent

            unless t = schema.tables.find{|t| t.oid == row['confrelid']}
              raise "Table targeted by foreign key doesn't exist in the same schema"
            end

            t
          end
        end
      end

      def constrained_columns
        @constrained_columns ||= extract_array(row['conkey']).map{|n| parent.columns.find{|c| c.row['attnum'] == n}.name} if row['conkey']
      end

      def foreign_constrained_columns
        @foreign_constrained_columns ||= extract_array(row['confkey']).map{|n| foreign_table.columns.find{|c| c.row['attnum'] == n}.name} if row['confkey']
      end
    end
  end
end
