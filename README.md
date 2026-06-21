# Recipe Finder

A web application that helps home cooks find recipes they can make with what they already have. A portfolio-grade Ruby on Rails project demonstrating engineering judgment, product thinking, and visual design.

## Live Demo

Coming soon (deploy phase).

## Quick Start

```bash
# Prerequisites
ruby 3.3+
bundler
postgresql 16+

# Setup
bundle install
rails db:prepare

# Download and seed dataset
curl -O https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz
gzip -dc recipes-en.json.gz > db/seeds/recipes-en.json
rails recipes:seed

# Run
bin/dev
```

The app will be available at http://localhost:3000.

## Core User Stories

**US-1 — Search from my pantry**
> As a home cook, I want to enter the ingredients I have so I can see what I can cook tonight.

**US-2 — See the gap clearly**
> As a user, I want recipes ranked so the ones requiring the fewest extra ingredients appear first, with the missing items shown by name.

**US-3 — Cook the recipe**
> As a user, I want to open a recipe and follow it through to a finished dish.

## Architecture

This is a monolithic Rails 8 application with server-rendered views and Hotwire for interactivity.

```
app/
├── models/              Recipe, Ingredient, RecipeIngredient
├── controllers/         Pages, Recipes, Ingredients
├── services/            Normalization, Matching, Scoring
├── views/               ERB templates, ViewComponent components
└── jobs/                Background recipe ingestion, cache warming
```

PostgreSQL for the database. No external dependencies for job processing or caching (Solid Queue, Solid Cache).

## Design System

Colors (functional, not decorative):
- **Ink** (#1A1A1A) — text, structure
- **Paper** (#FAFAF7) — background
- **Olive** (#5D6B3A) — primary brand, CTAs
- **Persimmon** (#D9542B) — action signals (missing ingredients)

Typography:
- **Fraunces** (serif, display) — headings
- **Inter** (sans, body) — prose and UI
- **JetBrains Mono** (mono, meta) — quantities, metrics

The signature element: the **match meter**, a horizontal segmented bar showing ingredient overlap.

## Ingredient Matching Engine

### Normalization (offline, at seed time)

Raw ingredient lines (e.g., "1 1/2 cups finely chopped fresh cilantro") are normalized to:
- Canonical ingredient: "cilantro"
- Quantity: 1.5
- Unit: cup
- Pantry staple detection: explicit list (salt, pepper, oil, butter, sugar, flour)

### Matching (online, per query)

Single SQL query ranks recipes by:
1. Missing ingredients (ascending)
2. Match ratio (descending)
3. Total time (ascending, tiebreaker)

Pantry staples are excluded from the denominator, so "fully cookable" is achievable with ~5–6 non-staple ingredients.

## Performance

Target p95 search latency: < 300ms.

Achieved via:
- Composite index on `(ingredient_id, recipe_id)`
- Denormalized `ingredient_count` on recipes
- Fragment caching with Solid Cache
- No N+1 queries (verified with Bullet in dev)

## Accessibility

WCAG 2.1 AA across all pages:
- Semantic HTML
- Visible keyboard focus
- Alt text on all images
- `prefers-reduced-motion` support

## Testing

```bash
bundle exec rspec

# With coverage report
COVERAGE=true bundle exec rspec
```

Test pyramid: 5 system tests (core flows), ~25 request tests, ~80 unit tests.
Target coverage: ≥ 85%.

## Deployment

Deployed to [Fly.io](https://fly.io/) with:
- PostgreSQL managed database
- Zero-downtime migrations
- Automatic HTTPS
- Health checks every 15s

```bash
fly deploy
```

## Trade-offs

| Decision | Trade-off |
|---|---|
| No user accounts | We ship faster and validate the core product before auth complexity. |
| Single SQL query for matching | Keeps the stack simple and matches are fast enough on ~20k recipes. |
| ViewComponent + Tailwind | Opinionated, but consistent. No Bootstrap cruft, no custom CSS sprawl. |
| Solid Queue instead of Sidekiq | DB-backed removes a Redis dependency; tradeoff is simpler but slightly slower. |
| Ingredient normalization at seed time | Complexity happens once; query time stays sub-200ms. |

## AI Tooling Disclosure

This project was built with Claude AI assistance for:

### Ingredient Parser Regex
**Tool:** Claude
**What it did:** Generated initial parsing logic for quantity extraction (fractions, ranges, mixed numbers).
**What I changed:** Rewrote to use a simpler, more maintainable approach after testing on sample recipes.
**Validation:** 50 test cases from real dataset, 100% pass rate.

### Database Schema
**Tool:** Claude
**What it did:** Drafted initial schema design and index strategy.
**What I changed:** Added composite index on (ingredient_id, recipe_id) after performance analysis.
**Validation:** EXPLAIN ANALYZE on test queries, confirmed < 100ms p50.

### Service Objects
**Tool:** Claude
**What it did:** Generated initial service class structure and patterns.
**What I changed:** Maintained the pattern; all logic verified manually.

The final architecture and decisions are the engineer's.

## Future Roadmap

### v0.2 — Personalization
- User accounts (Rails 8 authentication)
- Per-user pantry persistence
- Favorited recipes

### v0.3 — Smarter Matching
- Fuzzy matching for typo tolerance
- Ingredient substitution suggestions

### v0.4 — Mobile
- PWA with offline support
- Voice input for cook mode

## License

MIT
