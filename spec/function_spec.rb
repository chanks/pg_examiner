require 'spec_helper'

describe PGExaminer do
  it "should be able to differentiate between functions by their names" do
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

  it "should be able to differentiate between functions by their argument types" do
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
      CREATE FUNCTION add(one integer, two integer, three integer[]) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    d = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer, VARIADIC three integer[]) RETURNS integer
      AS $$
        SELECT one + two
      $$
      LANGUAGE SQL;
    SQL

    a.should_not == b
    a.should_not == c
    a.should_not == d
    b.should_not == c
    b.should_not == d
    c.should_not == d
  end

  it "should be able to differentiate between functions by their return types" do
    a = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer) RETURNS integer
      AS $$
        SELECT (one + two)::integer
      $$
      LANGUAGE SQL;
    SQL

    b = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer) RETURNS bigint
      AS $$
        SELECT (one + two)::bigint
      $$
      LANGUAGE SQL;
    SQL

    c = examine <<-SQL
      CREATE FUNCTION add(one integer, two integer) RETURNS smallint
      AS $$
        SELECT (one + two)::smallint
      $$
      LANGUAGE SQL;
    SQL

    a.should_not == b
    a.should_not == c
    b.should_not == c
  end

  it "should be able to differentiate between functions by their languages"

  it "should be able to differentiate between functions by their other flags"

  it "should be able to differentiate between functions by their contents"

  it "should be able differentiate between functions by their volatility"

  it "should be able to differentiate between triggers by their names"

  it "should be able to differentiate between triggers by their parent tables"

  it "should be able to differentiate between triggers by their associated functions"

  it "should be able to differentiate between triggers by their firing conditions"
end
