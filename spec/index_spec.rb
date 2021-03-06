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

    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"added"=>["int_idx2"], "removed"=>["int_idx"]}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"added"=>["int_idx2"], "removed"=>["int_idx"]}}}}}}
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

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"int_idx"=>{"expression"=>{["a"]=>["b"]}}}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"int_idx"=>{"expression"=>{["a"]=>["a", "b"]}}}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"int_idx"=>{"expression"=>{["b"]=>["a", "b"]}}}}}}}}
  end

  it "should consider the filters indexes have when determining equivalency" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE b > 0;
    SQL

    a.schemas.first.tables.first.indexes.first.row['filter'].should == '(b > 0)'

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a) WHERE b > 0;
    SQL

    b.schemas.first.tables.first.indexes.first.row['filter'].should == '(b > 0)'

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        b integer
      );

      CREATE INDEX int_idx ON test_table(a);
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c

    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"int_idx"=>{"filter expression"=>{"(b > 0)"=>nil}}}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"int_idx"=>{"filter expression"=>{"(b > 0)"=>nil}}}}}}}}
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

    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"text_idx"=>{"expression"=>{"lower(a)"=>["a"]}}}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"text_idx"=>{"expression"=>{"lower(a)"=>["a"]}}}}}}}}
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

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"indexes"=>{"int_idx"=>{"index is unique"=>{"f"=>"t"}}}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"column is marked not-null"=>{"f"=>"t"}}}, "indexes"=>{"added"=>["test_table_pkey"], "removed"=>["int_idx"]}, "constraints"=>{"added"=>["test_table_pkey"]}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"columns"=>{"a"=>{"column is marked not-null"=>{"f"=>"t"}}}, "indexes"=>{"added"=>["test_table_pkey"], "removed"=>["int_idx"]}, "constraints"=>{"added"=>["test_table_pkey"]}}}}}}
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

    a.diff(d).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"removed"=>["test_table_a_key"]}}}}}}
  end

  it "should recognize the difference between unique indices with different deferrable states" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a);
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) NOT DEFERRABLE;
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) DEFERRABLE;
    SQL

    d = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) DEFERRABLE INITIALLY IMMEDIATE;
    SQL

    e = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) DEFERRABLE INITIALLY DEFERRED;
    SQL

    c2 = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) DEFERRABLE;
    SQL

    d2 = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) DEFERRABLE INITIALLY IMMEDIATE;
    SQL

    e2 = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT test_table_a_key UNIQUE (a) DEFERRABLE INITIALLY DEFERRED;
    SQL

    a.should     == b
    a.should_not == c
    a.should_not == d
    c.should     == d
    c.should_not == e
    d.should_not == e

    c.should == c2
    d.should == d2
    e.should == e2

    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"test_table_a_key"=>{"constraint is deferrable"=>{"f"=>"t"}}}}}}}}
    a.diff(d).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"test_table_a_key"=>{"constraint is deferrable"=>{"f"=>"t"}}}}}}}}
    c.diff(e).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"test_table_a_key"=>{"constraint is initially deferred"=>{"f"=>"t"}}}}}}}}
    d.diff(e).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"test_table_a_key"=>{"constraint is initially deferred"=>{"f"=>"t"}}}}}}}}
  end
end
