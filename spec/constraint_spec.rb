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

  it "should consider foreign keys when differentiating between schemas" do
    a = examine <<-SQL
      CREATE TABLE parent (
        int1 integer PRIMARY KEY,
        int2 integer UNIQUE
      );

      CREATE TABLE child (
        parent_id integer REFERENCES parent
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE parent (
        int1 integer PRIMARY KEY,
        int2 integer UNIQUE
      );

      CREATE TABLE child (
        parent_id integer,
        FOREIGN KEY (parent_id) REFERENCES parent
      );
    SQL

    c = examine <<-SQL
      CREATE TABLE parent (
        int1 integer PRIMARY KEY,
        int2 integer UNIQUE
      );

      CREATE TABLE child (
        parent_id integer,
        FOREIGN KEY (parent_id) REFERENCES parent (int2)
      );
    SQL

    d = examine <<-SQL
      CREATE TABLE parent (
        int1 integer PRIMARY KEY,
        int2 integer UNIQUE
      );

      CREATE TABLE child (
        parent_id integer,
        FOREIGN KEY (parent_id) REFERENCES parent ON UPDATE CASCADE
      );
    SQL

    e = examine <<-SQL
      CREATE TABLE parent (
        int1 integer PRIMARY KEY,
        int2 integer UNIQUE
      );

      CREATE TABLE child (
        parent_id integer,
        FOREIGN KEY (parent_id) REFERENCES parent ON DELETE CASCADE
      );
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c
    b.should_not == d
    b.should_not == e
    d.should_not == e
  end

  it "should consider constraints when determining table equivalency" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        CONSTRAINT con CHECK (a > 0) NOT VALID
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        CONSTRAINT con CHECK (a > 0)
      );
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        CONSTRAINT con CHECK (a > 0) NOT VALID
      );

      ALTER TABLE test_table VALIDATE CONSTRAINT con;
    SQL

    a.should_not == b
    a.should_not == c
    b.should == c
  end
end
