# Recipe Matching Algorithm

## Overview

The matching algorithm answers: "Given the ingredients the user has, which recipes can they cook?"

It's a two-phase system:
1. **Normalization** (offline, at seed time): Raw ingredient strings → canonical ingredients
2. **Matching** (online, per query): User's pantry → ranked recipes

## Phase 1: Normalization

### Input
A raw ingredient line from a recipe:
```
"1 1/2 cups finely chopped fresh cilantro leaves, divided"
```

### Process

1. **Tokenize** the line into quantity, unit, descriptors, and core ingredient noun.
2. **Parse quantity**: "1 1/2" → 1.5 (handles fractions, ranges, mixed numbers).
3. **Parse unit**: "cups" → standardized unit token.
4. **Strip descriptors**: Remove ["finely", "chopped", "fresh", "divided", ...] from a maintained list.
5. **Singularize and lowercase**: "cilantro leaves" → "cilantro".
6. **Alias-map**: Apply explicit remapping (e.g., "scallions" → "green onions").
7. **Fuzzy match**: If a similar ingredient exists (trigram similarity > 0.88), reuse it. Else insert new.
8. **Pantry detection**: Check if the ingredient is on the pantry staple list.

### Output
```ruby
{
  original_text: "1 1/2 cups finely chopped fresh cilantro leaves, divided",
  quantity: 1.5,
  unit: "cup",
  ingredient_name: "cilantro",
  is_pantry_staple: false
}
```

### Pantry Staples (Excluded from Matching)

These are assumed always available:
- salt, black pepper, water
- oil, olive oil, butter
- sugar, all-purpose flour

**Rationale**: Recipes requiring 5–6 non-staple ingredients should be "fully cookable" for users with basic kitchen supplies. Staples don't count toward the missing-ingredient tally.

## Phase 2: Matching

### Input
- User's pantry: Array of ingredient IDs the user has (e.g., [42, 89, 156])
- Filters:
  - `max_missing`: Only show recipes within N ingredients of the pantry (default 3)
  - `only_cookable`: Show only fully cookable recipes (zero missing)
  - `exclusions`: Exclude recipes containing specific ingredients (e.g., "peanuts")
  - `sort_by`: "best_match" (default), "quickest", "highest_rated"

### SQL Query

```sql
WITH pantry AS (
  SELECT unnest(ARRAY[42, 89, 156]::bigint[]) AS ingredient_id
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
  JOIN ingredients i ON i.id = ri.ingredient_id
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
  AND (rs.total - rs.matched) <= 3  -- max_missing
ORDER BY missing ASC, match_ratio DESC, r.total_time_minutes ASC NULLS LAST
LIMIT 25 OFFSET 0;
```

### Output
Recipes ranked by:
1. **Missing count** (ascending): Recipes requiring the fewest extra ingredients appear first.
2. **Match ratio** (descending): Among recipes with the same missing count, show highest-coverage recipes.
3. **Total time** (ascending): Quickest recipes win ties (embodying the product principle: "make dinner fast").

### Example

User's pantry: [eggs, flour, milk, butter]

Recipe: Pasta Carbonara (needs eggs, pancetta, pecorino, black pepper, spaghetti)
- Total ingredients (non-staple): 4 (pancetta, pecorino, spaghetti — black pepper is staple)
- Matched: 1 (eggs)
- Missing: 3 (pancetta, pecorino, spaghetti)
- Match ratio: 1/4 = 0.25 = 25%

Ranking: 3 missing, 25% match → appears in results if `max_missing >= 3`.

## Indexes

Critical indexes for performance:

```sql
-- Composite index drives the main matching query
CREATE INDEX idx_recipe_ingredients_on_ingredient_and_recipe 
  ON recipe_ingredients(ingredient_id, recipe_id);

-- Sort/filter support
CREATE INDEX idx_recipes_on_total_time_minutes ON recipes(total_time_minutes);
CREATE INDEX idx_recipes_on_ratings ON recipes(ratings);
CREATE INDEX idx_recipes_on_ingredient_count ON recipes(ingredient_count);

-- Full-text fallback (future)
CREATE INDEX idx_recipes_searchable_tsv_gin ON recipes USING GIN(searchable_tsv);
```

## Performance Characteristics

Measured on ~20k recipes, ~3k unique ingredients:

- **Seed (first run)**: ~5 min (normalizes and inserts all recipes)
- **Reseed (unchanged data)**: ~30s (idempotent; most recipes already exist)
- **Search p50**: ~80ms (user enters pantry, results appear)
- **Search p95**: <300ms (even with deep filters)

See README for profiling method.

## Known Limitations

1. **Boolean matching, not fuzzy**: Typos in ingredient names don't resolve (e.g., "tomatoe" vs. "tomato"). Mitigated by autocomplete UI.
2. **No substitutions**: User can't say "use sour cream instead of yogurt." Mitigated by "exclusions" filter ("exclude recipes with yogurt").
3. **Quantity ignored in matching**: Whether the user has 1 cup or 10 cups of flour doesn't affect matching. This is intentional (interviews don't ask "how much do you have", only "do you have it").
4. **No user customization of staples**: All users assume the same pantry staples. Addressed in v0.2 when accounts ship.

## Future Improvements

- **Trigram fuzzy match** at query time for typo tolerance.
- **Ingredient graph** for substitutions ("yogurt" ↔ "sour cream").
- **User-defined staples** once authentication exists.
- **Dietary filters** (vegan, gluten-free) as metadata on recipes.
