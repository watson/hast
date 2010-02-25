require 'rubygems'
require 'optparse'
require 'yaml'
require 'deep_merge'
require 'hast/apache'
require 'hast/postfix'
require 'hast/verifier'

class Hast
  NAME = "HAST - Hosting Account Status Tool"

  attr_reader :config

  def initialize
    parse_command_line_args
    load_config
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
    File.open(File.dirname(__FILE__) + '/../VERSION') { |f| version = f.gets }
    puts "#{NAME} v#{version}"
  end

  def output_config_template
    File.open(File.dirname(__FILE__) + '/../config.yml.template') { |f| puts f.readlines }
  end

  def load_config
    unless File.exists? @config_file
      puts "ERROR: Could not find config file '#{@config_file}'... aborting"
      exit 1
    end

    @config.deep_merge! YAML::load(File.open(@config_file))
    unless @config['apache']['base_path'].empty? && @config['apache']['base_path'] !~ /\/$/
      @config['apache']['base_path'] += '/'
    end
  end

  def parse_command_line_args
    @config = {'output' => :stdout}
    options = OptionParser.new do |opts|
      opts.banner = "Usage: hast config-file [options]"
      opts.separator ''
      opts.separator 'Specific options:'
      opts.on('-v', '--version',
              'Show this message')                                        { output_version; exit 0 }
      opts.on('-h', '--help',
              'Show version')                                             { puts opts; exit 0 }
      opts.on('-g', '--generate-config',
              'Output a config file template',
              '(pipe it to a file for easy use: hast -g > config.yml)')   { output_config_template; exit 0 }
      opts.on('-q', '--disable-lookup',
              'Do not lookup any domain names or MX records')             { @config['dns'] = { 'disable' => true } }
      opts.on('-y', '--yaml',
              'Output as YAML',
              '(pipe it to a file for easy use: hast -y > domains.yml)')  { @config['output'] = :yaml }
      opts.on('-c', '--domain-cache FILE',
              'Get the domains from a YAML file')                         { |file| @config['domain_cache'] = file }
      opts.separator ''
      opts.separator 'See http://github.com/watson/hast for details'
    end
    options.parse!

    unless @config_file = ARGV.delete_at(0)
      puts "ERROR: You must supply a config file as the first argument!"
      puts "       To generate a config file template use the -g argument"
      puts
      puts options
      exit 1
    end
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
        'Status unknown'
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
