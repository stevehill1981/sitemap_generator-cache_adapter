# SitemapGenerator::CacheAdapter

A cache-based storage adapter for the [sitemap_generator](https://github.com/kjvarga/sitemap_generator) gem. Stores sitemaps in `Rails.cache` instead of the filesystem.

## Why?

The default `sitemap_generator` adapter writes sitemaps to disk. This doesn't work well for:

- **Kubernetes deployments** with ephemeral pod storage
- **Heroku** and other read-only filesystems
- **Multi-pod deployments** where sitemaps need to be shared across instances
- **Serverless environments** without persistent storage

This adapter stores sitemaps in your Rails cache instead. When used with a database-backed cache like [Solid Cache](https://github.com/rails/solid_cache), sitemaps persist across deploys and are shared across all application instances.

## Installation

Add to your Gemfile:

```ruby
gem "sitemap_generator-cache_adapter"
```

Then run:

```bash
bundle install
```

## Usage

### Basic Setup

Configure `sitemap_generator` to use the cache adapter in `config/sitemap.rb`:

```ruby
SitemapGenerator::Sitemap.default_host = "https://example.com"
SitemapGenerator::Sitemap.adapter = SitemapGenerator::CacheAdapter.new
SitemapGenerator::Sitemap.compress = false  # Recommended for cache storage
SitemapGenerator::Sitemap.create_index = false  # Single sitemap file

SitemapGenerator::Sitemap.create do
  add "/about", changefreq: "monthly"
  add "/contact", changefreq: "monthly"

  # Add dynamic content
  Post.find_each do |post|
    add post_path(post), lastmod: post.updated_at
  end
end
```

### Serving Sitemaps (Single File)

For most sites, a single sitemap file is sufficient (up to 50,000 URLs).

Create a controller to serve sitemaps from the cache:

```ruby
# app/controllers/sitemaps_controller.rb
class SitemapsController < ApplicationController
  def show
    xml = SitemapGenerator::CacheAdapter.fetch("sitemap.xml") do
      # Load the sitemap config, which runs create and caches the result
      load Rails.root.join("config", "sitemap.rb")
      SitemapGenerator::Sitemap.ping_search_engines  # Optional
    end

    if xml.present?
      render xml: xml
    else
      head :not_found
    end
  end
end
```

Add the route:

```ruby
# config/routes.rb
get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }
```

**Note**: Loading `config/sitemap.rb` executes the entire file, including the `create` block. This is how sitemap_generator is designed to work.

### Serving Sitemaps (Multiple Files)

For large sites with more than 50,000 URLs, sitemap_generator creates multiple files with an index:

```ruby
# config/sitemap.rb
SitemapGenerator::Sitemap.default_host = "https://example.com"
SitemapGenerator::Sitemap.adapter = SitemapGenerator::CacheAdapter.new
SitemapGenerator::Sitemap.compress = false
# Don't set create_index = false

SitemapGenerator::Sitemap.create do
  # Your URLs here - will be split across multiple files if needed
end
```

Update the controller to serve any sitemap file:

```ruby
# app/controllers/sitemaps_controller.rb
class SitemapsController < ApplicationController
  def show
    filename = if params[:id].present?
      "sitemap#{params[:id]}.xml"
    else
      "sitemap.xml"
    end

    xml = SitemapGenerator::CacheAdapter.fetch(filename) do
      load Rails.root.join("config", "sitemap.rb")
      SitemapGenerator::Sitemap.ping_search_engines
    end

    if xml.present?
      render xml: xml
    else
      head :not_found
    end
  end
end
```

Update the routes:

```ruby
# config/routes.rb
get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }
get "sitemap:id.xml", to: "sitemaps#show", defaults: { format: :xml }, constraints: { id: /[0-9]+/ }
```

This serves:
- `/sitemap.xml` - The sitemap index
- `/sitemap1.xml`, `/sitemap2.xml`, etc. - Individual sitemap files

### Configuration Options

```ruby
SitemapGenerator::Sitemap.adapter = SitemapGenerator::CacheAdapter.new(
  cache_key_prefix: "myapp:sitemap",  # Default: "sitemap_generator"
  expires_in: 12.hours,               # Default: 24.hours
  cache_store: Rails.cache            # Default: Rails.cache
)
```

### Class Methods

The adapter provides several class methods for working with cached sitemaps:

```ruby
# Fetch with lazy generation
xml = SitemapGenerator::CacheAdapter.fetch("sitemap.xml") do
  SitemapGenerator::Sitemap.create
end

# Read directly (returns nil if not cached)
xml = SitemapGenerator::CacheAdapter.read("sitemap.xml")

# Check existence
if SitemapGenerator::CacheAdapter.exist?("sitemap.xml")
  # ...
end

# Delete a specific sitemap
SitemapGenerator::CacheAdapter.delete("sitemap.xml")

# Clear all cached sitemaps
SitemapGenerator::CacheAdapter.clear_all
```

## How It Works

1. **On cache miss**: The `fetch` method yields to the block, which calls `SitemapGenerator::Sitemap.create`. This triggers the adapter's `write` method, storing the sitemap XML in the cache.

2. **On cache hit**: The cached XML is returned immediately without regeneration.

3. **Expiration**: Sitemaps expire after 24 hours by default. On the next request after expiration, a fresh sitemap is generated.

This "lazy regeneration" approach means:
- No scheduled jobs required
- Sitemaps are always fresh (within the cache TTL)
- First request after expiration may be slightly slower

## Cache Backend Compatibility

Works with any Rails cache backend:

- **Solid Cache** (recommended for Kubernetes) - Database-backed, shared across pods
- **Redis** - Fast, shared across pods
- **Memcached** - Fast, shared across pods
- **Memory Store** - Development/testing only (not shared)
- **File Store** - Single-server deployments only

## Example: Kubernetes with Solid Cache

```ruby
# Gemfile
gem "solid_cache"
gem "sitemap_generator"
gem "sitemap_generator-cache_adapter"

# config/environments/production.rb
config.cache_store = :solid_cache_store

# config/sitemap.rb
SitemapGenerator::Sitemap.adapter = SitemapGenerator::CacheAdapter.new
```

With this setup, sitemaps are stored in your database and accessible from any pod in your cluster.

## Migrating from File-Based Sitemaps

1. Add the gem to your Gemfile
2. Update `config/sitemap.rb` to use the cache adapter
3. Create the sitemaps controller and route
4. Remove any sitemap-related cron jobs or scheduled tasks
5. Add `public/sitemap*.xml` to `.gitignore`
6. Delete existing static sitemap files

## Development

```bash
bundle install
bundle exec rspec
bundle exec standardrb
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
