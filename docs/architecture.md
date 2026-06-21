# Architecture Overview

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Browser / Client                          │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Rails 8 App (Puma)                          │
├─────────────────────────────────────────────────────────────┤
│  Controllers  │  Services  │  Models  │  ViewComponents     │
└────────────────────────────┬────────────────────────────────┘
                         │
      ┌──────────────────┼──────────────────┐
      ▼                  ▼                   ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ PostgreSQL   │  │ Solid Queue  │  │ Solid Cache  │
│ (main DB)    │  │ (jobs)       │  │ (fragments)  │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Layered Architecture

```
app/
├── controllers/           # Thin: parse params, delegate to services
├── models/                # AR models, simple validations & scopes
├── services/              # Business logic: matching, scoring, normalization
├── components/            # ViewComponent classes: reusable UI
├── views/                 # ERB templates: mostly component renders
├── jobs/                  # ActiveJob: async recipe ingestion
└── helpers/               # Tiny helpers, no business logic
```

## Key Services

### RecipeMatcher
Entry point for search queries. Takes pantry ingredients and filters, returns ranked recipes with pagination.

**Responsibilities:**
- Resolve ingredient IDs from user input
- Filter recipes by pantry match
- Apply exclusions and cookability filters
- Delegate ranking to RecipeScorer
- Paginate results

**Called from:** `RecipesController#index`

### RecipeScorer
Calculates match scores for a single recipe given a pantry.

**Responsibilities:**
- Count matched vs. total non-staple ingredients
- Calculate match ratio
- Determine if fully cookable
- Support multiple sort orders (best match, quickest, highest rated)

**Called from:** `RecipeMatcher`

### IngredientNormalizer
Parses raw ingredient text and normalizes to canonical form.

**Responsibilities:**
- Parse quantity (fractions, ranges, mixed numbers)
- Extract and standardize unit
- Strip descriptors ("fresh", "finely chopped", etc.)
- Singularize ingredient name
- Detect pantry staples
- Fuzzy match against existing ingredients

**Called from:** Seed task (one-time normalization)

## Data Flow

### Search Flow
```
Browser Input
    ↓
[Enter ingredients]
    ↓
RecipesController#index
  ↓
RecipeMatcher.call(pantry_ingredients, filters)
  ├─ Resolve ingredient IDs
  ├─ Find matching recipes
  ├─ Score each recipe
  ├─ Filter & sort
  ├─ Paginate
  ↓
RecipeCardComponent (×25)
  ├─ Render title, image
  ├─ MatchMeterComponent (signature bar)
  ├─ Display missing ingredients
  ↓
[HTML Response]
    ↓
Browser displays results
```

### Seed Flow
```
recipes-en.json (20k recipes)
    ↓
rake recipes:seed
    ├─ Read JSON line by line
    ├─ IngredientNormalizer.call(ingredient_text)
    ├─ Upsert Recipe record
    ├─ Upsert Ingredient records
    ├─ Create RecipeIngredient associations
    ↓
Database populated
    ↓
Run background job: RecomputeUsageCountsJob
    ↓
ingredients.usage_count updated
    ↓
Ready for queries
```

## Database Schema

Three core tables:

| Table | Columns | Indexes |
|-------|---------|---------|
| `recipes` | id, title, slug, source_url, image_url, instructions, total_time_minutes, ingredient_count, ... | slug (unique), source_url (unique), ingredient_count, total_time_minutes, ratings |
| `ingredients` | id, name, display_name, is_pantry_staple, usage_count | name (unique) |
| `recipe_ingredients` | id, recipe_id, ingredient_id, quantity, unit, position | (ingredient_id, recipe_id) composite; (recipe_id, position) |

The composite index on `recipe_ingredients(ingredient_id, recipe_id)` is critical — it drives the matching query.

## Caching Strategy

Three layers:

1. **HTTP caching**: Recipe detail pages get `Cache-Control: public, max-age=3600`. Results pages uncached (query-dependent).

2. **Fragment caching**: Each `RecipeCardComponent` is cached by `[recipe.cache_key, pantry_signature]`. Different pantries see different cards. Uses Solid Cache (DB-backed).

3. **Russian doll**: Result grid wraps card caches. A single card miss doesn't bust the entire page.

**Invalidation**: Recipes versioned by `updated_at` (Rails default). Re-seeding bumps `updated_at`, invalidating caches automatically.

## Background Jobs

Solid Queue (DB-backed) runs:

| Job | Trigger | Purpose |
|-----|---------|---------|
| `IngestRecipeJob` | Enqueued by seed task | Parse one recipe, upsert |
| `RecomputeUsageCountsJob` | Nightly cron | Refresh `ingredients.usage_count` |
| `WarmCacheJob` | Post-deploy | Pre-render top 100 recipe detail pages |

## Performance Strategy

**Targets:**
- Search p50 < 100ms
- Search p95 < 300ms
- Result page LCP < 1.5s
- First seed < 5 min

**Achieved via:**
- Composite index on `(ingredient_id, recipe_id)`
- Denormalized `ingredient_count` (avoids aggregate in query)
- No N+1 queries (verified with Bullet gem)
- Fragment caching of recipe cards
- Lazy-loaded images with explicit dimensions
- No JS framework (Hotwire only)

## Deployment

Deployed to Fly.io:
- Rails app on shared-cpu-1x with 512MB RAM
- Managed PostgreSQL (Fly PG)
- Zero-downtime migrations via release command
- Auto-scaling (not needed for portfolio, but configured)
- Health checks every 15s
- Status badge in README

## Development Environment

```bash
bin/dev  # Starts Puma + Tailwind watcher + Solid Queue worker
```

Uses `.env.local` for secrets (not committed).

## Testing

RSpec 6 with:
- Capybara + Cuprite for system tests
- FactoryBot for fixtures
- Shoulda Matchers for model specs
- VCR for HTTP mocking (if needed)

Test pyramid: 5 system tests, ~25 request tests, ~80 unit tests.
Target: ≥ 85% coverage (measured with SimpleCov).

## Future Scaling

If this becomes a real product:

1. **User accounts** (phase v0.2): Devise or Rails 8 built-in authentication.
2. **Elasticsearch** (if search complexity grows): Fuzzy matching, synonym support, dietary filters.
3. **Recipe API** (if mobile app planned): Extract JSON API, keep web UI in Rails monolith.
4. **Image CDN** (if serving 100k+ images): Upload to S3, serve via Cloudflare.
5. **Multi-region** (if international): Fly.io supports multiple regions; replicate PG setup.

Current architecture supports these paths without major rewrites.
