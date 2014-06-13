# PGExaminer

A tool for comparing PG database structures. Use it to ensure that downward migrations precisely undo upward ones, or that different sets of migrations produce the same schema, or that different schemas in a multitenanted database all have the same structure.

PGExaminer tries to be sensible about equivalency. For example, it will understand that two tables are equivalent if they have the same name, column names, column types, triggers, constraints, and indices. It won't care about the contents of the tables. It will care about the order the columns are in, but will ignore columns that have been dropped.

PGExaminer is NOT exhaustive. It currently doesn't have tests for its understanding of:

1. Aggregate functions
2. Column TOAST settings
3. Sequences
4. Views
5. User-defined types or enums
6. Object COMMENTs
7. Materialized views
8. Constraint deferral states
9. Exclusion constraints
10. Inheritance structures
11. User-defined objects in the system (pg_*) schemas or information_schema.
12. ...Probably some other stuff.

It may or may not understand these objects. If you're using one of these, or another Postgres feature that may be considered obscure, please test it out first. I'll be happy to add support for more objects if there's demand.

## Installation

Add this line to your application's Gemfile:

    gem 'pg_examiner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pg_examiner

## Usage

``` ruby
  # Need PG::Connection objects.
  state1 = PGExaminer.examine(connection1)
  state2 = PGExaminer.examine(connection2)
  state1 == state2 # => true or false
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pg_examiner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
