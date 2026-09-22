# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-22

### Changed

- Allow sitemap_generator 7.x (`>= 6.0, < 8`). The `~> 6.0` constraint forced apps using this adapter back to sitemap_generator 6.3.0. The adapter's `write(location, raw_data)` interface is unchanged in 7.x, and the specs plus an end-to-end `LinkSet#create` pass against 7.1.1.
- Run CI on Ruby 4.0 as well.

## [1.0.1] - 2026-01-10

### Fixed

- Use pessimistic version constraint (`~> 6.0`) for sitemap_generator dependency
- Remove duplicate homepage_uri metadata

## [1.0.0] - 2026-01-10

### Added

- Initial release
- `SitemapGenerator::CacheAdapter` class for storing sitemaps in Rails.cache
- Support for custom cache key prefix and expiration time
- Support for custom cache store
- Class methods: `fetch`, `read`, `exist?`, `delete`, `clear_all`
- Comprehensive documentation and examples
