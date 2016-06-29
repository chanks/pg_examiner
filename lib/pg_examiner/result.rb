# frozen_string_literal: true

require 'pg_examiner/base'

module PGExaminer
  class Result < Base
    attr_reader :pg_namespace,
                :pg_class,
                :pg_type,
                :pg_index,
                :pg_attrdef,
                :pg_attribute,
                :pg_extension,
                :pg_constraint,
                :pg_proc,
                :pg_language,
                :pg_trigger

    def initialize(connection)
      @conn = connection
      load_schema
    end

    def diffable_lists
      {
        "schemas"    => "schemas",
        "extensions" => "extensions",
        "languages"  => "languages",
      }
    end

    def schemas
      @schemas ||= @pg_namespace.map{|row| Schema.new(self, row)}.sort_by(&:name)
    end

    def extensions
      @extensions ||= @pg_extension.map{|row| Extension.new(self, row)}.sort_by(&:name)
    end

    def languages
      @languages ||= @pg_language.map{|row| Language.new(self, row)}.sort_by(&:name)
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
        SELECT oid, nspname AS name
        FROM pg_namespace
        WHERE nspname != 'information_schema'
        AND nspname NOT LIKE 'pg_%'
      SQL

      @pg_class = load_table @pg_namespace.map{|ns| ns['oid']}, <<-SQL
        SELECT oid, relname AS name, relkind, relpersistence, reloptions, relnamespace
        FROM pg_class
        WHERE relnamespace IN (?)
      SQL

      @pg_attribute = load_table @pg_class.map{|ns| ns['oid']}, <<-SQL
        SELECT atttypid, attname AS name, attndims, attnotnull, atttypmod, attrelid, atthasdef, attnum
        FROM pg_attribute
        WHERE attrelid IN (?)
        AND attnum > 0       -- No system columns
        AND NOT attisdropped -- Still active
      SQL

      @pg_type = execute <<-SQL
        SELECT oid, typname AS name
        FROM pg_type
      SQL

      @pg_index = load_table @pg_class.map{|ns| ns['oid']}, <<-SQL
        SELECT c.relname AS name, i.indrelid, i.indkey, indisunique, indisprimary,
          pg_get_expr(i.indpred, i.indrelid) AS filter,
          pg_get_expr(i.indexprs, i.indrelid) AS expression
        FROM pg_index i
        JOIN pg_class c ON c.oid = i.indexrelid
        WHERE c.oid IN (?)
      SQL

      @pg_constraint = load_table @pg_class.map{|ns| ns['oid']}, <<-SQL
        SELECT oid, conname AS name, conrelid,
          pg_get_constraintdef(oid) AS definition
        FROM pg_constraint c
        WHERE conrelid IN (?)
      SQL

      @pg_trigger = load_table @pg_class.map{|ns| ns['oid']}, <<-SQL
        SELECT oid, tgname AS name, tgrelid, tgtype, tgfoid
        FROM pg_trigger
        WHERE tgrelid IN (?)
        AND NOT tgisinternal -- Ignore foreign key and unique index triggers, which have unpredictable names.
      SQL

      @pg_attrdef = execute <<-SQL
        SELECT oid, adrelid, adnum, pg_get_expr(adbin, adrelid) AS default
        FROM pg_attrdef
      SQL

      @pg_proc = load_table @pg_namespace.map{|ns| ns['oid']}, <<-SQL
        SELECT oid, proname AS name, pronamespace, proargtypes, prorettype, proargmodes, prolang, pg_get_functiondef(oid) AS definition
        FROM pg_proc
        WHERE pronamespace IN (?)
        AND NOT proisagg -- prevent pg_get_functiondef() from throwing errors on aggregate functions.
      SQL

      @pg_extension = execute <<-SQL
        SELECT extname AS name, extnamespace, extversion
        FROM pg_extension
      SQL

      @pg_language = execute <<-SQL
        SELECT oid, lanname AS name
        FROM pg_language
      SQL
    end

    def load_table(oids, sql)
      if oids.any?
        execute sql.gsub(/\?/, oids.map{|oid| "'#{oid}'"}.join(', '))
      else
        []
      end
    end
  end
end

require 'pg_examiner/result/item'
require 'pg_examiner/result/column'
require 'pg_examiner/result/constraint'
require 'pg_examiner/result/extension'
require 'pg_examiner/result/function'
require 'pg_examiner/result/index'
require 'pg_examiner/result/language'
require 'pg_examiner/result/schema'
require 'pg_examiner/result/sequence'
require 'pg_examiner/result/table'
require 'pg_examiner/result/trigger'
