# frozen_string_literal: true

module PGExaminer
  class Result
    class Extension < Item
      def diffable_attrs
        [:name, :extversion]
      end

      def diffable_methods
        [:schema_name]
      end

      def schema
        # Extensions installed in system schemas won't be returned, so @schema
        # will be nil in that case.

        if @schema_calculated
          @schema
        else
          @schema_calculated = true
          @schema = result.schemas.find{|s| s.oid == row['extnamespace']}
        end
      end

      def schema_name
        schema && schema.name
      end
    end
  end
end
