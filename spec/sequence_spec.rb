# frozen_string_literal: true

require 'spec_helper'

describe PGExaminer do
  it "should be able to tell when a sequence exists" do
    a = examine "SELECT 1" # No-op.

    b = examine <<-SQL
      CREATE SEQUENCE my_sequence;
    SQL

    c = examine <<-SQL
      CREATE SEQUENCE my_other_sequence;
    SQL

    a.diff(b).should == {"schemas"=>{"public"=>{"sequences"=>{"added"=>["my_sequence"]}}}}
    a.diff(c).should == {"schemas"=>{"public"=>{"sequences"=>{"added"=>["my_other_sequence"]}}}}
    b.diff(c).should == {"schemas"=>{"public"=>{"sequences"=>{"added"=>["my_other_sequence"], "removed"=>["my_sequence"]}}}}
  end

  it "should be able to tell when a table is associated with an index" do
    a = examine <<-SQL
      CREATE TABLE test_table (
        id serial
      )
    SQL

    b = examine <<-SQL
      CREATE SEQUENCE test_table_id_seq;

      CREATE TABLE test_table (
        id integer NOT NULL default nextval('test_table_id_seq')
      )
    SQL

    a.diff(b).should == {}

    # TODO: Add concept of the column owning the sequence?
  end
end
