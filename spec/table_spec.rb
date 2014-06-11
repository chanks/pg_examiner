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

    id, body = table.columns # Returned in proper ordering

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
    one = examine <<-SQL
      CREATE TABLE test_table (
        id serial,
        body text
      )
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        id serial,
        body text
      )
    SQL

    one.should == two
  end

  it "should consider differently-named tables non-equivalent" do
    one = examine <<-SQL
      CREATE TABLE test_table_a (
        id serial,
        body text
      )
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table_b (
        id serial,
        body text
      )
    SQL

    one.should_not == two
  end

  it "should consider tables with current columns in the same order equivalent" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer,
        c integer
      );

      ALTER TABLE test_table DROP COLUMN b;
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        c integer
      );
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD COLUMN c integer;
    SQL

    one.should == two
    one.should == three
    two.should == three
  end

  it "should consider tables with columns in differing orders not equivalent" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer,
        c integer
      );
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        c integer,
        b integer
      )
    SQL

    one.should_not == two
  end

  it "should consider tables with columns of differing types not equivalent" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a text
      )
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        a integer default 5
      );
    SQL

    one.should_not == two
    one.should_not == three
  end

  it "should consider array types as different from scalar types" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer[]
      )
    SQL

    one.should_not == two
  end

  it "should consider the presence of not-null constraints" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer not null
      )
    SQL

    one.should_not == two
  end

  it "should consider the presence of type-specific data" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a varchar(49)
      );
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a varchar(50)
      )
    SQL

    one.should_not == two
  end

  it "should consider unlogged and temporary tables as different from permanent tables" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    two = examine <<-SQL
      CREATE UNLOGGED TABLE test_table (
        a integer
      )
    SQL

    three = examine <<-SQL
      CREATE TEMPORARY TABLE test_table (
        a integer
      )
    SQL

    one.should_not == two
    one.should_not == three
    two.should_not == three
  end

  it "should consider additional specified options when comparing tables" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      )
      WITH (fillfactor=90);
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      )
      WITH (fillfactor=70);
    SQL

    four = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
      ALTER TABLE test_table SET (fillfactor=70);
    SQL

    one.should_not == two
    one.should_not == three
    two.should_not == three
    three.should == four
  end
end
