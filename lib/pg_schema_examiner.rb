require 'pg_schema_examiner/result'
require 'pg_schema_examiner/version'

module PGSchemaExaminer
  class << self
    def examine(connection)
      Result.new(connection)
    end
  end
end
