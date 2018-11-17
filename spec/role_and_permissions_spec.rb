# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should be able to tell when roles have different permissions on tables" do
    a = examine <<-SQL
      CREATE ROLE user_1;

      CREATE TABLE test_table (
        id integer
      );

      GRANT SELECT ON test_table TO user_1;
    SQL

    b = examine <<-SQL
      CREATE ROLE user_1;

      CREATE TABLE test_table (
        id integer
      );

      GRANT SELECT, UPDATE ON test_table TO user_1;
    SQL

    a.diff(b).should == {"schemas"=>{"public"=>{"tables"=>{"test_table"=>{"permissions"=>{"user_1"=>{"permissions"=>{["SELECT"]=>["SELECT", "UPDATE"]}}}}}}}}
  end

  it "should ignore inconsequential differences in permissions" do
    a = examine <<-SQL
      CREATE ROLE user_1;

      CREATE TABLE test_table (
        id integer
      );

      GRANT UPDATE, SELECT ON test_table TO user_1;
    SQL

    b = examine <<-SQL
      CREATE ROLE user_1;

      CREATE TABLE test_table (
        id integer
      );

      GRANT SELECT, UPDATE ON test_table TO user_1;
    SQL

    a.diff(b).should == {}
  end
end
