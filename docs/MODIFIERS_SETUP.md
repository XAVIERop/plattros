# Generic Modifiers Setup

Modifier groups let you define customizable options (Size, Milk, Sugar, etc.) per cafe, instead of hardcoded coffee modifiers.

## Quick seed (recommended)

1. Edit `scripts/seed_modifier_groups.sql` and replace `YOUR_CAFE_ID` with your cafe UUID.
2. Run: `psql $DATABASE_URL -f scripts/seed_modifier_groups.sql`  
   (or run the script in Supabase SQL Editor)

This creates Size (Small/Medium/Large) and Milk (Regular/Skim/Soy/Oat) groups and links coffee items to Size.

## Schema

- **modifier_groups**: Groups like "Size", "Milk" (per cafe)
- **modifier_options**: Options within each group (e.g. Small, Medium, Large) with optional price add-ons
- **menu_item_modifier_groups**: Links menu items to modifier groups (many-to-many)

## Setup via SQL

```sql
-- 1. Create a modifier group (e.g. Size)
INSERT INTO modifier_groups (cafe_id, name, display_order, is_required, min_selections, max_selections)
VALUES ('YOUR_CAFE_ID', 'Size', 0, true, 1, 1)
RETURNING id;

-- 2. Add options (use the returned id as modifier_group_id)
INSERT INTO modifier_options (modifier_group_id, name, price_modifier, display_order, is_default)
VALUES
  ('GROUP_ID', 'Small', 0, 0, false),
  ('GROUP_ID', 'Medium', 20, 1, true),
  ('GROUP_ID', 'Large', 40, 2, false);

-- 3. Link menu items to the group
INSERT INTO menu_item_modifier_groups (menu_item_id, modifier_group_id)
SELECT id, 'GROUP_ID' FROM menu_items WHERE cafe_id = 'YOUR_CAFE_ID' AND category ILIKE '%coffee%';
```

## Behavior

- When a menu item has linked modifier groups, tapping it opens the **Modifier Selector** before adding to cart
- Items without modifiers add directly with default options
- Selections are stored in `order_items.special_instructions` as JSON
- Price = base price + sum of selected option `price_modifier` values
