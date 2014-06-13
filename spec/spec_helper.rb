require 'uri'
require 'pg'
require 'pry'
require 'pg_examiner'

uri = URI.parse(ENV['DATABASE_URL'] || 'postgres://postgres:@localhost/pg_examiner_test')
CONNECTION = PG::Connection.open :host     => uri.host,
                                 :user     => uri.user,
                                 :password => uri.password,
                                 :port     => uri.port || 5432,
                                 :dbname   => uri.path[1..-1]

RSpec.configure do |config|
  def examine(sql, schema = nil)
    execute "BEGIN"
    execute(sql)
    PGExaminer.examine(CONNECTION, schema)
  ensure
    execute "ROLLBACK"
  end

  def execute(*args)
    CONNECTION.async_exec(*args).to_a
  end
end
