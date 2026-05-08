# sitemap_generator-cache_adapter modernisation assessment

**Date:** 2026-05-08
**Author:** Steve + Claude (NetNodes-wide modernisation programme; eighteenth assessment)
**Status:** Brief — tiny custom gem.

---

## Status

A 14-file Ruby gem providing a cache-based storage adapter for `sitemap_generator`, so sitemaps can be written to `Rails.cache` instead of the filesystem (relevant for k8s ephemeral pods and read-only-FS deployments).

## Why this assessment is brief

A single-purpose adapter gem with 14 files doesn't fit the modernisation template. The relevant questions are:

- Is it published to RubyGems, or only used internally? (Affects whether maintenance includes a release process.)
- Are there active consumers across NetNodes apps? Marketing sites use `sitemap_generator` (see dc-web, nn-web, passflow-web assessments). If they all use this adapter, it's load-bearing.
- Is the upstream `sitemap_generator` gem still maintained? Adapter relevance depends on host gem health.

## Recommendation

1. **Confirm consumers** — grep across NetNodes Rails apps for `gem "sitemap_generator-cache_adapter"`. dc-web and passflow-web both pull it (visible in their Gemfiles). nn-web does too.
2. **Document the consumers** in this gem's README so future-Steve knows what depends on it.
3. **No fleet-hygiene items apply** — too small to need them.

---

*Companion to the other 17 assessments.*
