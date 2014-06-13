require 'pg_examiner/result'
require 'pg_examiner/version'

module PGExaminer
  class << self
    def examine(connection, schema = nil)
      result = Result.new(connection)

      if schema
        result.schemas.find { |s| s.name == schema.to_s }
      else
        result
      end
    end
  end
end
