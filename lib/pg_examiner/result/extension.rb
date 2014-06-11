module PGExaminer
  class Result
    class Extension < Base
      def name
        row['extname']
      end

      def schema
        @schema ||= result.schemas.find { |s| s.oid == row['extnamespace'] }
      end
    end
  end
end
