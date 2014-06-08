require 'spec_helper'

describe PGExaminer do
  it "should be able to examine the public schema" do
    result = PGExaminer.examine(CONNECTION)
    result.should be_an_instance_of PGExaminer::Result

    result.schemas.length.should == 1
    schema = result.schemas.first
    schema.should be_an_instance_of PGExaminer::Result::Schema
    schema.name.should == 'public'
    schema.tables.should == []
  end
end
