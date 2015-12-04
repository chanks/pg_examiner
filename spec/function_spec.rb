require 'spec_helper'

describe PGExaminer do
  it "should be able to differentiate between functions by their names" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    c = examine <<-SQL_FUNCTION
      CREATE FUNCTION add_numbers(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    a.should == b
    a.should_not == c
    b.should_not == c

    a.diff(c).should == {:schemas=>{"public"=>{:functions=>{:added=>["add_numbers"], :removed=>["add"]}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:functions=>{:added=>["add_numbers"], :removed=>["add"]}}}}
  end

  it "should be able to differentiate between functions by their argument types" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer, three integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    c = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer, three integer[]) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    d = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer, VARIADIC three integer[]) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    a.should_not == b
    a.should_not == c
    a.should_not == d
    b.should_not == c
    b.should_not == d
    c.should_not == d

    a.diff(b).should == {:schemas=>{"public"=>{:functions=>{"add"=>{:definition=>{"CREATE OR REPLACE FUNCTION public.add(one integer, two integer)\n RETURNS integer\n LANGUAGE sql\nAS $function$\n        SELECT one + two\n      $function$\n"=>"CREATE OR REPLACE FUNCTION public.add(one integer, two integer, three integer)\n RETURNS integer\n LANGUAGE sql\nAS $function$\n        SELECT one + two\n      $function$\n"}, :argument_types=>{["int4", "int4"]=>["int4", "int4", "int4"]}}}}}}
    a.diff(c).should == {:schemas=>{"public"=>{:functions=>{"add"=>{:definition=>{"CREATE OR REPLACE FUNCTION public.add(one integer, two integer)\n RETURNS integer\n LANGUAGE sql\nAS $function$\n        SELECT one + two\n      $function$\n"=>"CREATE OR REPLACE FUNCTION public.add(one integer, two integer, three integer[])\n RETURNS integer\n LANGUAGE sql\nAS $function$\n        SELECT one + two\n      $function$\n"}, :argument_types=>{["int4", "int4"]=>["int4", "int4", "_int4"]}}}}}}
  end

  it "should be able to differentiate between functions by their argument defaults" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer DEFAULT 42) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    a.should_not == b
  end

  it "should be able to differentiate between functions by their return types" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT (one + two)::integer
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS bigint
      AS $$
        SELECT (one + two)::bigint
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    c = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS smallint
      AS $$
        SELECT (one + two)::smallint
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    a.should_not == b
    a.should_not == c
    b.should_not == c
  end

  it "should be able to differentiate between functions by their languages" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        BEGIN
          RETURN one + two;
        END
      $$
      LANGUAGE PLPGSQL;
    SQL_FUNCTION

    a.should_not == b

    a.diff(b)[:schemas]['public'][:functions]['add'][:language].should == {'sql' => 'plpgsql'}
  end

  it "should be able to differentiate between functions by their other flags" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL
      COST 0.1;
    SQL_FUNCTION

    c = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL
      RETURNS NULL ON NULL INPUT;
    SQL_FUNCTION

    d = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL
      STRICT;
    SQL_FUNCTION

    a.should_not == b
    a.should_not == c
    a.should_not == d
  end

  it "should be able to differentiate between functions by their definitions" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT two + one
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    a.should_not == b
  end

  it "should be able to differentiate between functions by their volatility" do
    a = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL_FUNCTION

    b = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL
      VOLATILE;
    SQL_FUNCTION

    c = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL
      STABLE;
    SQL_FUNCTION

    d = examine <<-SQL_FUNCTION
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL
      IMMUTABLE;
    SQL_FUNCTION

    a.should == b
    a.should_not == c
    a.should_not == d
  end

  it "should be able to differentiate between triggers by their names" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig2 BEFORE INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c

    a.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:triggers=>{:added=>["trig2"], :removed=>["trig"]}}}}}}
    b.diff(c).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:triggers=>{:added=>["trig2"], :removed=>["trig"]}}}}}}
  end

  it "should be able to differentiate between triggers by their parent tables" do
    a = examine <<-SQL
      CREATE TABLE test_table_a (
        a integer
      );

      CREATE TABLE test_table_b (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table_a FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table_a (
        a integer
      );

      CREATE TABLE test_table_b (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table_b FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    a.should_not == b

    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table_a"=>{:triggers=>{:removed=>["trig"]}}, "test_table_b"=>{:triggers=>{:added=>["trig"]}}}}}}
  end

  it "should be able to differentiate between triggers by their associated functions" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func1() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE FUNCTION func2() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func1();
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func1() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE FUNCTION func2() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func2();
    SQL

    a.should_not == b

    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:triggers=>{"trig"=>{:function=>{"func1"=>"func2"}}}}}}}}
  end

  it "should be able to differentiate between triggers by their firing conditions" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    b = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE UPDATE ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    c = examine <<-SQL
      CREATE TABLE test_table (
        a integer
      );

      CREATE FUNCTION func() RETURNS trigger AS $$
        BEGIN
          NEW.a = 56;
          RETURN NEW;
        END;
      $$
      LANGUAGE plpgsql;

      CREATE TRIGGER trig BEFORE DELETE ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    a.should_not == b
    a.should_not == c
    b.should_not == c

    a.diff(b).should == {:schemas=>{"public"=>{:tables=>{"test_table"=>{:triggers=>{"trig"=>{:tgtype=>{"7"=>"19"}}}}}}}}
  end
end
