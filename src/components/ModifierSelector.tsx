import { useState } from "react";
import type { ModifierGroup } from "@/lib/menu/useCafeModifiers";

interface ModifierSelectorProps {
  groups: ModifierGroup[];
  selections: Record<string, string>;
  onChange: (selections: Record<string, string>) => void;
  productName: string;
  onAdd: (qty: number) => void;
  onClose: () => void;
}

export function ModifierSelector({
  groups,
  selections,
  onChange,
  productName,
  onAdd,
  onClose
}: ModifierSelectorProps) {
  const handleSelect = (groupId: string, optionId: string) => {
    onChange({ ...selections, [groupId]: optionId });
  };

  const [qty, setQty] = useState(1);

  const canAdd = groups.every((g) => {
    const selected = selections[g.id];
    if (g.isRequired && g.minSelections > 0) return !!selected;
    return true;
  });

  return (
    <div className="modifier-selector-overlay">
      <div className="modifier-selector-sheet">
        <header className="modifier-selector-header">
          <h3>{productName}</h3>
          <button type="button" className="ghost icon-only" onClick={onClose} aria-label="Close">
            ×
          </button>
        </header>
        <div className="modifier-selector-body">
          {groups.map((group) => (
            <div key={group.id} className="modifier-group">
              <div className="modifier-group-label">
                {group.name}
                {group.isRequired && <span className="required">*</span>}
              </div>
              <div className="modifier-options">
                {group.options.map((opt) => (
                  <button
                    key={opt.id}
                    type="button"
                    className={`ghost modifier-option ${selections[group.id] === opt.id ? "chip-active" : ""}`}
                    onClick={() => handleSelect(group.id, opt.id)}
                  >
                    {opt.name}
                    {opt.priceModifier > 0 && (
                      <span className="modifier-price">+AED {opt.priceModifier}</span>
                    )}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
        <footer className="modifier-selector-footer">
          <div className="modifier-qty">
            <button type="button" className="ghost" onClick={() => setQty(Math.max(1, qty - 1))}>
              −
            </button>
            <span>{qty}</span>
            <button type="button" className="ghost" onClick={() => setQty(qty + 1)}>
              +
            </button>
          </div>
          <button
            type="button"
            className="primary"
            disabled={!canAdd}
            onClick={() => onAdd(qty)}
          >
            Add to Cart
          </button>
        </footer>
      </div>
    </div>
  );
}
