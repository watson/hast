module HAST
  class Postfix
    attr_reader :domains

    def initialize(config)
      @config = config
      @domains = []

      case @config['postfix']['method']
      when 'file'
        vhost_file
      when 'database'
        mysql
      when nil
        raise "ERROR: Postfix method not specified!"
      else
        raise "ERROR: Unknown Postfix method '#{@config['postfix']['method']}'"
      end
    end

    private

    def vhost_file
      File.open(@config['postfix']['vhost_file']) do |f|
        @domains = f.readlines.compact.map{ |line| line.chomp }.reject{ |line| line.empty? }
      end
    end

    def mysql
      require 'mysql'

      dbh = Mysql.real_connect(@config['postfix']['database']['host'],
                               @config['postfix']['database']['user'],
                               @config['postfix']['database']['password'],
                               @config['postfix']['database']['database'])

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
