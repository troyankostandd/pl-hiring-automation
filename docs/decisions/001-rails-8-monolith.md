# ADR 001: Rails 8 Monolithic Architecture

## Context

Building a portfolio-grade recipe finder application that needs to demonstrate engineering judgment and clean architecture.

## Decision

Use Rails 8 as a monolithic server-rendered application with Hotwire for interactivity, rather than a separate API + frontend SPA.

## Rationale

- **Simplicity**: Single codebase, unified deployment, no service coordination complexity.
- **Portfolio value**: Demonstrates strong Rails fundamentals and opinionated patterns (ViewComponent, Solid Queue).
- **Time-to-market**: Server-rendered HTML with Hotwire is faster to iterate on than building an SPA.
- **Performance**: No JavaScript bundle size overhead; Turbo Drive handles page transitions.
- **SEO**: Server-rendered content is fully indexable without client-side rendering.

## Tradeoffs

- Can't reuse API across multiple client platforms (but that's not a requirement).
- Slightly more coupled than an API-first architecture (but architecture docs mitigate confusion).
- Scaling web tier requires careful database query optimization (mitigated by Solid Queue, indexes, caching).

## Status

Accepted

## Date

2026-06-21
