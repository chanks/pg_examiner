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
      load_schema
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

    def load_schema
      # Get all relevant schemas/namespaces, which includes public but not
      # information_schema or system schemas, which are prefixed with pg_. It
      # wouldn't be a good practice for anyone to name a custom schema
      # starting with pg_ anyway.
      @pg_namespace = execute <<-SQL
        SELECT oid, nspname
        FROM pg_namespace
        WHERE nspname != 'information_schema'
        AND nspname NOT LIKE 'pg_%'
      SQL

      schema_oids = @pg_namespace.map{|ns| "'#{ns['oid']}'"}

      @pg_class = execute <<-SQL
        SELECT oid, relname, relkind, relpersistence, reloptions, relnamespace
        FROM pg_class
        WHERE relnamespace IN (#{schema_oids.join(', ')})
      SQL

      table_oids = @pg_class.map{|ns| "'#{ns['oid']}'"}

      @pg_attribute =
        if table_oids.any?
          execute <<-SQL
            SELECT atttypid, attname, attndims, attnotnull, atttypmod, attrelid, atthasdef
            FROM pg_attribute
            WHERE attrelid IN (#{table_oids.join(', ')})
            AND attnum > 0       -- No system columns
            AND NOT attisdropped -- Still active
          SQL
        else
          []
        end

      att_oids = @pg_attribute.map{|a| "'#{a['atttypid']}'"}

      @pg_type = if att_oids.any?
        execute <<-SQL
          SELECT oid, typname
          FROM pg_type
          WHERE oid IN (#{att_oids.join(', ')})
        SQL
      else
        []
      end

      @pg_index = if table_oids.any?
        execute <<-SQL
          SELECT c.relname, i.indrelid
          FROM pg_index i
          JOIN pg_class c ON c.oid = i.indexrelid
          WHERE c.oid IN (#{table_oids.join(', ')})
        SQL
      else
        []
      end

      @pg_attrdef = execute <<-SQL
        SELECT oid, adrelid, pg_get_expr(adbin, adrelid) AS default
        FROM pg_attrdef
      SQL

      @pg_extension = execute <<-SQL
        SELECT extname, extnamespace, extversion
        FROM pg_extension
      SQL
    end
  end
end
