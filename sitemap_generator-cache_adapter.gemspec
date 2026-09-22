# frozen_string_literal: true

require_relative "lib/sitemap_generator/cache_adapter/version"

Gem::Specification.new do |spec|
  spec.name = "sitemap_generator-cache_adapter"
  spec.version = SitemapGenerator::CacheAdapter::VERSION
  spec.authors = ["Steve Hill"]
  spec.email = ["steve@stevehill.xyz"]

  spec.summary = "Cache adapter for sitemap_generator gem"
  spec.description = <<~DESC
    A cache-based storage adapter for the sitemap_generator gem. Stores sitemaps
    in Rails.cache instead of the filesystem, making it ideal for Kubernetes
    deployments, Heroku, and other environments with ephemeral or read-only
    filesystems. Works with any Rails cache backend including Solid Cache,
    Redis, and Memcached.
  DESC
  spec.homepage = "https://github.com/stevehill1981/sitemap_generator-cache_adapter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "sitemap_generator", ">= 6.0", "< 8"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.0"
end
