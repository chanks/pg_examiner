# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should be able to examine the extensions in the db" do
    result1 = examine "SELECT 1"
    result1.should be_an_instance_of PGExaminer::Result
    result1.extensions.map(&:name).should == ['plpgsql']

    result2 = examine <<-SQL
      CREATE EXTENSION citext;
    SQL

    result2.extensions.length.should == 2

    citext, plpgsql = result2.extensions # Ordered by name

    citext.should be_an_instance_of PGExaminer::Result::Extension
    citext.name.should == 'citext'
    citext.schema.should be_an_instance_of PGExaminer::Result::Schema
    citext.schema.name.should == 'public'

    plpgsql.should be_an_instance_of PGExaminer::Result::Extension
    plpgsql.name.should == 'plpgsql'
    plpgsql.schema.should be nil

    result1.diff(result2)["extensions"].should == {"added"   => ['citext']}
    result2.diff(result1)["extensions"].should == {"removed" => ['citext']}
  end
end
