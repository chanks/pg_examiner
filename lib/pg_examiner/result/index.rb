module PGExaminer
  class Result
    class Index < Base
      COMPARISON_COLUMNS = %w(relname)

      def name
        row['relname']
      end
    end
  end
end
