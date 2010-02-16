require 'rubygems'
require 'optparse'
require 'yaml'
require 'rdoc/usage'
require 'lib/hast/apache'
require 'lib/hast/postfix'
require 'lib/hast/verifier'

class Hast
  NAME = "HAST - Hosting Account Status Tool"

  attr_reader :config

  def initialize
    load_config
    parse_command_line_args
    load_domains
    verify_domains
  end

  private

  def logger(text, newline = true, yaml = nil)
    if @config['output'] == :yaml
      return if yaml.nil?
      text = yaml
    end

    if newline
      puts text
    else
      print text
      $stdout.flush
    end
  end

  def output_version
    version = nil
    File.open('VERSION') { |f| version = f.gets }
    puts "#{NAME} v#{version}"
  end

  def output_help
    RDoc::usage
  end

  def load_config
    @config = YAML::load(File.open('config.yml'))
    unless @config['apache']['base_path'].empty? && @config['apache']['base_path'] !~ /\/$/
      @config['apache']['base_path'] += '/'
    end
    @config['output'] ||= :stdout
  end

  def parse_command_line_args
    OptionParser.new do |opts|
      opts.on('-v', '--version')           { output_version; exit 0 }
      opts.on('-h', '--help')              { output_help }
      opts.on('-q', '--no-dns')            { @config['dns']['disable'] = true }
      opts.on('-y', '--yaml')              { @config['output'] = :yaml }
      opts.on('-c', '--domain-cache FILE') { |file| @config['domain_cache'] = file }
    end.parse!
  end

  def load_domains
    logger "Finding domains..."

    if @config['domain_cache']
      domains = YAML::load(File.open(@config['domain_cache']))
      @apache = domains['apache']
      @postfix = domains['postfix']
    else
      @apache = HAST::Apache.new(@config).domains
      @postfix = HAST::Postfix.new(@config).domains
    end
  end

  def verify_domains
    divider = '------------------------------------------------------------------------'
    output_block = Proc.new do |domain, max_length, status, ips|
      logger sprintf("%#{max_length}s : ", domain), false, "  - #{domain}\n"
      logger case status
      when :active
        'Active'
      when :inactive
        'Inactive (no record)'
      when :unknown
        'Status ukendt'
      when :other
        "Inactive (unexpected ip#{ips.size > 1 ? '\'s' : ''}: #{ips.join(', ')})"
      end
    end

    logger "\nWebhosting status:\n#{divider}", true, 'apache:'
    @apache.nil?  ? logger('No domains found') : HAST::Verifier.run(@config, @apache,  :web,  &output_block)

    logger "\nMailhosting status:\n#{divider}", true, 'postfix:'
    @postfix.nil? ? logger('No domains found') : HAST::Verifier.run(@config, @postfix, :mail, &output_block)
  end
end
