-- Generic modifier groups and options for menu items
-- Replaces hardcoded coffee modifiers (size, milk, sugar) with backend-driven config

-- Modifier groups (e.g. Size, Milk, Sugar, Extra Shots)
CREATE TABLE IF NOT EXISTS public.modifier_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_required BOOLEAN NOT NULL DEFAULT false,
  min_selections INTEGER NOT NULL DEFAULT 1,
  max_selections INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_modifier_groups_cafe ON public.modifier_groups(cafe_id);

-- Modifier options (e.g. Small, Medium, Large; Regular, Skim, Soy)
CREATE TABLE IF NOT EXISTS public.modifier_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  modifier_group_id UUID NOT NULL REFERENCES public.modifier_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price_modifier DECIMAL(8,2) NOT NULL DEFAULT 0,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_modifier_options_group ON public.modifier_options(modifier_group_id);

-- Link menu items to modifier groups (many-to-many)
CREATE TABLE IF NOT EXISTS public.menu_item_modifier_groups (
  menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  modifier_group_id UUID NOT NULL REFERENCES public.modifier_groups(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (menu_item_id, modifier_group_id)
);

CREATE INDEX IF NOT EXISTS idx_menu_item_modifier_groups_menu ON public.menu_item_modifier_groups(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_menu_item_modifier_groups_group ON public.menu_item_modifier_groups(modifier_group_id);

-- RLS
ALTER TABLE public.modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modifier_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_modifier_groups ENABLE ROW LEVEL SECURITY;

-- Anyone can read modifier data (needed for POS)
CREATE POLICY "Anyone can read modifier groups" ON public.modifier_groups FOR SELECT USING (true);
CREATE POLICY "Anyone can read modifier options" ON public.modifier_options FOR SELECT USING (true);
CREATE POLICY "Anyone can read menu item modifier groups" ON public.menu_item_modifier_groups FOR SELECT USING (true);

-- Cafe staff can manage
CREATE POLICY "Cafe staff can manage modifier groups" ON public.modifier_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff
      WHERE cafe_staff.cafe_id = modifier_groups.cafe_id
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

CREATE POLICY "Cafe staff can manage modifier options" ON public.modifier_options
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.modifier_groups mg
      JOIN public.cafe_staff cs ON cs.cafe_id = mg.cafe_id
      WHERE mg.id = modifier_options.modifier_group_id
      AND cs.user_id = auth.uid()
      AND cs.role IN ('owner', 'manager')
      AND cs.is_active = true
    )
  );

CREATE POLICY "Cafe staff can manage menu item modifier groups" ON public.menu_item_modifier_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.menu_items mi
      JOIN public.cafe_staff cs ON cs.cafe_id = mi.cafe_id
      WHERE mi.id = menu_item_modifier_groups.menu_item_id
      AND cs.user_id = auth.uid()
      AND cs.role IN ('owner', 'manager')
      AND cs.is_active = true
    )
  );

COMMENT ON TABLE public.modifier_groups IS 'Modifier groups (Size, Milk, etc.) per cafe';
COMMENT ON TABLE public.modifier_options IS 'Options within a modifier group with optional price add-on';
COMMENT ON TABLE public.menu_item_modifier_groups IS 'Links menu items to applicable modifier groups';
