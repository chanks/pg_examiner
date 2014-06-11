require 'spec_helper'

describe PGExaminer do
  it "should be able to tell when a table exists" do
    result = examine <<-SQL
      CREATE TABLE test_table (
        id serial,
        body text
      )
    SQL

    result.should be_an_instance_of PGExaminer::Result
    result.schemas.length.should == 1

    schema = result.schemas.first
    schema.should be_an_instance_of PGExaminer::Result::Schema
    schema.name.should == 'public'
    schema.tables.length.should == 1

    table = schema.tables.first
    table.should be_an_instance_of PGExaminer::Result::Table
    table.columns.length.should == 2

    id, body = table.columns # Returned in proper ordering

    id.should be_an_instance_of PGExaminer::Result::Column
    id.name.should == 'id'
    id.type.should == 'int4'
    id.default.should == "nextval('test_table_id_seq'::regclass)"

    body.should be_an_instance_of PGExaminer::Result::Column
    body.name.should == 'body'
    body.type.should == 'text'
    body.default.should == nil
  end

  it "should order tables by name" do
    result = examine <<-SQL
      CREATE TABLE table_a ();
      CREATE TABLE table_b ();
    SQL

    result.should be_an_instance_of PGExaminer::Result
    result.schemas.length.should == 1

    schema = result.schemas.first
    schema.should be_an_instance_of PGExaminer::Result::Schema
    schema.name.should == 'public'
    schema.tables.length.should == 2
    schema.tables.map(&:name).should == %w(table_a table_b)
  end
end
