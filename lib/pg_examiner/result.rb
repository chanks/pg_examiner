require 'pg_examiner/result/base'
require 'pg_examiner/result/column'
require 'pg_examiner/result/extension'
require 'pg_examiner/result/index'
require 'pg_examiner/result/schema'
require 'pg_examiner/result/table'

module PGExaminer
  class Result
    attr_reader :pg_namespace, :pg_class, :pg_type, :pg_index, :pg_attrdef, :pg_attribute, :pg_extension

    def initialize(connection)
      @conn = connection

      @pg_namespace = execute "SELECT oid, * FROM pg_namespace WHERE nspname != 'information_schema' AND nspname NOT LIKE 'pg_%'"
      @pg_class     = execute "SELECT oid, * FROM pg_class"
      @pg_type      = execute "SELECT oid, * FROM pg_type"
      @pg_index     = execute "SELECT * FROM pg_index JOIN pg_class ON pg_class.oid = pg_index.indexrelid"
      @pg_attrdef   = execute "SELECT oid, pg_get_expr(adbin, adrelid) AS default, * FROM pg_attrdef"
      @pg_attribute = execute "SELECT * FROM pg_attribute WHERE NOT attisdropped"
      @pg_extension = execute "SELECT * FROM pg_extension"
    end

    def schemas
      @schemas ||= @pg_namespace.map{|row| Schema.new(self, row)}
    end

    def extensions
      @extensions ||= @pg_extension.map{|row| Extension.new(self, row)}.sort_by(&:name)
    end

    def ==(other)
      other.is_a?(Result) &&
        schemas == other.schemas &&
        extensions == other.extensions
    end

    def inspect
      "#<#{self.class} @schemas=#{@schemas.inspect}, @extensions=#{@extensions.inspect}>"
    end

    private

    def execute(*args)
      @conn.async_exec(*args).to_a
    end
  end
end
