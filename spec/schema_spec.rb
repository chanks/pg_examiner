# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should be able to examine the public schema" do
    result = examine("SELECT 1")
    result.should be_an_instance_of PGExaminer::Result

    result.schemas.length.should == 1
    schema = result.schemas.first
    schema.should be_an_instance_of PGExaminer::Result::Schema
    schema.name.should == 'public'
    schema.tables.should == []

    other_result = examine("SELECT 1")
    result.should == other_result
    result.diff(other_result).should == {}
  end

  it "should detect other user-added schemas" do
    result = examine <<-SQL
      CREATE SCHEMA my_schema;
    SQL

    result.schemas.length.should == 2
    result.schemas.map(&:name).should == %w(my_schema public)
  end

  it "should consider differently-named schemas non-equivalent" do
    a = examine <<-SQL
      CREATE SCHEMA test_schema_a;
    SQL

    b = examine <<-SQL
      CREATE SCHEMA test_schema_b;
    SQL

    c = examine <<-SQL
      SELECT 1;
    SQL

    a.should == a
    a.should_not == b
    a.should_not == c
    b.should_not == a
    b.should == b
    b.should_not == c
    c.should_not == a
    c.should_not == b
    c.should == c

    a.diff(a).should == {}
    a.diff(b).should == {"schemas" => {"added" => ['test_schema_b'], "removed" => ['test_schema_a']}}
    a.diff(c).should == {"schemas" => {"removed" => ['test_schema_a']}}
    b.diff(a).should == {"schemas" => {"added" => ['test_schema_a'], "removed" => ['test_schema_b']}}
    b.diff(b).should == {}
    b.diff(c).should == {"schemas" => {"removed" => ['test_schema_b']}}
    c.diff(a).should == {"schemas" => {"added" => ['test_schema_a']}}
    c.diff(b).should == {"schemas" => {"added" => ['test_schema_b']}}
    c.diff(c).should == {}
  end

  it "should be able to compare the contents of different schemas" do
    a = examine <<-SQL, "schema1"
      CREATE SCHEMA schema1;
      CREATE TABLE schema1.test_table (
        a integer,
        b integer
      );
    SQL

    b = examine <<-SQL, "schema2"
      CREATE SCHEMA schema2;
      CREATE TABLE schema2.test_table (
        a integer,
        b integer
      );
    SQL

    c = examine <<-SQL, "schema2"
      CREATE SCHEMA schema2;
      CREATE TABLE schema2.test_table_2 (
        a integer,
        b integer
      );
    SQL

    d = examine <<-SQL, "schema2"
      CREATE SCHEMA schema2;
    SQL

    a.should == b
    a.diff(b).should == {}
    b.diff(a).should == {}

    a.should_not == c
    a.diff(c).should == {"tables" => {"added" => ['test_table_2'], "removed" => ['test_table']}}
    a.diff(d).should == {"tables" => {"removed" => ['test_table']}}
  end
end
