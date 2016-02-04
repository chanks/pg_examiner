# frozen_string_literal: true

module PGExaminer
  class Result
    class Table < Item
      def diffable_lists
        [:columns, :indexes, :constraints, :triggers]
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
        end.sort_by{|c| c['attnum'].to_i}.map { |row| Column.new(result, row, self) }
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
    end
  end
end
