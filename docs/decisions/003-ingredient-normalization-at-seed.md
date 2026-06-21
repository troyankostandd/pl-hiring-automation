# ADR 003: Ingredient Normalization at Seed Time, Not Query Time

## Context

Recipe ingredient text ("1 1/2 cups finely chopped fresh cilantro") must be normalized to canonical ingredients ("cilantro"). Could happen either at seed time or at query time.

## Decision

Normalize at seed time. Store canonical ingredients and discard raw text after normalization.

## Rationale

- **Query performance**: Searching matches pre-normalized ingredients; no fuzzy matching overhead at query time.
- **Consistency**: Every recipe gets the same normalization pipeline; no divergence in behavior.
- **Simplicity**: Matching algorithm is straightforward SQL; no machine learning or fuzzy scoring complexity.
- **Failure isolation**: Bad recipes don't slow down good queries; errors are surfaced at seed time.

## Tradeoffs

- Normalization accuracy is locked at seed time; can't improve matching without re-seeding.
- Recipe ingredient lines lose their original descriptors (quantity, unit preserved; "finely chopped" lost).
- Can't support typo tolerance at query time without a second full-text index.

## Mitigation

- Document known normalization issues in ADR 003-supplement.
- Log all unparsed or ambiguous lines at seed time.
- Link to dataset issues / PRs if normalization is wrong for a specific recipe.

## Status

Accepted

## Date

2026-06-21
