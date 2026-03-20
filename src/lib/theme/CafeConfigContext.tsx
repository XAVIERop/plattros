import { createContext, useContext, type ReactNode } from "react";
import { formatCurrency as fmt, getCurrencySymbol } from "./useCafeBranding";

type CafeConfigContextValue = {
  formatCurrency: (amount: number) => string;
  currencySymbol: string;
};

const CafeConfigContext = createContext<CafeConfigContextValue>({
  formatCurrency: (n) => fmt(n, "INR"),
  currencySymbol: "₹",
});

export function CafeConfigProvider({
  children,
  currency = "INR",
}: {
  children: ReactNode;
  currency?: string;
}) {
  const value: CafeConfigContextValue = {
    formatCurrency: (amount) => fmt(amount, currency),
    currencySymbol: getCurrencySymbol(currency),
  };
  return (
    <CafeConfigContext.Provider value={value}>{children}</CafeConfigContext.Provider>
  );
}

export function useCafeConfig() {
  return useContext(CafeConfigContext);
}
