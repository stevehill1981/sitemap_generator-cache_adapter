# frozen_string_literal: true

require "spec_helper"

RSpec.describe SitemapGenerator::CacheAdapter do
  let(:cache_store) { MemoryCacheStore.new }
  let(:adapter) { described_class.new(cache_store: cache_store) }
  let(:location) { double("SitemapLocation", filename: "sitemap.xml") }
  let(:raw_data) { '<?xml version="1.0" encoding="UTF-8"?><urlset></urlset>' }

  before do
    described_class.reset!
    described_class.cache_store = cache_store
  end

  after do
    described_class.reset!
  end

  describe "#initialize" do
    it "accepts custom cache_key_prefix" do
      described_class.new(cache_key_prefix: "custom", cache_store: cache_store)
      expect(described_class.cache_key_prefix).to eq("custom")
    end

    it "accepts custom expires_in" do
      described_class.new(expires_in: 3600, cache_store: cache_store)
      expect(described_class.expires_in).to eq(3600)
    end

    it "accepts custom cache_store" do
      custom_store = MemoryCacheStore.new
      described_class.new(cache_store: custom_store)
      expect(described_class.cache_store).to eq(custom_store)
    end
  end

  describe "#write" do
    it "stores sitemap data in the cache" do
      adapter.write(location, raw_data)

      cached = cache_store.read("sitemap_generator:sitemap.xml")
      expect(cached).to eq(raw_data)
    end

    it "uses custom cache key prefix" do
      described_class.new(cache_key_prefix: "myapp", cache_store: cache_store)
      adapter = described_class.new(cache_store: cache_store)
      adapter.write(location, raw_data)

      cached = cache_store.read("myapp:sitemap.xml")
      expect(cached).to eq(raw_data)
    end
  end

  describe ".fetch" do
    context "when sitemap is not cached" do
      it "yields the block" do
        block_called = false

        described_class.fetch("sitemap.xml") do
          block_called = true
          adapter.write(location, raw_data)
        end

        expect(block_called).to be true
      end

      it "returns the cached content after block execution" do
        result = described_class.fetch("sitemap.xml") do
          adapter.write(location, raw_data)
        end

        expect(result).to eq(raw_data)
      end
    end

    context "when sitemap is already cached" do
      before do
        adapter.write(location, raw_data)
      end

      it "returns cached content without yielding" do
        block_called = false

        result = described_class.fetch("sitemap.xml") do
          block_called = true
        end

        expect(result).to eq(raw_data)
        expect(block_called).to be false
      end
    end
  end

  describe ".read" do
    it "returns nil when sitemap is not cached" do
      expect(described_class.read("sitemap.xml")).to be_nil
    end

    it "returns cached content when present" do
      adapter.write(location, raw_data)
      expect(described_class.read("sitemap.xml")).to eq(raw_data)
    end
  end

  describe ".exist?" do
    it "returns false when sitemap is not cached" do
      expect(described_class.exist?("sitemap.xml")).to be false
    end

    it "returns true when sitemap is cached" do
      adapter.write(location, raw_data)
      expect(described_class.exist?("sitemap.xml")).to be true
    end
  end

  describe ".delete" do
    it "removes the sitemap from cache" do
      adapter.write(location, raw_data)
      expect(described_class.exist?("sitemap.xml")).to be true

      described_class.delete("sitemap.xml")
      expect(described_class.exist?("sitemap.xml")).to be false
    end
  end

  describe ".clear_all" do
    it "removes all sitemaps with delete_matched" do
      adapter.write(location, raw_data)
      adapter.write(double("SitemapLocation", filename: "sitemap2.xml"), raw_data)

      described_class.clear_all

      expect(described_class.exist?("sitemap.xml")).to be false
      expect(described_class.exist?("sitemap2.xml")).to be false
    end
  end

  describe ".reset!" do
    it "resets configuration to defaults" do
      described_class.cache_key_prefix = "custom"
      described_class.expires_in = 1234
      described_class.reset!

      expect(described_class.cache_key_prefix).to eq("sitemap_generator")
      expect(described_class.expires_in).to eq(86_400)
    end
  end

  describe "default values" do
    before { described_class.reset! }

    it "has default cache_key_prefix" do
      expect(described_class.cache_key_prefix).to eq("sitemap_generator")
    end

    it "has default expires_in of 24 hours" do
      expect(described_class.expires_in).to eq(86_400)
    end
  end
end
