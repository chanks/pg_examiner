require 'spec_helper'

describe PGExaminer do
  it "should be able to differentiate functions by their names" do
    a = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer) RETURNS integer 
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    b = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer) RETURNS integer 
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    c = examine <<-SQL
      CREATE FUNCTION add_numbers(one integer, two integer) RETURNS integer 
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    a.should == b
    a.should_not == c
    b.should_not == c
  end

  it "should be able to differentiate functions by their argument types" do
    a = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    b = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer, three integer) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    c = examine <<-SQL
      CREATE FUNCTION add_numbers(one integer, two integer, VARIADIC integers integer[]) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    a.should_not == b
    a.should_not == c
  end

  it "should be able to differentiate functions by their return types"

  it "should be able to differentiate functions by their languages"

  it "should be able to differentiate functions by their other flags"

  it "should be able to differentiate functions by their contents"

  it "should be able differentiate functions by their volatility"

  it "should be able to differentiate triggers by their names"

  it "should be able to differentiate triggers by their parent tables"

  it "should be able to differentiate triggers by their associated functions"

  it "should be able to differentiate triggers by their firing conditions"
end
