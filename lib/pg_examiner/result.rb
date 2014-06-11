require 'pg_examiner/result/base'
require 'pg_examiner/result/column'
require 'pg_examiner/result/extension'
require 'pg_examiner/result/schema'
require 'pg_examiner/result/table'

module PGExaminer
  class Result
    attr_reader :pg_namespace, :pg_attribute, :pg_class, :pg_type, :pg_attrdef

    def initialize(connection)
      @conn = connection

      @pg_namespace = execute "SELECT oid, * FROM pg_namespace WHERE nspname != 'information_schema' AND nspname NOT LIKE 'pg_%'"
      @pg_class     = execute "SELECT oid, * FROM pg_class"
      @pg_type      = execute "SELECT oid, * FROM pg_type"
      @pg_attrdef   = execute "SELECT oid, * FROM pg_attrdef"
      @pg_attribute = execute "SELECT * FROM pg_attribute"
      @pg_extension = execute "SELECT * FROM pg_extension"
    end

    def schemas
      @schemas ||= @pg_namespace.map { |row| Schema.new(self, row) }
    end

    def extensions
      @extensions ||= @pg_extension.map{|row| Extension.new(self, row)}.sort_by(&:name)
    end

    private

    def execute(*args)
      @conn.async_exec(*args).to_a
    end
  end
end
