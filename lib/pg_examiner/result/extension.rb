module PGExaminer
  class Result
    class Extension < Base
      COMPARISON_COLUMNS = %w(extname extversion)

      def name
        row['extname']
      end

      def schema
        @schema ||= result.schemas.find { |s| s.oid == row['extnamespace'] }
      end

      def ==(other)
        super &&
          (schema && schema.name) == (other.schema && other.schema.name)
      end
    end
  end
end
