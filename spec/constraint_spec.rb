# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should consider check constraints when determining table equivalency" do
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

    g = examine <<-SQL
      CREATE TABLE test_table (
        a integer,
        CONSTRAINT con CHECK (a < 0)
      );
    SQL

    a.diff(b).should be_empty
    a.diff(c).should be_empty
    b.diff(c).should be_empty

    a.diff(d).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"added"=>["con_two"], "removed"=>["con"]}}}}}}
    a.diff(e).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"added"=>["test_table_a_check"], "removed"=>["con"]}}}}}}
    a.diff(f).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"removed"=>["con"]}}}}}}
    a.diff(g).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"con"=>{"check constraint definition"=>{"(a > 0)"=>"(a < 0)"}}}}}}}}
    e.diff(f).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"removed"=>["test_table_a_check"]}}}}}}
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
    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table_1"=>{"constraints"=>{"removed"=>["con"]}}, "test_table_2"=>{"constraints"=>{"added"=>["con"]}}}}}}
  end

  it "should consider constraint validation when determining table equivalency" do
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

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"con"=>{"constraint is validated"=>{"f"=>"t"}}}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"con"=>{"constraint is validated"=>{"f"=>"t"}}}}}}}}
  end

  describe "when considering foreign keys" do
    it "should consider their presence" do
      a = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer
        );
      SQL

      b = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer REFERENCES parent
        );
      SQL

      a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"added"=>["child_parent_id_fkey"]}}}}}}
    end

    it "should consider the remote columns of foreign keys when differentiating between schemas" do
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
          FOREIGN KEY (parent_id) REFERENCES parent (int1)
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

      a.should == b
      a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"index"=>{"parent_pkey"=>"parent_int2_key"}, "foreign constrained columns"=>{["int1"]=>["int2"]}}}}}}}}
      b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"index"=>{"parent_pkey"=>"parent_int2_key"}, "foreign constrained columns"=>{["int1"]=>["int2"]}}}}}}}}
    end

    it "should consider the local columns of the foreign keys" do
      a = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id1 integer,
          parent_id2 integer,
          CONSTRAINT fkey FOREIGN KEY (parent_id1) REFERENCES parent
        );
      SQL

      b = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id1 integer,
          parent_id2 integer,
          CONSTRAINT fkey FOREIGN KEY (parent_id2) REFERENCES parent
        );
      SQL

      a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"fkey"=>{"local constrained columns"=>{["parent_id1"]=>["parent_id2"]}}}}}}}}
    end

    it "should consider on update/delete actions" do
      a = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer,
          FOREIGN KEY (parent_id) REFERENCES parent
        );
      SQL

      b = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer,
          FOREIGN KEY (parent_id) REFERENCES parent ON UPDATE CASCADE
        );
      SQL

      c = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer,
          FOREIGN KEY (parent_id) REFERENCES parent ON DELETE CASCADE
        );
      SQL

      a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"foreign key on update action"=>{"no action"=>"cascade"}}}}}}}}
      a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"foreign key on delete action"=>{"no action"=>"cascade"}}}}}}}}
      b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"foreign key on update action"=>{"cascade"=>"no action"}, "foreign key on delete action"=>{"no action"=>"cascade"}}}}}}}}
    end

    it "should consider match simple/full" do
      a = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer,
          FOREIGN KEY (parent_id) REFERENCES parent
        );
      SQL

      b = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer,
          FOREIGN KEY (parent_id) REFERENCES parent MATCH SIMPLE
        );
      SQL

      c = examine <<-SQL
        CREATE TABLE parent (
          int1 integer PRIMARY KEY
        );

        CREATE TABLE child (
          parent_id integer,
          FOREIGN KEY (parent_id) REFERENCES parent MATCH FULL
        );
      SQL

      a.diff(b).should == {}
      a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"foreign key match type"=>{"simple"=>"full"}}}}}}}}
      b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"foreign key match type"=>{"simple"=>"full"}}}}}}}}
    end

    describe "when comparing two schemas" do
      it "should understand that tables will point to tables in their own schema" do
        a = examine <<-SQL, "schema1"
          CREATE SCHEMA schema1;
          CREATE TABLE schema1.parent (int1 integer PRIMARY KEY);
          CREATE TABLE schema1.child (parent_id integer REFERENCES schema1.parent);
        SQL

        b = examine <<-SQL, "schema2"
          CREATE SCHEMA schema2;
          CREATE TABLE schema2.parent (int1 integer PRIMARY KEY);
          CREATE TABLE schema2.child (parent_id integer REFERENCES schema2.parent);
        SQL

        c = examine <<-SQL, "schema2"
          CREATE SCHEMA schema1;
          CREATE TABLE schema1.parent (int1 integer PRIMARY KEY);

          CREATE SCHEMA schema2;
          CREATE TABLE schema2.parent (int1 integer PRIMARY KEY);
          CREATE TABLE schema2.child (parent_id integer REFERENCES schema1.parent);
        SQL

        a.should == b
        b.diff(c).should == {"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"table referenced by foreign key"=>{["(same schema)", "parent"]=>["schema1 schema", "parent"]}}}}}}
      end

      it "should understand when tables point to a table in public" do
        a = examine <<-SQL, "schema1"
          CREATE TABLE parent (int1 integer PRIMARY KEY);
          CREATE SCHEMA schema1;
          CREATE TABLE schema1.parent (int1 integer PRIMARY KEY);
          CREATE TABLE schema1.child (parent_id integer REFERENCES parent);
        SQL

        b = examine <<-SQL, "schema2"
          CREATE TABLE parent (int1 integer PRIMARY KEY);
          CREATE SCHEMA schema2;
          CREATE TABLE schema2.parent (int1 integer PRIMARY KEY);
          CREATE TABLE schema2.child (parent_id integer REFERENCES parent);
        SQL

        c = examine <<-SQL, "schema1"
          CREATE TABLE parent (int1 integer PRIMARY KEY);

          CREATE SCHEMA schema1;
          CREATE TABLE schema1.parent (int1 integer PRIMARY KEY);
          CREATE TABLE schema1.child (parent_id integer REFERENCES schema1.parent);
        SQL

        a.should == b
        b.diff(c).should == {"tables"=>{"child"=>{"constraints"=>{"child_parent_id_fkey"=>{"table referenced by foreign key"=>{["public schema", "parent"]=>["(same schema)", "parent"]}}}}}}
      end
    end
  end
end
