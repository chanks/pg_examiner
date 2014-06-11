require 'spec_helper'

describe PGExaminer do
  it "should be able to examine the extensions in the db" do
    result = examine "SELECT 1"
    result.should be_an_instance_of PGExaminer::Result
    result.extensions.map(&:name).should == ['plpgsql']

    result = examine <<-SQL
      CREATE EXTENSION citext;
    SQL

    result.extensions.length.should == 2

    citext, plpgsql = result.extensions # Ordered by name

    citext.should be_an_instance_of PGExaminer::Result::Extension
    citext.name.should == 'citext'
    citext.schema.should be_an_instance_of PGExaminer::Result::Schema
    citext.schema.name.should == 'public'

    plpgsql.should be_an_instance_of PGExaminer::Result::Extension
    plpgsql.name.should == 'plpgsql'
    plpgsql.schema.should be nil
  end
end
