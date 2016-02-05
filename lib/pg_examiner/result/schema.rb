# frozen_string_literal: true

module PGExaminer
  class Result
    class Schema < Item
      def diffable_lists
        {
          "tables"    => "tables",
          "sequences" => "sequences",
          "functions" => "functions",
        }
      end

      def tables
        @tables ||= result.pg_class.select do |c|
          c['relnamespace'] == oid && c['relkind'] == 'r'
        end.map{|row| Table.new(result, row, self)}.sort_by(&:name)
      end

      def sequences
        @sequences ||= result.pg_class.select do |c|
          c['relnamespace'] == oid && c['relkind'] == 'S'
        end.map{|row| Sequence.new(result, row, self)}.sort_by(&:name)
      end

      def functions
        @functions ||= result.pg_proc.select do |c|
          c['pronamespace'] == oid
        end.map{|row| Function.new(result, row, self)}.sort_by(&:name)
      end
    end
  end
end
