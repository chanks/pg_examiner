# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should be able to tell when a table exists" do
    result = examine <<-SQL
      CREATE TABLE test_table (
        id serial,
        body text
      )
    SQL

    result.should be_an_instance_of PGExaminer::Result
    result.schemas.length.should == 1

    schema = result.schemas.first
    schema.should be_an_instance_of PGExaminer::Result::Schema
    schema.name.should == 'public'
    schema.tables.length.should == 1

    table = schema.tables.first
    table.should be_an_instance_of PGExaminer::Result::Table
    table.columns.length.should == 2

    body, id = table.columns # Returned in alphabetical ordering

    id.should be_an_instance_of PGExaminer::Result::Column
    id.name.should == 'id'
    id.type.should == 'int4'
    id.default.should == "nextval('test_table_id_seq'::regclass)"

    body.should be_an_instance_of PGExaminer::Result::Column
    body.name.should == 'body'
    body.type.should == 'text'
    body.default.should == nil
  end

  it "should order tables by name" do
    result = examine <<-SQL
      CREATE TABLE table_a ();
      CREATE TABLE table_b ();
    SQL

    result.should be_an_instance_of PGExaminer::Result
    result.schemas.length.should == 1

    schema = result.schemas.first
    schema.should be_an_instance_of PGExaminer::Result::Schema
    schema.name.should == 'public'
    schema.tables.length.should == 2
    schema.tables.map(&:name).should == %w(table_a table_b)
  end

  it "should consider equivalent tables equivalent" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        id serial,
        body text
      )
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        id serial,
        body text
      )
    SQL

    a.should == b
  end

  it "should consider differently-named tables non-equivalent" do
    a = examine <<-SQL
      CREATE TABLE test_table_a (
        id serial,
        body text
      )
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table_b (
        id serial,
        body text
      )
    SQL

    a.should_not == b

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"added"=>["test_table_b"], "removed"=>["test_table_a"]}}}}
  end

  it "should consider tables with current columns in the same order equivalent" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer,
        c integer
      );

      ALTER TABLE test_table DROP COLUMN b;
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        c integer
      );
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD COLUMN c integer;
    SQL

    a.should == b
    a.should == c
    b.should == c
  end

  it "should consider tables with columns in differing orders not equivalent" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer,
        c integer
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        c integer,
        b integer
      )
    SQL

    a.should == b
  end

  it "should consider tables with columns of differing types not equivalent" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a text
      )
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer default 5
      );
    SQL

    a.should_not == b
    a.should_not == c

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"type"=>{"int4"=>"text"}}}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"default"=>{nil=>"5"}}}}}}}}
  end

  it "should consider array types as different from scalar types" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer[]
      )
    SQL

    a.should_not == b

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"array dimensionality"=>{"0"=>"1"}, "type"=>{"int4"=>"_int4"}}}}}}}}
  end

  it "should consider the presence of not-null constraints" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer not null
      )
    SQL

    a.should_not == b

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"column is marked not-null"=>{"f"=>"t"}}}}}}}}
  end

  it "should consider the presence of type-specific data" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a varchar(49)
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a varchar(50)
      )
    SQL

    a.should_not == b

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"datatype information (atttypmod)"=>{"53"=>"54"}}}}}}}}
  end

  it "should consider unlogged and temporary tables as different from permanent tables" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    b = examine <<-SQL
      CREATE UNLOGGED TABLE test_table (
        a integer
      )
    SQL

    c = examine <<-SQL
      CREATE TEMPORARY TABLE test_table (
        a integer
      )
    SQL

    a.should_not == b
    a.should_not == c
    b.should_not == c

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"table type (relpersistence)"=>{"p"=>"u"}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"removed"=>["test_table"]}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"removed"=>["test_table"]}}}}
  end

  it "should consider additional specified options when comparing tables" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      )
      WITH (fillfactor=90);
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      )
      WITH (fillfactor=70);
    SQL

    d = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
      ALTER TABLE test_table SET (fillfactor=70);
    SQL

    a.should_not == b
    a.should_not == c
    b.should_not == c
    c.should == d

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"table options"=>{nil=>"{fillfactor=90}"}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"table options"=>{nil=>"{fillfactor=70}"}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"table options"=>{"{fillfactor=90}"=>"{fillfactor=70}"}}}}}}
  end
end
