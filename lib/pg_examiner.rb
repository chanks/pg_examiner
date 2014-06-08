require 'pg_examiner/result'
require 'pg_examiner/version'

module PGExaminer
  class << self
    def examine(connection)
      Result.new(connection)
    end
  end
end
