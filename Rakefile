require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "hast"
    gem.summary = %Q{Hosting Account Status Tool - Fetch domains from Apache configuration files and the Postfix database on a hosting server environment. Then run a report checking each domains DNS records to see if they match your server.}
    gem.description = <<-EOF
      HAST stands for 'Hosting Account Status Tool'.

      HAST is a tool for fetching domains from Apache configuration files and
      from the Postfix database on a hosting server environment. It will then
      run a report, checking the DNS records for each domain to see if they
      match your server.

      This is important for finding "dead" domains where the domain either
      doesn't exist anymore or where the owner have moved it to another
      hosting provider.

      Before you can use HAST, you need to setup a config.yml file. Use
      config.yml.example as a template.
    EOF
    gem.email = "w@tson.dk"
    gem.homepage = "http://github.com/watson/hast"
    gem.authors = ["Thomas Watson Steen"]
    gem.add_development_dependency "mysql", ">= 0"
    gem.add_development_dependency "net-dns", ">= 0"
    gem.add_development_dependency "deep_merge", ">= 0.1.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :default => :version
