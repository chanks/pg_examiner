# frozen_string_literal: true

module PGExaminer
  class Result
    class Table < Item
      def diffable_lists
        {
          "columns"     => "columns",
          "indexes"     => "indexes",
          "constraints" => "constraints",
          "triggers"    => "triggers",
          "permissions" => "permissions",
        }
      end

      def diffable_attrs
        {
          "name"           => "name",
          "relpersistence" => "table type (relpersistence)",
          "reloptions"     => "table options",
        }
      end

      def columns
        @columns ||= result.pg_attribute.select do |c|
          c['attrelid'] == oid
        end.sort_by{|c| c['name']}.map { |row| Column.new(result, row, self) }
      end

      def indexes
        @indexes ||= result.pg_index.select do |c|
          c['indrelid'] == oid
        end.map{|row| Index.new(result, row, self)}.sort_by(&:name)
      end

      def constraints
        @constraints ||= result.pg_constraint.select do |c|
          c['conrelid'] == oid
        end.map{|row| Constraint.new(result, row, self)}.sort_by(&:name)
      end

      def triggers
        @triggers ||= result.pg_trigger.select do |t|
          t['tgrelid'] == oid
        end.map{|row| Trigger.new(result, row, self)}.sort_by(&:name)
      end

      def permissions
        @permissions ||= begin
          if acl = @row["relacl"]
            acl[/^{(.*)}$/, 1].split(",").map{|acl| Permission.new(acl)}.sort_by(&:name)
          else
            []
          end
        end
      end

      class Permission < Base
        attr_accessor :name, :grantor, :permissions

        CHARS_TO_LABELS = {
          "r" => "SELECT", # "read"
          "w" => "UPDATE", # "write"
          "a" => "INSERT", # "append"
          "d" => "DELETE",
          "D" => "TRUNCATE",
          "x" => "REFERENCES",
          "t" => "TRIGGER",
        }.freeze

        def initialize(acl)
          @name, permissions = acl.split("=")
          permissions, @grantor = permissions.split("/")
          @permissions = permissions.split("").map{|char| CHARS_TO_LABELS.fetch(char)}
        end

        def diffable_methods
          {
            "grantor"     => "grantor",
            "permissions" => "permissions",
          }
        end
      end
    end
  end
end
