module PGExaminer
  class Result
    class Constraint < Item
      def diffable_attrs
        [:name, :definition]
      end
    end
  end
end
