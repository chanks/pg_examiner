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
          "foreign_key_update_action"   => "foreign key on update action",
          "foreign_key_delete_action"   => "foreign key on delete action",
          "foreign_key_match_type"      => "foreign key match type",
        }
      end

      def type
        @type ||= result.pg_type.find{|t| t['oid'] == row['contypid']}['name'] if row['contypid'] != '0'
      end

      def index
        @index ||= result.pg_index.find{|i| i['indexrelid'] == row['conindid']}['name'] if row['conindid'] != '0'
      end

      def foreign_table_name
        if ft = foreign_table
          this_schema_name = parent.parent.name
          that_schema_name = ft.parent.name

          relative_schema =
            if this_schema_name == that_schema_name
              "(same schema)"
            else
              "#{that_schema_name} schema"
            end

          [relative_schema, ft.name]
        end
      end

      def foreign_table
        if row['confrelid'] != '0'
          @foreign_table ||= begin
            # Look up the table, which may be outside our own schema.
            table_row = result.pg_class.find { |c| c['relkind'] == 'r' && c['oid'] == row['confrelid'] }
            schema = result.schemas.find { |s| s.oid == table_row['relnamespace'] }
            schema.tables.find { |t| t.name == table_row['name'] }
          end
        end
      end

      def constrained_columns
        @constrained_columns ||= extract_array(row['conkey']).map{|n| parent.columns.find{|c| c.row['attnum'] == n}.name} if row['conkey']
      end

      def foreign_constrained_columns
        @foreign_constrained_columns ||= extract_array(row['confkey']).map{|n| foreign_table.columns.find{|c| c.row['attnum'] == n}.name} if row['confkey']
      end

      FOREIGN_KEY_ACTIONS = {
        "a" => "no action",
        "r" => "restrict",
        "c" => "cascade",
        "n" => "set null",
        "d" => "set default",
      }.freeze

      def foreign_key_update_action
        FOREIGN_KEY_ACTIONS.fetch(row['confupdtype']) if row['confupdtype'] != ' '
      end

      def foreign_key_delete_action
        FOREIGN_KEY_ACTIONS.fetch(row['confdeltype']) if row['confdeltype'] != ' '
      end

      FOREIGN_KEY_MATCH_TYPES = {
        "f" => "full",
        "p" => "partial",
        "s" => "simple",
      }.freeze

      def foreign_key_match_type
        FOREIGN_KEY_MATCH_TYPES.fetch(row['confmatchtype']) if row['confmatchtype'] != ' '
      end
    end
  end
end
