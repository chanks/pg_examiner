# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should consider indexes when determining equivalency" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx ON test_table(id);
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx ON test_table(id);
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx2 ON test_table(id);
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c

    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{:added=>["int_idx2"], :removed=>["int_idx"]}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{:added=>["int_idx2"], :removed=>["int_idx"]}}}}}}
  end

  it "should consider the columns indexes are on when determining equivalency" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(b);
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a, b);
    SQL

    a.should_not == b
    a.should_not == c
    b.should_not == c

    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"int_idx"=>{:expression=>{["a"]=>["b"]}}}}}}}}
    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"int_idx"=>{:expression=>{["a"]=>["a", "b"]}}}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"int_idx"=>{:expression=>{["b"]=>["a", "b"]}}}}}}}}
  end

  it "should consider the filters indexes have when determining equivalency" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE a > 0;
    SQL

    a.schemas.first.tables.first.indexes.first.row['filter'].should == '(a > 0)'

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE a > 0;
    SQL

    b.schemas.first.tables.first.indexes.first.row['filter'].should == '(a > 0)'

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c

    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"int_idx"=>{:filter=>{"(a > 0)"=>nil}}}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"int_idx"=>{:filter=>{"(a > 0)"=>nil}}}}}}}}
  end

  it "should consider the expressions indexes are on, if any" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(lower(a));
    SQL

    a.schemas.first.tables.first.indexes.first.expression.should == 'lower(a)'

    b = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(LOWER(a));
    SQL

    b.schemas.first.tables.first.indexes.first.expression.should == 'lower(a)'

    c = examine <<-SQL
      CREATE TABLE test_table (
        a text
      );

      CREATE INDEX text_idx ON test_table(a);
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c

    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"text_idx"=>{:expression=>{"lower(a)"=>["a"]}}}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"text_idx"=>{:expression=>{"lower(a)"=>["a"]}}}}}}}}
  end

  it "should consider the uniqueness and primary key status of an index, if any" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE UNIQUE INDEX int_idx ON test_table(a);
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD PRIMARY KEY (a);
    SQL

    a.should_not == b
    a.should_not == c
    b.should_not == c

    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:indexes=>{"int_idx"=>{:indisunique=>{"f"=>"t"}}}}}}}}
    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:columns=>{"a"=>{:attnotnull=>{"f"=>"t"}}}, :indexes=>{:added=>["test_table_pkey"], :removed=>["int_idx"]}, :constraints=>{:added=>["test_table_pkey"]}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:columns=>{"a"=>{:attnotnull=>{"f"=>"t"}}}, :indexes=>{:added=>["test_table_pkey"], :removed=>["int_idx"]}, :constraints=>{:added=>["test_table_pkey"]}}}}}}
  end

  it "should recognize the difference between a unique index and a unique constraint" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        UNIQUE (a)
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer UNIQUE
      );
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a);
    SQL

    d = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE UNIQUE INDEX test_table_a_key ON test_table (a);
    SQL

    a.should == b
    a.should == c
    a.should_not == d

    a.diff(d).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{:removed=>["test_table_a_key"]}}}}}}
  end
end
