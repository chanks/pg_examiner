module PGExaminer
  class Result
    class Schema < Base
      COMPARISON_COLUMNS = %w()

      def tables
        @tables ||= result.pg_class.select do |c|
          c['relnamespace'] == oid && c['relkind'] == 'r'
        end.map{|row| Table.new(result, row, self)}.sort_by(&:name)
      end

      def functions
        @functions ||= result.pg_proc.select do |c|
          c['pronamespace'] == oid
        end.map{|row| Function.new(result, row, self)}.sort_by(&:name)
      end

      def ==(other)
        super &&
          tables    == other.tables &&
          functions == other.functions
      end


      def diff(other)
        d = {}
        this = tables.map(&:name)
        that = other.tables.map(&:name)

        unless this == that
          added   = that - this
          removed = this - that

          h = {}
          h[:added]   = added   if added.any?
          h[:removed] = removed if removed.any?
          d[:tables] = h
        end

        d
      end
    end
  end
end
