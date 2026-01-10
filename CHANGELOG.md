# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
