require 'spec_helper'

describe PGExaminer do
  it "should be able to examine the extensions in the db" do
    result = PGExaminer.examine(CONNECTION)
    result.should be_an_instance_of PGExaminer::Result
    result.extensions.map(&:name).should == ['plpgsql']

    execute <<-SQL
      CREATE EXTENSION citext;
    SQL

    result = PGExaminer.examine(CONNECTION)
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
