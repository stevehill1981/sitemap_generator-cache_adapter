# frozen_string_literal: true

require "sitemap_generator"

module SitemapGenerator
  # An adapter for SitemapGenerator that stores sitemaps in Rails.cache instead of the filesystem.
  #
  # This is useful for:
  # - Kubernetes deployments with no persistent disk storage
  # - Heroku and other read-only/ephemeral filesystems
  # - Multi-pod deployments where sitemaps need to be shared across instances
  #
  # When used with a database-backed cache (like Solid Cache), sitemaps persist
  # across deploys and are shared across all application instances.
  #
  # @example Basic usage in config/sitemap.rb
  #   SitemapGenerator::Sitemap.adapter = SitemapGenerator::CacheAdapter.new
  #
  # @example With custom options
  #   SitemapGenerator::Sitemap.adapter = SitemapGenerator::CacheAdapter.new(
  #     cache_key_prefix: "myapp:sitemap",
  #     expires_in: 12.hours
  #   )
  #
  # @example Serving from a Rails controller
  #   class SitemapsController < ApplicationController
  #     def show
  #       xml = SitemapGenerator::CacheAdapter.fetch("sitemap.xml") do
  #         SitemapGenerator::Sitemap.create
  #       end
  #       render xml: xml
  #     end
  #   end
  #
  class CacheAdapter
    DEFAULT_CACHE_KEY_PREFIX = "sitemap_generator"
    DEFAULT_EXPIRES_IN = 86_400 # 24 hours in seconds

    class << self
      # @return [String] The prefix used for all cache keys
      def cache_key_prefix
        @cache_key_prefix || DEFAULT_CACHE_KEY_PREFIX
      end

      # @param value [String] The prefix to use for all cache keys
      attr_writer :cache_key_prefix

      # @return [Integer, ActiveSupport::Duration] The cache expiration time
      def expires_in
        @expires_in || DEFAULT_EXPIRES_IN
      end

      # @param value [Integer, ActiveSupport::Duration] The cache expiration time
      attr_writer :expires_in

      # @return [#fetch, #read, #write, #exist?, #delete] The cache store to use
      def cache_store
        @cache_store || default_cache_store
      end

      # @param value [#fetch, #read, #write, #exist?, #delete] The cache store to use
      attr_writer :cache_store

      # Fetch a sitemap from cache, generating it if not present.
      #
      # @param filename [String] The sitemap filename (e.g., "sitemap.xml")
      # @yield Block that generates the sitemap (typically calls SitemapGenerator::Sitemap.create)
      # @return [String] The sitemap XML content
      #
      # @example
      #   xml = SitemapGenerator::CacheAdapter.fetch("sitemap.xml") do
      #     SitemapGenerator::Sitemap.create
      #   end
      def fetch(filename, &block)
        cache_key = "#{cache_key_prefix}:#{filename}"

        cache_store.fetch(cache_key, expires_in: expires_in) do
          yield if block_given?
          cache_store.read(cache_key)
        end
      end

      # Read a sitemap directly from cache without generation.
      #
      # @param filename [String] The sitemap filename
      # @return [String, nil] The sitemap XML content or nil if not cached
      def read(filename)
        cache_store.read("#{cache_key_prefix}:#{filename}")
      end

      # Check if a sitemap exists in cache.
      #
      # @param filename [String] The sitemap filename
      # @return [Boolean]
      def exist?(filename)
        cache_store.exist?("#{cache_key_prefix}:#{filename}")
      end

      # Delete a specific sitemap from cache.
      #
      # @param filename [String] The sitemap filename
      # @return [Boolean] true if deleted, false otherwise
      def delete(filename)
        cache_store.delete("#{cache_key_prefix}:#{filename}")
      end

      # Clear all cached sitemaps matching the prefix.
      #
      # @note This only works with cache stores that support delete_matched
      # @return [void]
      def clear_all
        if cache_store.respond_to?(:delete_matched)
          cache_store.delete_matched("#{cache_key_prefix}:*")
        else
          # Fallback: delete known sitemap filenames
          %w[sitemap.xml sitemap.xml.gz sitemap_index.xml sitemap_index.xml.gz].each do |f|
            delete(f)
          end
        end
      end

      # Reset configuration to defaults.
      #
      # @return [void]
      def reset!
        @cache_key_prefix = nil
        @expires_in = nil
        @cache_store = nil
      end

      private

      def default_cache_store
        if defined?(Rails) && Rails.respond_to?(:cache)
          Rails.cache
        else
          raise ConfigurationError, "No cache store configured. Set SitemapGenerator::CacheAdapter.cache_store or use within a Rails application."
        end
      end
    end

    # Error raised when the adapter is misconfigured
    class ConfigurationError < StandardError; end

    # Initialize a new CacheAdapter.
    #
    # @param cache_key_prefix [String] Prefix for cache keys (default: "sitemap_generator")
    # @param expires_in [Integer, ActiveSupport::Duration] Cache expiration time (default: 24.hours)
    # @param cache_store [#fetch, #read, #write] Cache store to use (default: Rails.cache)
    #
    # @example
    #   adapter = SitemapGenerator::CacheAdapter.new(
    #     cache_key_prefix: "myapp:sitemap",
    #     expires_in: 12.hours
    #   )
    def initialize(cache_key_prefix: nil, expires_in: nil, cache_store: nil)
      self.class.cache_key_prefix = cache_key_prefix if cache_key_prefix
      self.class.expires_in = expires_in if expires_in
      self.class.cache_store = cache_store if cache_store
    end

    # Write sitemap data to the cache.
    #
    # This method is called by SitemapGenerator when creating sitemaps.
    # It conforms to the adapter interface expected by sitemap_generator.
    #
    # @param location [SitemapGenerator::SitemapLocation] Location object with filename info
    # @param raw_data [String] The raw XML sitemap data
    # @return [void]
    def write(location, raw_data)
      cache_key = "#{self.class.cache_key_prefix}:#{location.filename}"

      self.class.cache_store.write(
        cache_key,
        raw_data,
        expires_in: self.class.expires_in
      )

      log_write(location.filename, raw_data.bytesize)
    end

    private

    def log_write(filename, bytesize)
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.info "[SitemapGenerator::CacheAdapter] Cached #{filename} (#{bytesize} bytes)"
      end
    end
  end
end
