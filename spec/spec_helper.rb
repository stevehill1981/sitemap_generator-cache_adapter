# frozen_string_literal: true

require "sitemap_generator-cache_adapter"

# Simple in-memory cache store for testing (mimics Rails.cache interface)
class MemoryCacheStore
  def initialize
    @data = {}
    @expires_at = {}
  end

  def read(key)
    return nil if expired?(key)
    @data[key]
  end

  def write(key, value, options = {})
    @data[key] = value
    if options[:expires_in]
      @expires_at[key] = Time.now + options[:expires_in]
    end
    value
  end

  def fetch(key, options = {}, &block)
    return read(key) if exist?(key)

    value = yield if block_given?
    # Note: The adapter writes during the block, so we read after
    read(key) || value
  end

  def exist?(key)
    return false unless @data.key?(key)
    !expired?(key)
  end

  def delete(key)
    @data.delete(key)
    @expires_at.delete(key)
    true
  end

  def delete_matched(pattern)
    regex = Regexp.new(pattern.gsub("*", ".*"))
    @data.keys.each do |key|
      if key.match?(regex)
        delete(key)
      end
    end
  end

  def clear
    @data.clear
    @expires_at.clear
  end

  private

  def expired?(key)
    return false unless @expires_at[key]
    Time.now > @expires_at[key]
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
