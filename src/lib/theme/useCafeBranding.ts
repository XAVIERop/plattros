import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";

export interface CafeTheme {
  primaryColor?: string;
  logoUrl?: string;
  cafeName?: string;
  type?: string;
  description?: string;
  /** ISO 4217: INR, AED, USD. Used for POS display. */
  currency?: string;
}

/** Format amount with cafe currency. Use from useCafeBranding. */
export function formatCurrency(amount: number, currency: string = "INR"): string {
  const symbol = currency === "AED" ? "AED " : currency === "USD" ? "$" : "₹";
  const formatted = Math.round(amount).toLocaleString("en-IN", { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  return `${symbol}${formatted}`;
}

/** Currency symbol only (for labels like "Discount (AED)"). */
export function getCurrencySymbol(currency: string = "INR"): string {
  return currency === "AED" ? "AED" : currency === "USD" ? "USD" : "₹";
}

// Converts generic hex (#ff0000) to Tailwind's HSL component format (e.g. "0 100% 50%")
function hexToHsl(hex: string): string {
  let r = 0, g = 0, b = 0;
  if (hex.length === 4) {
    r = parseInt("0x" + hex[1] + hex[1]);
    g = parseInt("0x" + hex[2] + hex[2]);
    b = parseInt("0x" + hex[3] + hex[3]);
  } else if (hex.length === 7) {
    r = parseInt("0x" + hex[1] + hex[2]);
    g = parseInt("0x" + hex[3] + hex[4]);
    b = parseInt("0x" + hex[5] + hex[6]);
  }
  r /= 255;
  g /= 255;
  b /= 255;
  const cmin = Math.min(r, g, b),
        cmax = Math.max(r, g, b),
        delta = cmax - cmin;
  let h = 0, s = 0, l = 0;

  if (delta === 0) h = 0;
  else if (cmax === r) h = ((g - b) / delta) % 6;
  else if (cmax === g) h = (b - r) / delta + 2;
  else h = (r - g) / delta + 4;

  h = Math.round(h * 60);
  if (h < 0) h += 360;

  l = (cmax + cmin) / 2;
  s = delta === 0 ? 0 : delta / (1 - Math.abs(2 * l - 1));
  s = +(s * 100).toFixed(1);
  l = +(l * 100).toFixed(1);

  return `${h} ${s}% ${l}%`;
}

// Determines if text over this background should be dark or light
function getLuminanceFromHex(hex: string): number {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return 1;
  const r = parseInt(result[1], 16) / 255;
  const g = parseInt(result[2], 16) / 255;
  const b = parseInt(result[3], 16) / 255;
  // Per ITU-R BT.709
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function useCafeBranding(cafeId: string | null) {
  const [theme, setTheme] = useState<CafeTheme>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!cafeId) {
      setTheme({});
      document.documentElement.style.removeProperty('--primary');
      document.documentElement.style.removeProperty('--primary-foreground');
      setLoading(false);
      return;
    }

    async function fetchTheme() {
      setLoading(true);
      const { data, error } = await supabase
        .from("cafes")
        .select("name, primary_color, logo_url, type, description, currency")
        .eq("id", cafeId)
        .maybeSingle();

      if (!error && data) {
        setTheme({
          cafeName: data.name,
          primaryColor: data.primary_color,
          logoUrl: data.logo_url,
          type: data.type,
          description: data.description,
          currency: data.currency || "INR",
        });

        // Inject Tailwind variables globally
        if (data.primary_color && data.primary_color.startsWith('#')) {
          const hslComponent = hexToHsl(data.primary_color);
          const luminance = getLuminanceFromHex(data.primary_color);
          const fgHsl = luminance > 0.5 ? "240 5.9% 10%" : "0 0% 100%"; // dark text vs light text
          
          document.documentElement.style.setProperty('--primary', hslComponent);
          document.documentElement.style.setProperty('--primary-foreground', fgHsl);

          // Calculate a "dark" version for gradients/shadows (reduce L by 10%)
          const parts = hslComponent.split(' ');
          const h = parts[0];
          const s = parts[1];
          const l = parseFloat(parts[2]) - 10;
          document.documentElement.style.setProperty('--primary-dark', `${h} ${s} ${l}%`);
        }
      } else {
        setTheme({});
        document.documentElement.style.removeProperty('--primary');
        document.documentElement.style.removeProperty('--primary-foreground');
        document.documentElement.style.removeProperty('--primary-dark');
      }
      setLoading(false);
    }

    void fetchTheme();
  }, [cafeId]);

  const curr = theme.currency || "INR";
  const formatCurrencyFn = (amount: number) => formatCurrency(amount, curr);
  const currencySymbol = getCurrencySymbol(curr);
  return { theme, loading, formatCurrency: formatCurrencyFn, currencySymbol: currencySymbol };
}
