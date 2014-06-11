require 'spec_helper'

describe PGExaminer do
  it "should consider constraints when determining table equivalency" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        CONSTRAINT con CHECK (a > 0)
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT con CHECK (a     >     0);
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer CONSTRAINT con CHECK (a > 0)
      );
    SQL

    d = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      ALTER TABLE test_table ADD CONSTRAINT con_two CHECK (a > 0);
    SQL

    e = examine <<-SQL
      CREATE TABLE test_table (
        a integer CHECK (a > 0)
      );
    SQL

    f = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );
    SQL

    a.should == b
    a.should == c
    b.should == c
    a.should_not == d
    a.should_not == e
    a.should_not == f
    e.should_not == f
  end
end
