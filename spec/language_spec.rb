# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should be able to examine the languages loaded into the db" do
    result = examine("SELECT 1")
    result.should be_an_instance_of PGExaminer::Result
    result.languages.map(&:name).should == %w(c internal plpgsql sql) # Different for other installations?
  end
end
