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
  end

  it "should detect other user-added schemas" do
    result = examine <<-SQL
      CREATE SCHEMA my_schema;
    SQL

    result.schemas.length.should == 2
    result.schemas.map(&:name).should == %w(public my_schema)
  end
end
