# ADR 002: Solid Queue Over Sidekiq for Background Jobs

## Context

Recipe ingestion and cache warming require background job processing. Need to choose a job queue.

## Decision

Use Solid Queue (Rails 8 database-backed job runner) instead of Sidekiq.

## Rationale

- **No Redis dependency**: Simplifies deployment and removes a moving part from the stack.
- **Rails 8 first-class support**: Part of the new Rails omakase stack; well-integrated with credentials and deployment.
- **Sufficient performance**: For ~20k recipes, database-backed job queue is fast enough.
- **Interview context**: Shows familiarity with modern Rails tooling, not just the "Redis + Sidekiq" default.

## Tradeoffs

- Slightly slower than Redis-backed Sidekiq for very high job volumes (not a constraint here).
- Requires database cleanup of old job records (handled via Solid Queue rake tasks).
- Less ecosystem of plugins (not needed for this scope).

## Status

Accepted

## Date

2026-06-21
