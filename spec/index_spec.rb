require 'spec_helper'

describe PGExaminer do
  it "should consider indexes when determining equivalency" do
    one = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx ON test_table(id);
    SQL

    two = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx ON test_table(id);
    SQL

    three = examine <<-SQL
      CREATE TABLE test_table (
        id integer
      );

      CREATE INDEX int_idx2 ON test_table(id);
    SQL

    one.should == two
    one.should_not == three
    two.should_not == three
  end
end
