# PGExaminer

A tool for comparing PG database structures. Use it to ensure that downward migrations precisely undo upward ones, or that different sets of migrations produce the same schema, or that different schemas in a multitenanted database all have the same structure.

PGExaminer tries to be sensible about equivalency. For example, it will understand that two tables are equivalent if they have the same name, column names/types, triggers, constraints, and indices. It won't care about the contents of the tables, or the order in which the columns were declared.

PGExaminer is NOT exhaustive. It currently doesn't have tests for its understanding of:

* Aggregate functions.
* Column TOAST settings.
* Sequences.
* Views.
* User-defined types or enums.
* Object COMMENTs.
* Materialized views.
* Exclusion constraints.
* Inheritance structures.
* User-defined objects in the system (pg_*) schemas or information_schema.
* ...Probably some other stuff.

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
  # Need a PG::Connection object. See your ORM's documentation for how to get one.

  # To make sure migrations work right:
  state1 = PGExaminer.examine(connection)
  # Migrate up then down.
  state2 = PGExaminer.examine(connection)
  state1 == state2 # => true or false

  # To make sure schema1 and schema2 have the same contents:
  state1 = PGExaminer.examine(connection, :schema1)
  state2 = PGExaminer.examine(connection, :schema2)
  state1 == state2 # => true or false
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pg_examiner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
