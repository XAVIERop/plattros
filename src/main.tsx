import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "sonner";
import { ErrorBoundary } from "./components/ErrorBoundary";
import App from "./App";
import CheckIn from "./pages/CheckIn";
import Reviews from "./pages/Reviews";
import Landing from "./pages/Landing";
import Pricing from "./pages/Pricing";
import { Terms, Privacy, Refund } from "./pages/Legal";
import "./styles.css";

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ErrorBoundary>
    <QueryClientProvider client={queryClient}>
      <Toaster position="bottom-left" richColors closeButton duration={3000} />
      <BrowserRouter>
        <Routes>
          <Route path="/landing" element={<Landing />} />
          <Route path="/pricing" element={<Pricing />} />
          <Route path="/terms" element={<Terms />} />
          <Route path="/privacy" element={<Privacy />} />
          <Route path="/refund" element={<Refund />} />
          <Route path="/checkin/:restaurantId" element={<CheckIn />} />
          <Route path="/reviews/:restaurantId" element={<Reviews />} />
          <Route path="*" element={<App />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
    </ErrorBoundary>
  </React.StrictMode>
);
