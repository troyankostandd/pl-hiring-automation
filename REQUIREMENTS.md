# Recipe Finder — Senior-Level Project Specification

> A web application that helps home cooks find recipes they can make with what they already have. Built as a portfolio-grade Ruby on Rails project demonstrating engineering judgment, product thinking, and visual design.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Principles](#2-product-vision--principles)
3. [Target User & Jobs to be Done](#3-target-user--jobs-to-be-done)
4. [User Stories](#4-user-stories)
5. [User Flows](#5-user-flows)
6. [Information Architecture](#6-information-architecture)
7. [Visual Design System](#7-visual-design-system)
8. [Page Specifications](#8-page-specifications)
9. [Functional Requirements](#9-functional-requirements)
10. [Technical Architecture](#10-technical-architecture)
11. [Data Model](#11-data-model)
12. [Ingredient Matching Engine](#12-ingredient-matching-engine)
13. [Routes & API Surface](#13-routes--api-surface)
14. [Frontend Architecture](#14-frontend-architecture)
15. [Performance Strategy](#15-performance-strategy)
16. [Caching Strategy](#16-caching-strategy)
17. [Background Jobs](#17-background-jobs)
18. [Security Requirements](#18-security-requirements)
19. [Accessibility Requirements](#19-accessibility-requirements)
20. [SEO & Structured Data](#20-seo--structured-data)
21. [Internationalization Readiness](#21-internationalization-readiness)
22. [Testing Strategy](#22-testing-strategy)
23. [CI/CD & DevOps](#23-cicd--devops)
24. [Observability](#24-observability)
25. [Code Quality & Conventions](#25-code-quality--conventions)
26. [Documentation Requirements](#26-documentation-requirements)
27. [AI Tooling Protocol](#27-ai-tooling-protocol)
28. [Phased Milestones](#28-phased-milestones)
29. [Risks & Mitigations](#29-risks--mitigations)
30. [Definition of Done](#30-definition-of-done)
31. [Future Roadmap](#31-future-roadmap)

---

## 1. Executive Summary

A Ruby on Rails 8 application that ingests a corpus of ~20,000+ scraped recipes, normalizes their ingredients, and lets users discover what they can cook based on what's in their kitchen. The match is ranked, not boolean — the headline product moment is "you're 4 of 5 ingredients away from this dish."

The project is intentionally constrained in scope (no auth, no user-generated content, no social features) and intentionally generous in craft (proper design system, real performance work, full test coverage, observability, accessibility).

**What makes this senior-level:**
- A real domain model, not a tutorial CRUD app.
- A non-trivial algorithm (ingredient normalization + relevance scoring) with documented trade-offs.
- A design system grounded in the subject, not a Bootstrap default.
- Performance engineering: indexes, caching, query analysis, sub-200ms p95.
- Test pyramid that catches real bugs.
- Deployed, observable, monitored, documented.

---

## 2. Product Vision & Principles

### 2.1 Product thesis

> Most recipe apps are *discovery* engines: browse, save, dream. This is a *decision* engine: what should I cook right now, given the constraint of my kitchen? The app's job is to collapse the gap between "I'm hungry" and "I'm cooking."

### 2.2 Principles

1. **Constraint-first.** The user starts from what they have, not from what they want. The pantry is the primary input, not a filter.
2. **Show the gap.** Never hide what's missing. If a recipe needs 7 ingredients and the user has 5, show the 2 missing ones immediately, by name, so they can decide.
3. **Speed is the feature.** Every interaction should feel instant. If the user has to wait, the experiment failed.
4. **Defer nothing critical.** A recipe page should be cookable on its own. No half-loaded states, no "click to expand" for instructions.
5. **Honest empty states.** "No matches" is a real outcome, not a failure. Tell the user what to change.

### 2.3 Anti-principles (explicit non-goals)

- Not a recipe magazine. No editorial content, no "trending today," no curation.
- Not a meal planner. No calendars, no shopping integrations.
- Not a social product. No accounts, follows, likes, saves-to-board.
- Not a nutrition tracker. Calories shown if in dataset; never computed.

---

## 3. Target User & Jobs to be Done

### 3.1 Primary persona

**The constrained cook.** Has 5–15 ingredients in the fridge, 30–45 minutes of time, and doesn't want to go shopping. Knows how to cook but isn't looking for a project. The fridge contents change weekly; the app gets re-used.

### 3.2 Jobs to be done

| When... | I want to... | So I can... |
|---|---|---|
| I open the fridge at 6pm | quickly see what's cookable | avoid takeout |
| I have an odd ingredient (leftover ricotta) | find recipes that actually use it | not throw it out |
| I'm one or two items short of a recipe I like | see what I'd need | decide if it's worth a corner-store run |
| I'm midway through cooking | reference the recipe hands-free | keep both hands on the knife |

These jobs drive every feature decision below. If a feature doesn't serve one of these jobs, it doesn't ship.

---

## 4. User Stories

Ship three user stories (US-1, US-2, US-3 are the headline trio). The rest are documented but optional.

### 4.1 Core (must ship)

**US-1 — Search from my pantry**
> As a home cook, I want to enter the ingredients I have so I can see what I can cook tonight.

**Acceptance criteria**
- Tag-style input accepts multiple ingredients (chip UI, Enter or comma commits).
- Suggestions appear as I type, sourced from the top ~500 ingredients by usage.
- Selected ingredients persist across page loads via cookie (no auth required).
- Empty submission shows a helpful prompt, not an error.
- Submitting the form updates the URL (shareable, bookmarkable).
- The same query produces stable results (idempotent ordering).

**US-2 — See the gap clearly**
> As a user, I want recipes ranked so the ones requiring the fewest extra ingredients appear first, with the missing items shown by name.

**Acceptance criteria**
- Each result shows: title, image, total time, "X of Y ingredients" badge, missing ingredients listed inline (up to 3, then "+N more").
- A toggle filters to "Only show recipes I can fully cook."
- A slider/filter caps maximum missing ingredients (e.g. "show recipes within 2 ingredients of my pantry").
- Sort options: best match (default), quickest, highest rated.
- The ranking algorithm is documented in the README.

**US-3 — Cook the recipe**
> As a user, I want to open a recipe and follow it through to a finished dish.

**Acceptance criteria**
- Detail page renders complete ingredient list with quantities and units.
- Missing ingredients are visually distinct from ones the user has.
- Instructions render as a numbered, step-by-step list.
- A "cook mode" toggle enlarges text, hides chrome, prevents screen sleep where supported, and lets the user check off steps.
- Source URL is linked (credit to allrecipes.com).
- Total time, prep time, cook time, and yield are visible at a glance.

### 4.2 Extended (ship if §28 phases 1–6 are complete)

**US-4 — Reuse my pantry**
> As a returning user, I want my pantry to be remembered so I don't have to re-enter it every visit.
- Cookie-based persistence, no account required.
- Clear-pantry action available.

**US-5 — Build a shopping list from a near-match**
> As a user looking at a recipe I'm two items short on, I want to add those missing items to a printable list.
- "Add missing to list" button on result cards and detail page.
- List page printable, copyable to clipboard.
- List persists in cookie alongside pantry.

**US-6 — Refine by dietary need**
> As a user with dietary constraints, I want to exclude recipes containing certain ingredients.
- Exclusion input on the search page ("avoid: peanuts, shellfish").
- Filters compose with the pantry match.

### 4.3 Out of scope (documented for the interview)

User accounts. Personal recipe uploads. Comments. Ratings (we *display* the scraped rating but don't accept new ones). Meal calendars. Macros/calorie computation. Image uploads. Translations of recipes themselves.

---

## 5. User Flows

### 5.1 Primary flow — first visit to cooked dish

```
Landing
  │
  ▼
Add ingredients (autocomplete) ──► Pantry chips visible
  │
  ▼
Submit
  │
  ▼
Results ranked by match
  │
  ├──► Filter to "fully cookable only"
  ├──► Adjust max-missing
  └──► Click a recipe
        │
        ▼
       Recipe detail
        │
        ├──► Enter cook mode (large type, step checkboxes)
        └──► Back to results (pantry preserved)
```

### 5.2 Returning-user flow
Pantry restored from cookie. Landing redirects to results if pantry non-empty.

### 5.3 Edge flows
- Zero results → suggest removing exclusions, lowering threshold, or showing "closest matches" (recipes within 4 ingredients).
- Slow query (>1s) → progressive render via Turbo Stream, show skeleton results first.
- Cookie cleared mid-session → graceful degradation, no errors.

---

## 6. Information Architecture

```
/                              Landing / pantry input
/recipes?ingredients=…         Ranked results
/recipes/:slug                 Recipe detail
/recipes/:slug/cook            Cook mode (distraction-free)
/pantry                        Manage saved pantry (extended)
/list                          Shopping list (extended)
/about                         How matching works + AI disclosure
/health                        JSON health check (uptime monitor)
```

URL design priorities:
- Pantry travels in query string (shareable links).
- Recipe URLs are slugs (`/recipes/sheet-pan-chicken-thighs-3829`), not raw IDs.
- Stable URLs — never break a recipe URL once shipped.

---

## 7. Visual Design System

This is the section reviewers will linger on. The brief here: the design must feel like a *kitchen instrument*, not a *food magazine*. Magazines sell the dish; instruments help you make it. The visual language should feel closer to a test-kitchen notebook or a thoughtful kitchen-aid app than to NYT Cooking or Bon Appétit.

### 7.1 Design thesis

> A precise, slightly utilitarian editorial design with a confident type voice and an unmistakable signature element: the **match meter**, a horizontal segmented bar showing pantry overlap as a primary recurring motif throughout the app.

The match meter is the thing this app is remembered by. Every other choice supports it.

### 7.2 What we are deliberately avoiding

These look templated and would weaken the design:
- Warm cream background (#F4F1EA) + terracotta + serif display (the generic AI default).
- "Hero recipe with overlapping text on a moody food photo" landing.
- Pinterest-style masonry grids.
- Pastel chip pills.
- Big rounded corners everywhere (12px+ on cards).

### 7.3 Color palette

A restrained, slightly unusual palette. Six named tokens. No gradients. No tints — every color is used at its specified value.

| Token | Hex | Role |
|---|---|---|
| `--ink`        | `#1A1A1A` | Primary text, hairlines, structural elements |
| `--paper`      | `#FAFAF7` | Page background — bone, not cream |
| `--paper-2`    | `#F2F1EC` | Secondary surface (cards), one step deeper |
| `--olive`      | `#5D6B3A` | Primary brand color — used on the match meter, CTAs, links |
| `--persimmon`  | `#D9542B` | Accent — exclusively for missing-ingredient indicators (i.e. action signals) |
| `--smoke`      | `#6B6B66` | Secondary text, meta information |

Color is functional. The persimmon is *only* used to indicate "you need this" — never decorative. This consistency is what makes the design legible without instruction.

**Dark mode** is documented but deferred. The palette is dark-mode-ready (ink/paper invert cleanly to a near-black + bone-on-black) but shipping dark mode is a phase 8 task.

### 7.4 Typography

Three faces, used with discipline. All available from Google Fonts (no licensing burden, deployable instantly).

| Role | Family | Notes |
|---|---|---|
| Display | **Fraunces** | Variable serif with optical sizing. Used at 32–96px for headings, recipe titles, and the landing hero. Soft slope (`-15`), high contrast (`100`), used at weight 500–700. |
| Body | **Inter** | Workhorse sans. Used at 15–18px for prose, UI labels, navigation. Weights 400/500/600. |
| Mono | **JetBrains Mono** | Used exclusively for ingredient quantities, units, and match-meter numerics. Weight 400. |

**Type scale** (modular, ratio 1.25):

| Token | Size | Use |
|---|---|---|
| `--text-xs`   | 12px | Captions, meta |
| `--text-sm`   | 14px | Secondary UI |
| `--text-base` | 16px | Body default |
| `--text-md`   | 18px | Body emphasis, primary UI |
| `--text-lg`   | 24px | Subheadings |
| `--text-xl`   | 32px | Section heads |
| `--text-2xl`  | 48px | Page heads |
| `--text-3xl`  | 72px | Landing hero |

Line-height: 1.5 for body, 1.1 for display. Letter-spacing: `-0.02em` for display, `0` for body, `0.04em` (uppercase) for eyebrows.

### 7.5 Spacing & layout

8px base grid. Spacing tokens: `4, 8, 12, 16, 24, 32, 48, 64, 96, 128`.

**Layout grid:** 12 columns, 24px gutters, max content width 1200px, side padding 24px (mobile) / 48px (desktop).

**Breakpoints:**
- `sm`: 640px (single column → comfortable reading)
- `md`: 768px (two-column recipe cards)
- `lg`: 1024px (three-column results, sidebar filters)
- `xl`: 1280px (four-column results on landing-page suggestions)

### 7.6 Border, shadow, radius

- Corners: 4px on cards, 2px on inputs/buttons, 0px on the match meter (it's a precise instrument, not a soft pill).
- Borders: 1px hairlines in `--ink` at 8% opacity.
- Shadows: used sparingly — only on the cook-mode floating bar and the autocomplete dropdown. `0 2px 12px rgba(26, 26, 26, 0.08)`.

### 7.7 The match meter (signature element)

This is the single most distinctive UI element. It appears on every result card and on the recipe detail page.

```
██████░░░░  4 / 6        ← four olive segments, two empty
```

- Horizontal stack of equal-width segments, one per recipe ingredient (excluding pantry staples).
- Filled segments use `--olive`. Empty segments use a 1px outline in `--ink` at 20% opacity.
- Numeric count in JetBrains Mono to the right.
- Segments are clickable on the detail page (hovering reveals the ingredient name in a tooltip).
- The bar reflows on resize but maintains a minimum segment width of 12px; for recipes with >12 ingredients, segments compress to 8px.

This is the moment the design earns its keep. Everything else is in service of making this bar legible.

### 7.8 Iconography

A minimal custom icon set, 24×24, 1.5px stroke, square caps, ink color. Six icons: search, plus, close, check, clock, external-link. Anything else is a label, not an icon. No icon font, no decorative icons.

### 7.9 Imagery

Recipe images come from the scraped dataset. Treatment:
- All images object-fit cover, 16:10 aspect ratio on cards, 21:9 on detail page hero.
- No filters, no rounded corners on hero, 4px corners on cards.
- Missing images get a hand-drawn SVG placeholder (a simple plate-and-utensils mark in `--ink`).
- Lazy-loaded below the fold.

### 7.10 Motion

Restrained. Three motions, defined and reused:

| Name | Duration | Easing | Use |
|---|---|---|---|
| `instant`  | 80ms  | `ease-out`    | Hover state changes |
| `precise`  | 200ms | `cubic-bezier(0.2, 0, 0, 1)` | Filter changes, sort changes |
| `expand`   | 300ms | `cubic-bezier(0.2, 0, 0, 1)` | Drawer/sheet open, autocomplete open |

`prefers-reduced-motion` collapses all to 0ms.

Animations to *avoid*: bouncing, scaling on hover (other than 2% on cards), shimmer skeletons (use solid blocks), and anything carousel-related.

### 7.11 Component inventory

Build these as `ViewComponent` classes. Each has a Lookbook preview.

- `TagInput` — the pantry input
- `IngredientChip` — selected ingredient pill (removable)
- `RecipeCard` — result card
- `MatchMeter` — the signature bar
- `MissingList` — inline list of missing ingredients
- `RecipeHero` — detail page header
- `IngredientList` — checkable list with quantity column
- `StepList` — numbered instructions, checkable in cook mode
- `Filter` — generic filter control (toggle, slider, select)
- `EmptyState` — reusable empty/error state
- `Pagination` — pagy-driven pagination control
- `Button` — three variants: primary (olive), secondary (outline ink), ghost
- `Eyebrow` — small uppercase label above section heads

### 7.12 Copy voice

Direct, plain, slightly understated. No exclamation marks. No "Hello, chef!" No empty marketing words like "delicious," "amazing," or "perfect."

Examples:
- ✅ "What's in your kitchen?"
- ❌ "Tell us what you have, and we'll find delicious recipes!"
- ✅ "No matches. Try removing an exclusion or raising the missing-ingredient limit."
- ❌ "Oops! We couldn't find any recipes 😢"
- ✅ "Add to shopping list"
- ❌ "Add these to my grocery cart!"

---

## 8. Page Specifications

### 8.1 Landing (`/`)

**Single job:** get ingredients into the pantry as fast as possible.

Layout (desktop):
```
┌────────────────────────────────────────────────┐
│  Recipe Finder                          About  │
├────────────────────────────────────────────────┤
│                                                │
│   Cook from what                               │
│   you already have.                            │  ← Display, 72px, Fraunces
│                                                │
│   ┌──────────────────────────────────────┐    │
│   │ + Add an ingredient…                 │    │  ← Tag input, focused on load
│   └──────────────────────────────────────┘    │
│                                                │
│   [eggs] [flour] [milk] [butter]               │  ← Selected chips
│                                                │
│   ┌────────────────┐                           │
│   │ Find recipes → │   847 recipes ready       │  ← Primary CTA
│   └────────────────┘                           │
│                                                │
│   Or start from a common pantry:               │
│   [Italian basics] [Baking] [Stir-fry]         │  ← Quick-start chips
│                                                │
└────────────────────────────────────────────────┘
```

Above the fold on every viewport. No scroll required to start.

### 8.2 Results (`/recipes`)

```
┌────────────────────────────────────────────────────┐
│ ← Recipe Finder           [eggs] [flour] [milk] +  │  ← Sticky pantry bar
├────────────────────────────────────────────────────┤
│                                                    │
│ 142 recipes match    Sort: Best match ▾            │
│                                                    │
│ ▢ Only show recipes I can fully cook               │
│ Max missing: ●───────○ 3                           │
│                                                    │
│ ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│ │ [recipe img] │  │ [recipe img] │  │ [img]      ││
│ │              │  │              │  │            ││
│ │ Pasta alla   │  │ Chocolate    │  │ Frittata   ││
│ │ carbonara    │  │ chip cookies │  │            ││
│ │              │  │              │  │            ││
│ │ ████████░░   │  │ ██████░░░░   │  │ ██████████ ││
│ │ 4/5 · 25min  │  │ 3/5 · 35min  │  │ 5/5 · 15m  ││
│ │              │  │              │  │            ││
│ │ Missing:     │  │ Missing:     │  │ Ready to   ││
│ │ pancetta     │  │ chocolate    │  │ cook       ││
│ │              │  │ chips, brown │  │            ││
│ │              │  │ sugar        │  │            ││
│ └──────────────┘  └──────────────┘  └────────────┘│
│                                                    │
│              ← 1 2 3 … 8 →                         │
└────────────────────────────────────────────────────┘
```

Filter changes update results in place via Turbo Streams. No full page reloads.

### 8.3 Recipe detail (`/recipes/:slug`)

```
┌────────────────────────────────────────────────────┐
│                                                    │
│           [Hero image, 21:9, no overlay]           │
│                                                    │
├────────────────────────────────────────────────────┤
│ EYEBROW · ITALIAN                                  │
│                                                    │
│ Pasta alla Carbonara                               │  ← Fraunces 48px
│                                                    │
│ A Roman classic. Egg, cheese, and cured pork —     │
│ no cream, ever.                                    │
│                                                    │
│ ⏱ 25 min   👥 4 servings   ★ 4.7                  │
│                                                    │
│ ██████████░░░  4 / 5 ingredients                   │  ← Match meter, large
│                                                    │
│ ┌───────────────────────┬───────────────────────┐ │
│ │ INGREDIENTS           │ INSTRUCTIONS          │ │
│ │                       │                       │ │
│ │ 400g  spaghetti       │ 1. Bring a large pot  │ │
│ │ 200g  pancetta  ⚠     │    of water to boil…  │ │
│ │ 4     large eggs      │                       │ │
│ │ 80g   pecorino        │ 2. Meanwhile, cube    │ │
│ │ ★     black pepper    │    the pancetta…      │ │
│ │                       │                       │ │
│ │ ⚠ = need to buy       │ ……                    │ │
│ │ ★ = pantry staple     │                       │ │
│ │                       │                       │ │
│ │ [Add missing to list] │                       │ │
│ │ [Start cook mode →]   │                       │ │
│ └───────────────────────┴───────────────────────┘ │
│                                                    │
│ Source: allrecipes.com ↗                          │
└────────────────────────────────────────────────────┘
```

### 8.4 Cook mode (`/recipes/:slug/cook`)

Distraction-free. Larger type. No nav. Wake-lock API to keep screen on. Steps checkable. Two-column on desktop (ingredients left, instructions right); stacked on mobile with a sticky ingredient drawer.

### 8.5 Empty states

Never just say "no results." Always:
1. State what happened.
2. Show the closest non-empty alternative if one exists.
3. Suggest one concrete action.

Example:
> No exact matches.
>
> The closest recipes need 3 more ingredients than you have.
> [Show closest matches] [Adjust filters]

### 8.6 Error states

- 404 → recipe-themed but not cute. "This page isn't on the menu. [Back to search]"
- 500 → "Something broke on our end. We've been notified. [Back to search]" (Sentry captured.)
- Slow query → Turbo Stream skeleton then real results.

---

## 9. Functional Requirements

### 9.1 Must ship

| ID | Requirement | Owner story |
|---|---|---|
| F-1 | Tag-style ingredient input with autocomplete | US-1 |
| F-2 | Ingredient autocomplete sourced from top 500 by usage | US-1 |
| F-3 | Pantry persists across page loads via cookie | US-1, US-4 |
| F-4 | Search returns ranked recipes via SQL (no in-memory sort) | US-2 |
| F-5 | Result card shows title, image, time, match meter, missing list | US-2 |
| F-6 | "Only fully cookable" toggle and max-missing slider | US-2 |
| F-7 | Sort by best match / quickest / highest-rated | US-2 |
| F-8 | Pagination (25 per page) | US-2 |
| F-9 | Recipe detail with full ingredient list, instructions, metadata | US-3 |
| F-10 | Visual differentiation of missing vs. owned vs. pantry-staple ingredients | US-3 |
| F-11 | Cook mode with checkable steps and wake-lock | US-3 |
| F-12 | Idempotent seed task from `recipes-en.json` | infra |
| F-13 | Health check endpoint for uptime monitor | infra |

### 9.2 Should ship if time allows

| ID | Requirement |
|---|---|
| F-14 | Shopping list (extended) |
| F-15 | Exclusion input ("avoid: peanuts") |
| F-16 | Quick-start pantry presets |
| F-17 | "Closest matches" fallback on zero results |

### 9.3 Won't ship (documented for interview)

User accounts, ratings submission, social sharing, recipe upload, comments, calorie computation, video, meal calendar.

---

## 10. Technical Architecture

### 10.1 Stack

| Layer | Choice | Why |
|---|---|---|
| Language | Ruby 3.3+ | Latest stable, performance improvements over 3.2 |
| Framework | Rails 8 | Solid Queue, Solid Cache, Propshaft default — fewer moving parts |
| Database | PostgreSQL 16 | `pg_trgm`, full-text search, generated columns |
| App server | Puma | Default, well-understood |
| Job runner | Solid Queue (DB-backed) | No Redis dependency |
| Cache | Solid Cache (DB-backed) | Same reasoning |
| Frontend | Hotwire (Turbo + Stimulus) | First-party, no SPA overhead |
| CSS | Tailwind CSS 3 via `tailwindcss-rails` | Constrained design tokens, no runaway custom CSS |
| Components | `view_component` gem | Testable, previewable via Lookbook |
| Component preview | Lookbook | Standard, well-maintained |
| Pagination | Pagy | Fast, light, no AR-pollution |
| Search query | Custom service object | Documented; no `ransack` to keep the algorithm visible |
| HTTP client (seed) | `down` + `oj` for streaming JSON | Memory-safe for the dataset |
| Testing | RSpec 6 + Capybara + factory_bot + faker | Industry standard |
| Static analysis | RuboCop (rails-omakase) + Brakeman + bundler-audit | Run in CI |
| Type checking | Sorbet `# typed: false` (optional, document only) | Don't ship unless mature |
| Error tracking | Sentry | Free tier sufficient |
| Uptime monitor | Better Uptime / UptimeRobot | Free tier |
| Deployment | Fly.io | Easiest Rails+PG deploy, free tier with hobby PG |
| Asset hosting | Fly app static + Cloudflare in front | Optional; default Fly is fine |

### 10.2 Layered architecture

```
app/
├── controllers/              # thin: parse params, call service, render
├── models/                   # AR models + scopes + simple methods
├── components/               # ViewComponent classes
├── views/                    # ERB templates, mostly component renders
├── services/                 # business logic: matching, scoring, normalization
│   ├── ingredient_normalizer.rb
│   ├── ingredient_parser.rb
│   ├── recipe_matcher.rb
│   └── recipe_scorer.rb
├── queries/                  # complex SQL composers
│   └── recipe_search_query.rb
├── forms/                    # form objects for non-model forms
│   └── pantry_search_form.rb
├── decorators/               # presenters (optional, only if needed)
├── jobs/                     # ActiveJob classes
│   ├── ingest_recipe_job.rb
│   └── recompute_usage_counts_job.rb
└── helpers/                  # tiny, no business logic
```

### 10.3 Patterns

- **Service objects.** One public class method `.call(...)`. No state on the class. Return a `Result` value object (`success?`, `value`, `error`).
- **Query objects.** Wrap composable SQL when scopes get unwieldy. Public `#relation` returns an `ActiveRecord::Relation` (chainable).
- **Form objects.** `ActiveModel::Model` classes for non-AR forms (the pantry search form). Validations live here.
- **View components.** Every reusable bit of UI. Components have unit tests and Lookbook previews.
- **No concerns.** Avoid. They obscure where logic lives. Prefer composition.

### 10.4 Folder discipline

- Service files match class names. No multi-class files.
- One model per file. AR callbacks discouraged; prefer explicit service calls.
- Tests mirror app structure 1:1.

---

## 11. Data Model

### 11.1 Schema

**`recipes`**
| Column | Type | Notes |
|---|---|---|
| `id` | `bigint` | pk |
| `source_url` | `string` | unique index, idempotency key |
| `slug` | `string` | unique index, e.g. `pasta-alla-carbonara-2839` |
| `title` | `string` | indexed |
| `description` | `text` | |
| `instructions` | `text` | stored as paragraph blocks separated by `\n\n` |
| `image_url` | `string` | |
| `total_time_minutes` | `integer` | nullable |
| `prep_time_minutes` | `integer` | nullable |
| `cook_time_minutes` | `integer` | nullable |
| `yields` | `string` | "4 servings" |
| `ratings` | `decimal(3,2)` | nullable |
| `ratings_count` | `integer` | default 0 |
| `category` | `string` | nullable, indexed |
| `cuisine` | `string` | nullable, indexed |
| `ingredient_count` | `integer` | denormalized; excludes pantry staples; used in scoring |
| `searchable_tsv` | `tsvector` | generated column from title + description |
| `created_at` / `updated_at` | `timestamp` | |

**`ingredients`**
| Column | Type | Notes |
|---|---|---|
| `id` | `bigint` | pk |
| `name` | `string` | unique, lowercase, normalized form |
| `display_name` | `string` | UI-friendly capitalization |
| `is_pantry_staple` | `boolean` | default false |
| `usage_count` | `integer` | denormalized, refreshed by job |
| `created_at` / `updated_at` | `timestamp` | |

**`recipe_ingredients`**
| Column | Type | Notes |
|---|---|---|
| `id` | `bigint` | pk |
| `recipe_id` | `bigint` | fk, indexed |
| `ingredient_id` | `bigint` | fk, indexed |
| `original_text` | `string` | raw line from dataset |
| `quantity` | `decimal(10,3)` | nullable |
| `unit` | `string` | nullable |
| `position` | `integer` | preserves order in the recipe |
| Composite unique | `(recipe_id, ingredient_id)` | |

### 11.2 Indexes

- `recipes(slug)` unique
- `recipes(source_url)` unique
- `recipes(total_time_minutes)` for sort
- `recipes(ratings)` for sort
- `recipes(ingredient_count)` for scoring
- GIN on `recipes.searchable_tsv` for fallback full-text
- `ingredients(name)` unique
- GIN trigram on `ingredients.name` (`pg_trgm`) for fuzzy match during seed
- `recipe_ingredients(ingredient_id, recipe_id)` composite — drives the match query
- `recipe_ingredients(recipe_id, position)` for ordered display

### 11.3 PostgreSQL extensions

- `pg_trgm` — fuzzy ingredient matching at seed time
- `unaccent` — handle accented characters in scraped data
- `citext` (optional) — for case-insensitive ingredient names if not normalizing aggressively

### 11.4 Generated columns

`recipes.searchable_tsv` as a `tsvector` generated from `title || ' ' || description`. Postgres maintains it; we don't.

---

## 12. Ingredient Matching Engine

This is the heart of the application. Treat it as a domain in its own right.

### 12.1 Two-phase design

**Phase A: Normalization (offline, at seed time).** Convert messy strings into canonical ingredient records.

**Phase B: Matching (online, per query).** Given a user's pantry, return ranked recipes via a single SQL query.

### 12.2 Phase A — Normalization

Input: `"1 1/2 cups finely chopped fresh cilantro leaves, divided"`
Output:
- canonical ingredient: `cilantro`
- quantity: `1.5`
- unit: `cup`
- original_text: `"1 1/2 cups finely chopped fresh cilantro leaves, divided"`

Pipeline:

1. **Tokenize.** Split into quantity tokens, unit tokens, descriptor tokens, core noun tokens.
2. **Parse quantity.** Handle fractions (`1/2`), mixed (`1 1/2`), ranges (`1-2`, take midpoint), descriptive (`a pinch`, `to taste`).
3. **Parse unit.** Match against a unit dictionary (cup, tbsp, tsp, g, kg, oz, lb, ml, l, pinch, dash, clove, bunch, can, slice, sprig, …).
4. **Strip descriptors.** Remove words from a maintained list: *fresh, dried, ground, chopped, finely, coarsely, minced, diced, sliced, peeled, large, medium, small, ripe, organic, optional, divided, to taste, freshly, plus more for serving, …*.
5. **Singularize + lowercase.**
6. **Alias-map.** Apply a small explicit map: `scallions → green onions`, `aubergine → eggplant`, `coriander leaves → cilantro`. Keep this map under 50 entries and document each.
7. **Fuzzy reuse.** If an existing ingredient has trigram similarity > 0.88, reuse it. Otherwise insert new.
8. **Pantry staple detection.** Match against a small explicit list (`salt, black pepper, water, oil, olive oil, butter, sugar, all-purpose flour`).

**Acceptable correctness target:** 90% of recipe lines normalize sensibly when sampled. Log all unparsed lines; ship with a known-issues list.

**Edge cases to handle explicitly:**
- "Salt and pepper to taste" → split into two `recipe_ingredients` rows, both pantry staples.
- "Olive oil, plus more for serving" → strip the "plus more" clause.
- "Optional: red pepper flakes" → store with a flag (optional column on `recipe_ingredients` if time, otherwise treat as required).
- "2 (14 oz) cans diced tomatoes" → ingredient: tomatoes, quantity: 2, unit: can.

### 12.3 Phase B — Matching SQL

Single query, no N+1, no in-memory filtering.

```sql
WITH pantry AS (
  SELECT unnest(ARRAY[:ingredient_ids]::bigint[]) AS ingredient_id
),
recipe_scores AS (
  SELECT
    r.id,
    r.ingredient_count AS total,
    COUNT(ri.id) FILTER (
      WHERE ri.ingredient_id IN (SELECT ingredient_id FROM pantry)
    ) AS matched
  FROM recipes r
  JOIN recipe_ingredients ri ON ri.recipe_id = r.id
  JOIN ingredients i         ON i.id = ri.ingredient_id
  WHERE i.is_pantry_staple = false
  GROUP BY r.id, r.ingredient_count
)
SELECT
  r.*,
  rs.matched,
  rs.total,
  (rs.total - rs.matched) AS missing,
  (rs.matched::float / NULLIF(rs.total, 0)) AS match_ratio
FROM recipe_scores rs
JOIN recipes r ON r.id = rs.id
WHERE rs.matched > 0
  AND (rs.total - rs.matched) <= :max_missing
ORDER BY missing ASC, match_ratio DESC, r.total_time_minutes ASC NULLS LAST
LIMIT :per_page OFFSET :offset;
```

### 12.4 Scoring tunables

Exposed in `config/matching.yml`:
- `pantry_staples`: explicit list
- `max_missing_default`: 3
- `match_ratio_minimum`: 0.2 (recipes below this never appear)
- `tiebreaker_priority`: `[missing, match_ratio, total_time]`

### 12.5 Documented trade-offs

| Decision | Trade-off |
|---|---|
| Boolean match (have / don't have) vs. fuzzy at query time | Boolean is fast and explainable. Fuzzy moves complexity to seed. |
| Single SQL vs. ES/OpenSearch | Single SQL keeps the stack at one dep. Sub-200ms achievable on this dataset. |
| Pantry staples as a flag vs. as a separate "always-have" set per user | Per-user is correct but requires accounts. Out of scope. |
| Excluding zero-match recipes | A `0/5` match is not useful. Saves render. |
| Tiebreaker on `total_time ASC` | Encodes the product principle: faster wins ties. |

---

## 13. Routes & API Surface

```ruby
Rails.application.routes.draw do
  root "pages#home"

  get "/recipes",         to: "recipes#index",  as: :recipes
  get "/recipes/:slug",   to: "recipes#show",   as: :recipe, constraints: { slug: /[^\/]+/ }
  get "/recipes/:slug/cook", to: "recipes#cook", as: :cook_recipe

  resource :pantry, only: [:show, :update, :destroy], controller: "pantry"
  resource :list,   only: [:show, :update, :destroy], controller: "shopping_list"

  get "/ingredients/autocomplete", to: "ingredients#autocomplete", defaults: { format: :json }

  get "/about",  to: "pages#about"
  get "/health", to: "pages#health", defaults: { format: :json }

  # Asset & error routes handled by Rails defaults
end
```

**API conventions:**
- All HTML responses are server-rendered.
- `ingredients/autocomplete` returns JSON: `[{ id, name, display_name, usage_count }]`.
- Turbo Stream responses on filter changes (`format: :turbo_stream`).

---

## 14. Frontend Architecture

### 14.1 Asset pipeline

- **Propshaft** (Rails 8 default) for static assets.
- **importmap-rails** for JavaScript — no Node build for JS.
- **tailwindcss-rails** for CSS — Tailwind CLI, no PostCSS pipeline.

Why this combo: minimal moving parts, no `node_modules` in dev unless explicitly needed.

### 14.2 Hotwire

**Turbo Drive** — site-wide. Page transitions feel instant.

**Turbo Frames** — used for:
- The autocomplete dropdown (lazy frame).
- Filter results (the result grid is a frame).

**Turbo Streams** — used for:
- Adding/removing pantry chips.
- Live result updates on filter change.
- Shopping list updates.

**Stimulus controllers** (kept minimal):

| Controller | Purpose |
|---|---|
| `tag_input` | Pantry input: keyboard, commit on Enter/comma, paste handling |
| `autocomplete` | Debounced ingredient suggestions |
| `pantry` | Manage cookie sync |
| `cook_mode` | Wake-lock, step checkboxes, scroll progress |
| `filters` | Submit form on change with debounce |
| `clipboard` | Copy shopping list |

### 14.3 Tailwind config

Custom design tokens in `tailwind.config.js`:

```js
theme: {
  extend: {
    colors: {
      ink: '#1A1A1A',
      paper: '#FAFAF7',
      'paper-2': '#F2F1EC',
      olive: '#5D6B3A',
      persimmon: '#D9542B',
      smoke: '#6B6B66',
    },
    fontFamily: {
      display: ['Fraunces', 'serif'],
      sans: ['Inter', 'system-ui', 'sans-serif'],
      mono: ['JetBrains Mono', 'monospace'],
    },
    fontSize: {
      xs: '12px',
      sm: '14px',
      base: '16px',
      md: '18px',
      lg: '24px',
      xl: '32px',
      '2xl': '48px',
      '3xl': '72px',
    },
    spacing: {
      // Use Tailwind's default 4px scale; do not add custom values.
    },
    borderRadius: {
      none: '0',
      sm: '2px',
      DEFAULT: '4px',
    },
  },
}
```

Plugins: `@tailwindcss/typography` for the recipe instructions prose. Nothing else.

### 14.4 CSS conventions

- Utility-first, component classes only when a pattern repeats 3+ times.
- No `@apply` chains longer than 4 utilities.
- No inline styles.
- Custom CSS lives in `app/assets/stylesheets/application.tailwind.css` under `@layer components`.

### 14.5 ViewComponent conventions

- One component per file.
- Slot-based composition (`renders_one`, `renders_many`) over heavy parameter lists.
- Every component has a Lookbook preview at `test/components/previews/`.
- Every component has a unit test asserting it renders without raising.

---

## 15. Performance Strategy

### 15.1 Budgets

| Metric | Budget |
|---|---|
| Search query p50 | < 100ms |
| Search query p95 | < 300ms |
| Result page TTFB | < 200ms |
| Result page LCP | < 1.5s |
| Recipe detail TTFB | < 150ms |
| First seed of full dataset | < 5 min |
| Re-seed (idempotent) | < 30s if data unchanged |

### 15.2 Database

- Composite index `(ingredient_id, recipe_id)` is the most important. Verified via `EXPLAIN ANALYZE` in the README.
- `ingredient_count` denormalized on `recipes` to avoid a second aggregate.
- `usage_count` on ingredients refreshed nightly via background job.
- `pg_stat_statements` enabled in production for query monitoring.

### 15.3 N+1 prevention

- `Bullet` gem in dev/test, raises on N+1.
- All result queries `includes(:recipe_ingredients, :ingredients)` where applicable.

### 15.4 Frontend

- Images: native `loading="lazy"`, explicit `width`/`height` to prevent CLS.
- Fonts: `font-display: swap`, preload Fraunces and Inter weights actually used.
- No JS framework. Hotwire + Stimulus only.
- Tailwind purges unused classes in production build.

### 15.5 Asset delivery

- Brotli + gzip via Fly's load balancer.
- Static asset cache headers: 1 year on hashed assets, no-cache on HTML.

---

## 16. Caching Strategy

Three layers:

1. **HTTP caching.** Recipe detail pages get `Cache-Control: public, max-age=3600, stale-while-revalidate=86400`. Result pages are not cached (query-dependent).

2. **Fragment caching.** Each `RecipeCard` component fragment-cached by `[recipe.cache_key_with_version, pantry_signature]`. Cache key includes the pantry signature so different pantries get different cached cards. Use Solid Cache.

3. **Russian-doll caching.** The result grid wraps individual card caches. Misses on individual cards still hit hot cards.

**Cache invalidation:** Recipes are versioned by `updated_at` (Rails default). Re-seeding bumps `updated_at`, invalidating relevant caches. No manual sweeping.

**Don't cache:** the autocomplete endpoint (already fast enough), the pantry cookie, anything user-specific.

---

## 17. Background Jobs

Solid Queue, DB-backed, no Redis.

| Job | Trigger | Purpose |
|---|---|---|
| `IngestRecipeJob` | seed task | Parse one recipe row, upsert |
| `RecomputeUsageCountsJob` | nightly cron | Refresh `ingredients.usage_count` |
| `WarmCacheJob` | post-deploy | Pre-render top 100 recipe detail pages |

Cron via `solid_queue`'s recurring schedule in `config/recurring.yml`.

The seed task enqueues `IngestRecipeJob` per recipe and waits for the queue to drain. This gives free parallelism and clean failure isolation.

---

## 18. Security Requirements

Even without auth, hold the bar:

- **CSRF:** Rails default (enabled).
- **Strong parameters** everywhere; no `params.permit!`.
- **SQL injection:** parameterized queries; never interpolate user input into raw SQL.
- **XSS:** Rails default HTML escaping; explicit `raw` only for trusted SVG markers.
- **Content Security Policy:** strict CSP via `config/initializers/content_security_policy.rb`. No inline scripts (Hotwire is compatible).
- **Rate limiting:** `rack-attack`. Limit autocomplete to 60 req/min/IP, search to 30 req/min/IP. Return 429 with a polite message.
- **Dependency scanning:** `bundler-audit` and `brakeman` in CI; fail the build on high-severity findings.
- **Secrets:** Rails credentials only. No secrets in env files committed to the repo.
- **Logging:** filter `password`, `token`, `secret` patterns (Rails default + a config block).
- **HTTPS only** in production; HSTS enabled.

---

## 19. Accessibility Requirements

Target: **WCAG 2.1 AA** across all pages.

| Concern | Approach |
|---|---|
| Semantic HTML | `<main>`, `<nav>`, `<article>`, `<section>`. No `<div>` for anything that has a semantic equivalent. |
| Form labels | Every input has a `<label>`. The tag input uses `aria-describedby` for help text. |
| Keyboard | Every interactive element reachable via Tab. Visible focus ring (no `outline: none` without a custom replacement). |
| Match meter | `role="img"` with `aria-label="Match: 4 of 5 ingredients"`. Don't make screen reader users count segments. |
| Color contrast | All text ≥ 4.5:1 against background. Verified with the Stark or Polypane checks. |
| Motion | `@media (prefers-reduced-motion: reduce)` disables all transitions. |
| Cook mode | Step checkboxes are real checkboxes, fully accessible. |
| Skip link | "Skip to results" link first in tab order on the results page. |
| Heading hierarchy | One h1 per page; no skipped levels. |
| Images | All `<img>` have alt text. Recipe hero alt is the recipe title. Decorative SVGs `aria-hidden="true"`. |

Test with: keyboard-only navigation walkthrough, NVDA or VoiceOver pass on the three core flows, automated axe-core check in system tests.

---

## 20. SEO & Structured Data

This isn't a public consumer product, but the bar is the bar.

- Per-page `<title>` and `<meta name="description">`.
- Open Graph tags on recipe pages (`og:title`, `og:image`, `og:description`).
- **Schema.org `Recipe`** JSON-LD on every detail page — properly populated `recipeIngredient`, `recipeInstructions`, `cookTime`, `prepTime`, `totalTime`, `recipeYield`, `image`, `name`, `description`. This is genuinely useful and shows attention.
- `robots.txt` allows everything; nothing to hide.
- XML sitemap of all recipe URLs, served at `/sitemap.xml`, regenerated by a job.
- Canonical tags on all pages.

---

## 21. Internationalization Readiness

We ship in English. We design as if we'll add languages.

- All UI strings in `config/locales/en.yml`. No raw strings in templates.
- Date/time/number formatting via `l()` and `number_with_delimiter`.
- The recipe content itself is not translated (the dataset is English-only); this is documented.
- Lang attribute on `<html>` set from `I18n.locale`.

---

## 22. Testing Strategy

The test pyramid:

```
        ▲
       ╱ ╲
      ╱E2E╲              5 system tests (Capybara + headless Chrome)
     ╱─────╲
    ╱ Req   ╲            ~25 request specs (one per route + variations)
   ╱─────────╲
  ╱  Unit     ╲          ~80 unit specs (services, queries, components, models)
 ╱─────────────╲
```

### 22.1 What gets tested

| Layer | Test type | Coverage |
|---|---|---|
| `IngredientNormalizer` | unit | extensive — 50+ examples covering the edge cases in §12.2 |
| `IngredientParser` | unit | quantity/unit parsing matrix |
| `RecipeScorer` | unit | scoring math, tiebreakers, exclusions |
| `RecipeSearchQuery` | unit | SQL generation, parameter binding |
| `Recipe`, `Ingredient`, `RecipeIngredient` | model | validations, scopes |
| Components | component | render without raise + key content present |
| Controllers | request | happy path + 404 + zero-results + invalid params |
| Flows | system | three core user stories, one per spec |
| Autocomplete | request | JSON shape, debounce-friendly |
| Match meter | component | aria-label correct for various ratios |

### 22.2 Tooling

- **RSpec 6** + `rspec-rails`.
- **Capybara** + `cuprite` (CDP) for system tests — faster than Selenium.
- **factory_bot** — factories for `recipe`, `ingredient`, `recipe_ingredient`, plus traits (`:with_image`, `:pantry_staple`).
- **faker** — random but deterministic fixtures.
- **vcr** — not needed since there's no external HTTP at request time. Used for seed-task tests against a fixture JSON.
- **shoulda-matchers** — model validation specs.
- **axe-core-capybara** — accessibility assertions in system specs.

### 22.3 Coverage targets

- Line coverage: ≥ 85% (simplecov).
- Branch coverage tracked but not gated.
- 100% of services and queries covered.

### 22.4 Fixtures

A `spec/fixtures/sample_recipes.json` containing 100 hand-picked recipes covering edge cases: missing fields, weird ingredient strings, very long ingredient lists, missing images, no time data.

---

## 23. CI/CD & DevOps

### 23.1 CI (GitHub Actions)

`.github/workflows/ci.yml`:

```yaml
jobs:
  lint:
    - rubocop
    - brakeman
    - bundler-audit
  test:
    - rspec (with PostgreSQL service)
    - simplecov uploaded as artifact
  assets:
    - tailwindcss build (smoke test)
```

All three jobs must pass on PR before merge. Tests parallelized when count justifies it.

### 23.2 Pre-commit (Lefthook)

`lefthook.yml`:

```yaml
pre-commit:
  parallel: true
  commands:
    rubocop:
      glob: "*.rb"
      run: bundle exec rubocop {staged_files}
    brakeman:
      run: bundle exec brakeman -q --no-pager
```

### 23.3 Environments

| Env | Purpose | Hosting |
|---|---|---|
| development | Local | `bin/dev`, PG via Docker or Postgres.app |
| test | CI + local test runs | PG service in GH Actions |
| staging (optional) | Pre-prod | Fly.io app, scaled to 0 when idle |
| production | The deployed app | Fly.io with managed PG |

### 23.4 Deployment

- `fly deploy` from main, manual trigger.
- Blue-green via Fly's rolling deploys.
- Migrations run via release command (`fly.toml` `deploy.release_command`).
- Database backups: Fly managed PG daily snapshots.

### 23.5 `fly.toml` highlights

- Min instances: 1 (avoid cold starts during interview).
- Memory: 512MB sufficient for Puma + Solid Queue.
- Health check at `/health` every 15s.

---

## 24. Observability

### 24.1 Logs

- Rails default JSON-formatted logs in production.
- Lograge enabled for one-line request logs.
- PII filtering on `pantry`, `ingredient_ids` if those ever go through query strings as identifiable (they don't here, but the filter is in place).

### 24.2 Metrics

- Request timing via Rails default + Lograge.
- Query timing via `pg_stat_statements`.
- Custom metric: time spent in `RecipeMatcher.call`, logged per request.

### 24.3 Errors

- Sentry SDK installed and configured.
- Uncaught exceptions tagged with controller + action.
- Release tracking via Sentry source maps.

### 24.4 Uptime

- Better Uptime monitor on `/health` every 60s, alerts via email.
- Status badge in README.

### 24.5 What the dashboard shows

A small `/about` page (or a section of it) shows live stats: total recipes, total ingredients, average match-time over the last hour. Demonstrates the system is working end-to-end.

---

## 25. Code Quality & Conventions

### 25.1 Style

- **RuboCop** with `rubocop-rails-omakase` as the base, plus `rubocop-rspec` and `rubocop-performance`.
- Two-space indent, double quotes, trailing commas in multi-line hashes/arrays.
- Method length ≤ 15 lines (RuboCop default).
- Class length ≤ 150 lines.

### 25.2 Naming

- Services: imperative verb + noun → `RecipeMatcher`, `IngredientNormalizer`.
- Queries: noun + `Query` → `RecipeSearchQuery`.
- Components: noun + `Component` → `RecipeCardComponent`.
- Jobs: imperative verb + `Job` → `IngestRecipeJob`.

### 25.3 Comments

- Code explains *how*. Comments explain *why*.
- No comment that restates the next line of code.
- Each service file opens with a 2-3 line YARD-style comment explaining the responsibility.

### 25.4 Git

- Conventional commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`).
- Atomic commits — each commit passes CI standalone.
- PR template enforces: description, screenshots for UI changes, tests added, manual verification steps.
- Squash-merge into main; preserve PR title as commit title.

### 25.5 Annotations

- `annotaterb` keeps model files annotated with current schema.
- ERD generated by `rails-erd` and committed to `docs/erd.png`.

---

## 26. Documentation Requirements

### 26.1 README

Required sections, in this order:

1. **Hero** — one-line description, screenshot/GIF, status badges (CI, uptime, version).
2. **Live URL.**
3. **Three user stories** from §4.1, copied verbatim.
4. **Quickstart** — `bundle`, `rails db:prepare`, dataset download command, `rails recipes:seed`, `bin/dev`.
5. **Architecture overview** — paragraph + ERD image + a layered architecture diagram.
6. **Design system** — palette swatches, font choices, link to Lookbook.
7. **Ingredient matching** — the §12 explanation in plain English with a worked example.
8. **Performance** — measured numbers (LCP, TTFB, p95 search time) with screenshots.
9. **Accessibility** — note about WCAG 2.1 AA, link to manual test notes.
10. **Trade-offs** — explicit list of "I would have done X if I had more time."
11. **AI tooling disclosure** — per §27.
12. **Testing** — how to run tests, coverage report.
13. **Deployment** — how it's deployed, how to deploy a fork.
14. **License** — MIT or similar.

### 26.2 `docs/`

- `docs/erd.png` — entity-relationship diagram.
- `docs/architecture.md` — deeper than the README architecture section.
- `docs/matching-algorithm.md` — the matching engine, including SQL and worked examples.
- `docs/decisions/` — Architecture Decision Records (ADRs), one per major call. Examples:
  - `001-rails-8.md`
  - `002-solid-queue-over-sidekiq.md`
  - `003-no-elasticsearch.md`
  - `004-tailwind-over-bootstrap.md`
  - `005-view-component-over-partials.md`

ADRs are 200–400 words each. Format: context, decision, consequences.

### 26.3 In-app documentation

- `/about` page explains the matching algorithm to end users in plain language.
- Tooltips on the match meter.

---

## 27. AI Tooling Protocol

The brief requires disclosure. Reviewers will probe it. Treat this as a deliverable.

### 27.1 What to track

A `docs/ai-usage.md` file maintained throughout the build. For each significant AI-assisted task:

```markdown
### [Task name]
**Tool:** Claude / Cursor / Copilot / ChatGPT
**What it did:** [specific output, e.g. "drafted the initial trigram migration"]
**What I changed:** [what you rewrote and why]
**How I validated:** [tests written, benchmarks run, manual checks]
```

### 27.2 Examples of acceptable disclosure

> **Ingredient parser regex**
> Tool: Claude
> What it did: Generated initial regex for quantity parsing (fractions, ranges, mixed numbers).
> What I changed: Rejected the first version because it failed on "1 ½" with a Unicode fraction. Rewrote to use a fraction lookup table after benchmarking three approaches.
> How I validated: 50 hand-picked test cases from the dataset, 100% pass after revision. Ran against 1000 random recipes, logged failures, added 6 more cases.

### 27.3 Examples of unacceptable disclosure

> "Used Claude for help throughout."

Specificity is the signal. Generic disclosure reads as either dishonesty or laziness; both are flagged.

### 27.4 Things to *not* use AI for

- Final commit messages (reviewers can tell).
- The README narrative voice (be the engineer in the room, not a chatbot).
- Architectural decisions you can't defend (if you can't explain why, don't ship it).

---

## 28. Phased Milestones

Roughly 2–3 days of focused work if you've shipped Rails before. The brief expects less; this spec aims higher.

### Phase 1 — Setup & deploy (3h)
- Rails 8 app, PostgreSQL, Tailwind, ViewComponent, Lookbook.
- Hello-world page deployed to Fly.io.
- CI green on an empty test suite.
- Sentry wired in dev (verify error capture).

### Phase 2 — Data model & ingestion (4h)
- Schema for `recipes`, `ingredients`, `recipe_ingredients`.
- `IngredientNormalizer` service with unit tests against 50 hand-picked lines.
- `recipes:seed` rake task running against a 100-recipe fixture.
- ADR documenting parser approach.

### Phase 3 — Matching engine (3h)
- `RecipeSearchQuery` with the single-SQL match.
- `RecipeScorer` service.
- Tests for the matching math, including edge cases.
- `EXPLAIN ANALYZE` documented in `docs/matching-algorithm.md`.

### Phase 4 — Core UI (5h)
- Design tokens in Tailwind config.
- Landing, results, detail pages built with ViewComponent.
- Match meter component built and tested.
- Hotwire for filter changes.
- Lookbook previews for all components.

### Phase 5 — Polish & extended features (4h)
- Cook mode.
- Pantry cookie persistence.
- Shopping list (if time).
- Exclusion filter (if time).
- All copy reviewed against §7.12.

### Phase 6 — Full seed & performance (3h)
- Seed the full dataset on production.
- Add indexes, verify p95 < 300ms.
- Fragment caching wired in.
- Background job recomputing usage counts.

### Phase 7 — Accessibility & SEO (2h)
- Manual a11y pass on all pages.
- Schema.org JSON-LD on detail pages.
- Sitemap generation.
- Meta tags audit.

### Phase 8 — Documentation & handover (2h)
- README finalized with screenshots.
- ADRs filled in.
- AI usage doc reviewed.
- Trade-off section honest and specific.

**Total: ~26h.** Realistic for 3 focused days.

---

## 29. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Ingredient parsing accuracy is worse than 90% | High | Medium | Build against a 100-recipe sample first, iterate before full seed. Ship with a known-issues log. |
| Search query is slow on full dataset | Medium | High | Profile in Phase 3 with the full dataset, not a sample. Add indexes early. Materialize columns if needed. |
| Deployment configuration eats hours | Medium | High | Deploy in Phase 1, before any real code. Catch infra issues immediately. |
| Scope creep into "nice to haves" | High | High | The Definition of Done in §30 is the gate. Anything not on it is post-ship. |
| Design becomes generic AI default | Medium | Medium | Re-read §7.2 weekly. The persimmon-on-bone palette and match meter are the differentiators — don't second-guess them. |
| Seed task times out on Fly free tier | Medium | Medium | Run seed locally against a hosted PG; or chunk the seed into idempotent batches. |
| Tests slow down development | Low | Medium | Cuprite over Selenium. Parallelize. Keep system specs to 5. |
| The dataset has unexpected structure | Medium | High | Spend Phase 2's first hour exploring the JSON in a console. Don't write parsers blind. |

---

## 30. Definition of Done

Before considering the project shippable to the interview:

**Functionality**
- [ ] All F-1 through F-13 in §9.1 pass manual test on the deployed URL.
- [ ] The three user stories in §4.1 demonstrable in under 90 seconds total.
- [ ] Cook mode works on mobile (tested on a real phone).

**Quality**
- [ ] CI green on main.
- [ ] Coverage ≥ 85%.
- [ ] Rubocop clean.
- [ ] Brakeman clean (no high-severity findings).
- [ ] Bundler-audit clean.
- [ ] Lighthouse score ≥ 90 on Performance, Accessibility, Best Practices, SEO for the home and detail pages.
- [ ] Axe-core a11y check passes in system specs.

**Design**
- [ ] Tailwind tokens match §7.3 / §7.4 exactly.
- [ ] Match meter renders on all card and detail views.
- [ ] All copy reviewed against §7.12 voice rules.
- [ ] Lookbook accessible at `/lookbook` (or documented as dev-only).

**Performance**
- [ ] p95 search query < 300ms in production (measured, not assumed).
- [ ] LCP on results page < 1.5s.
- [ ] No N+1 queries (Bullet clean).

**Documentation**
- [ ] README covers all 14 sections in §26.1.
- [ ] At least 5 ADRs in `docs/decisions/`.
- [ ] `docs/ai-usage.md` complete and specific.
- [ ] ERD generated and committed.

**Operational**
- [ ] App deployed and accessible at a working URL.
- [ ] Uptime monitor green.
- [ ] Sentry receiving events (test event sent).
- [ ] `/health` returns 200.
- [ ] Backup of production DB verified (one snapshot exists).

**Hygiene**
- [ ] No commented-out code.
- [ ] No `binding.pry` or `byebug` calls.
- [ ] No TODO comments without a linked issue.
- [ ] Repo includes `.editorconfig`, `.ruby-version`, `.nvmrc` (if any JS tooling).
- [ ] License file present.

---

## 31. Future Roadmap

Document but do not build. Shows you've thought past the deadline.

### v0.2 — Personalization (post-interview)
- User accounts (Devise or Rails 8's built-in authentication).
- Per-user pantry persistence on the server.
- Per-user pantry-staple customization.
- Favorited recipes.

### v0.3 — Smarter matching
- Trigram fuzzy match at query time for typo tolerance.
- Synonym graph (learning from "didn't find what I expected" feedback).
- Substitution suggestions ("you have yogurt; you can substitute it for buttermilk").

### v0.4 — Multi-source
- Ingest from multiple recipe sources, deduplicate.
- Source attribution and quality scoring.

### v0.5 — Voice + hands-free
- Cook mode dictation: "next step," "repeat."
- Browser SpeechRecognition API, no third-party dep.

### v1.0 — Mobile
- PWA install prompt, offline-cache the user's pantry and last-viewed recipes.
- Native share sheet integration.

---

## Appendix A — Glossary

- **Pantry** — the set of ingredients the user has marked as available.
- **Pantry staple** — an ingredient assumed to always be available (salt, pepper, water, oil, butter, sugar, flour). Excluded from matching denominator.
- **Match meter** — the segmented horizontal bar showing matched / total ingredients for a recipe.
- **Match ratio** — `matched / total` (excluding staples).
- **Missing** — `total - matched`. The lower, the better the match.
- **Canonical ingredient** — the normalized form (lowercase, singular, descriptor-free) stored in `ingredients.name`.

## Appendix B — Reference data

- **Dataset:** `https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz`
- **Expected dataset size:** ~50–80MB uncompressed, ~20,000+ recipes.
- **Source:** `allrecipes.com` via `recipe-scrapers`.
- **License:** Recipes are linked back to source; we don't claim authorship. Always show source URL on detail page.

## Appendix C — Local development

```bash
# Prerequisites
asdf install   # or rbenv / rvm — ensure Ruby 3.3+

# Setup
bundle install
yarn install   # only if any JS deps
rails db:prepare

# Seed
curl -O https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz
gzip -dc recipes-en.json.gz > db/seeds/recipes-en.json
rails recipes:seed

# Run
bin/dev   # starts Puma, Tailwind watcher, Solid Queue
```

---

*End of specification.*
