module HAST
  class Apache
    attr_reader :domains

    def initialize(config)
      @config = config

      config_files = find_config_files(@config['apache']['config'])

      domains = find_domains_in_config(config_files)
      domains << find_extra_domains if @config['apache']['extra_domains_directory']
      domains.flatten!
      domains.uniq!

      @domains = domains
    end

    private

    def find_pattern_in_file(filename, pattern, ignore_pattern = /^\s*#/, &block)
      File.open(filename).each_line do |line|
        line.chomp!
        next if line =~ ignore_pattern
        if match = line.match(pattern)
          yield match
        end
      end
    end

    def find_config_files(filename)
      config_files = [filename]
      find_pattern_in_file(filename, /^\s*Include\s+(.*)$/i) do |match|
        # the include file might be a filename pattern instead of a real filname
        Dir.glob(@config['apache']['base_path'] + match[1]).each do |include_file|
          config_files << find_config_files(include_file)
        end
      end
      config_files.flatten.uniq
    end

    def find_domains_in_config(config_files)
      domains = []
      config_files.each do |filename|
        find_pattern_in_file(filename, /^\s*(ServerName|ServerAlias)\s+(.*)$/i) do |match|
          domains << match[2].split.map { |domain| domain.gsub(/:\d+$/, '') }
        end
      end
      domains.flatten.uniq
    end

    def find_extra_domains
      domains = []
      Dir.foreach(@config['apache']['extra_domains_directory']) do |entry|
        next if entry =~ /^\.\.?$/
        domains << entry
      end
      domains
    end
  end
end
