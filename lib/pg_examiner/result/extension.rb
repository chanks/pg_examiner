module PGExaminer
  class Result
    class Extension < Base
      COMPARISON_COLUMNS = %w(extname)

      def name
        row['extname']
      end

      def schema
        @schema ||= result.schemas.find { |s| s.oid == row['extnamespace'] }
      end
    end
  end
end
