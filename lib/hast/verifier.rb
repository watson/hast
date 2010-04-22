require 'net/dns/resolver'

module HAST
  class Verifier
    class << self
      def run(config, domains, type, &output_block)
        instance = self.new(config, domains, type, &output_block)
        instance.verify_domains
      end
    end

    def initialize(config, domains, type, &output_block)
      @config = config
      @domains = domains
      @type = type
      @output_block = output_block
      @dns = Net::DNS::Resolver.new
      @dns.nameservers = [@config['dns']['primary'], @config['dns']['secondary']].compact
    end

    def verify_domains
      @domains.each do |domain|
        if @config['dns']['disable']
          ips = nil
        else
          case @type
          when :web
            ips = get_server_ips(domain)
            expected_ip = @config['apache']['ip']
          when :mail
            ips = get_mailserver_ips(domain)
            expected_ip = @config['postfix']['ip']
          end
        end

        if ips.nil?
          @output_block.call domain, max_length, :unknown
        elsif ips.empty?
          @output_block.call domain, max_length, :inactive
        elsif ips.include? expected_ip
          @output_block.call domain, max_length, :active
        else
          @output_block.call domain, max_length, :other, ips
        end
      end
    end

    private

    def max_length
      max_length = 0
      @domains.each do |domain|
        max_length = domain.length if domain.length > max_length
      end
      max_length
    end

    def get_server_ips(domain)
      ips = []
      begin
        @dns.query(domain).each_address { |ip| ips << ip.to_s }
      rescue Net::DNS::Resolver::NoResponseError
        ips = nil
      end
      ips
    end

    def get_mailserver_ips(domain)
      ips = []
      @dns.query(domain, Net::DNS::MX).each_mx do |pref, name|
        ips << get_server_ips(name)
      end
      ips.flatten.uniq
    end
  end
end
