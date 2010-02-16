require 'mysql'

module HAST
  class Postfix
    attr_reader :domains

    def initialize(config)
      @config = config
      @domains = []

      dbh = Mysql.real_connect(@config['postfix']['mysql']['host'],
                               @config['postfix']['mysql']['user'],
                               @config['postfix']['mysql']['password'],
                               @config['postfix']['mysql']['database'])

      results = dbh.query('SELECT domain FROM domain')
      results.each do |row|
        next if row[0] == 'ALL'
        @domains << row[0]
      end
    rescue Mysql::Error => e
      puts "Error code: #{e.errno}"
      puts "Error message: #{e.error}"
      puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
    ensure
      dbh.close if dbh
    end
  end
end
