# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
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

    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"triggers"=>{"added"=>["trig2"], "removed"=>["trig"]}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"triggers"=>{"added"=>["trig2"], "removed"=>["trig"]}}}}}}
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

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table_a"=>{"triggers"=>{"removed"=>["trig"]}}, "test_table_b"=>{"triggers"=>{"added"=>["trig"]}}}}}}
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

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"triggers"=>{"trig"=>{"function"=>{"func1"=>"func2"}}}}}}}}
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

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"triggers"=>{"trig"=>{"trigger firing conditions (tgtype)"=>{"7"=>"19"}}}}}}}}
  end

  it "should be able to differentiate between normal triggers and constraint triggers" do
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

      CREATE TRIGGER trig AFTER INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
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

      CREATE CONSTRAINT TRIGGER trig AFTER INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    a.should_not == b

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"added"=>["trig"]}}}}}}
  end

  it "should be able to differentiate between deferrable and non-deferrable constraint triggers" do
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

      CREATE CONSTRAINT TRIGGER trig AFTER INSERT ON test_table FOR EACH ROW EXECUTE PROCEDURE func();
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

      CREATE CONSTRAINT TRIGGER trig AFTER INSERT ON test_table DEFERRABLE FOR EACH ROW EXECUTE PROCEDURE func();
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

      CREATE CONSTRAINT TRIGGER trig AFTER INSERT ON test_table DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE func();
    SQL

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"trig"=>{"constraint definition"=>{"TRIGGER"=>"TRIGGER DEFERRABLE"}}}}}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"trig"=>{"constraint definition"=>{"TRIGGER"=>"TRIGGER DEFERRABLE INITIALLY DEFERRED"}}}}}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"constraints"=>{"trig"=>{"constraint definition"=>{"TRIGGER DEFERRABLE"=>"TRIGGER DEFERRABLE INITIALLY DEFERRED"}}}}}}}}
  end
end
