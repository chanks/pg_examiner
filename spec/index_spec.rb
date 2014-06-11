require 'spec_helper'

describe PGExaminer do
  it "should consider indexes when determining equivalency" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx ON test_table(id);
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx ON test_table(id);
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx2 ON test_table(id);
    SQL

    one.should == two
    one.should_not == three
    two.should_not == three
  end

  it "should consider the columns indexes are on when determining equivalency" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(b);
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a, b);
    SQL

    one.should_not == two
    one.should_not == three
    two.should_not == three
  end

  it "should consider the filters indexes have when determining equivalency" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE a > 0;
    SQL

    one.schemas.first.tables.first.indexes.first.row['filter'].should == '(a > 0)'

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE a > 0;
    SQL

    two.schemas.first.tables.first.indexes.first.row['filter'].should == '(a > 0)'

    three = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    one.should == two
    one.should_not == three
    two.should_not == three
  end

  it "should consider the expressions indexes are on, if any" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(lower(a));
    SQL

    one.schemas.first.tables.first.indexes.first.expression.should == 'lower(a)'

    two = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(LOWER(a));
    SQL

    two.schemas.first.tables.first.indexes.first.expression.should == 'lower(a)'

    three = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(a);
    SQL

    one.should == two
    one.should_not == three
    two.should_not == three
  end

  it "should consider the uniqueness and primary key status of an index, if any" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE UNIQUE INDEX int_idx ON test_table(a);
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD PRIMARY KEY (a);
    SQL

    one.should_not == two
    one.should_not == three
    two.should_not == three
  end
end
