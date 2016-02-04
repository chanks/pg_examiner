# frozen_string_literal: true

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

    a.diff(d).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{:added=>["con_two"], :removed=>["con"]}}}}}}
    a.diff(e).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{:added=>["test_table_a_check"], :removed=>["con"]}}}}}}
    a.diff(f).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{:removed=>["con"]}}}}}}
    e.diff(f).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{:removed=>["test_table_a_check"]}}}}}}
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

    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"child"=>{:constraints=>{"child_parent_id_fkey"=>{:definition=>{"FOREIGN KEY (parent_id) REFERENCES parent(int1)"=>"FOREIGN KEY (parent_id) REFERENCES parent(int2)"}}}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"child"=>{:constraints=>{"child_parent_id_fkey"=>{:definition=>{"FOREIGN KEY (parent_id) REFERENCES parent(int1)"=>"FOREIGN KEY (parent_id) REFERENCES parent(int2)"}}}}}}}}
    b.diff(d).should == {:schemas=>{"public"=>{:tables=>{"child"=>{:constraints=>{"child_parent_id_fkey"=>{:definition=>{"FOREIGN KEY (parent_id) REFERENCES parent(int1)"=>"FOREIGN KEY (parent_id) REFERENCES parent(int1) ON UPDATE CASCADE"}}}}}}}}
    b.diff(e).should == {:schemas=>{"public"=>{:tables=>{"child"=>{:constraints=>{"child_parent_id_fkey"=>{:definition=>{"FOREIGN KEY (parent_id) REFERENCES parent(int1)"=>"FOREIGN KEY (parent_id) REFERENCES parent(int1) ON DELETE CASCADE"}}}}}}}}
    d.diff(e).should == {:schemas=>{"public"=>{:tables=>{"child"=>{:constraints=>{"child_parent_id_fkey"=>{:definition=>{"FOREIGN KEY (parent_id) REFERENCES parent(int1) ON UPDATE CASCADE"=>"FOREIGN KEY (parent_id) REFERENCES parent(int1) ON DELETE CASCADE"}}}}}}}}
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

    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{"con"=>{:definition=>{"CHECK ((a > 0)) NOT VALID"=>"CHECK ((a > 0))"}}}}}}}}
    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:constraints=>{"con"=>{:definition=>{"CHECK ((a > 0)) NOT VALID"=>"CHECK ((a > 0))"}}}}}}}}
  end

  it "should consider the tables each constraint is on" do
    a = examine <<-SQL
      CREATE TABLE test_table_1 (
        a integer,
        CONSTRAINT con CHECK (a > 0)
      );

      CREATE TABLE test_table_2 (
        a integer
      );
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table_1 (
        a integer
      );

      CREATE TABLE test_table_2 (
        a integer,
        CONSTRAINT con CHECK (a > 0)
      );
    SQL

    a.should_not == b
    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table_1"=>{:constraints=>{:removed=>["con"]}}, "test_table_2"=>{:constraints=>{:added=>["con"]}}}}}}
  end
end
