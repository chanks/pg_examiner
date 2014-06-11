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

    two = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE a > 0;
    SQL

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

    two = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(LOWER(a));
    SQL

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
end
