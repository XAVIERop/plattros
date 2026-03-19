import { useCallback, useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";

interface SessionUser {
  id: string;
  email: string;
  fullName: string | null;
  role: string | null;
  cafeId: string | null;
}

interface Credentials {
  email: string;
  password: string;
}

export function useCafeSession() {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadUser = useCallback(async () => {
    setLoading(true);
    setError(null);

    const { data } = await supabase.auth.getUser();
    const currentUser = data.user;

    if (!currentUser) {
      setUser(null);
      setLoading(false);
      return;
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("full_name, user_type, cafe_id")
      .eq("id", currentUser.id)
      .maybeSingle();

    if (profileError) {
      setError(profileError.message);
    }

    setUser({
      id: currentUser.id,
      email: currentUser.email || "",
      fullName: profile?.full_name || null,
      role: profile?.user_type || null,
      cafeId: profile?.cafe_id || null
    });
    setLoading(false);
  }, []);

  useEffect(() => {
    void loadUser();
    const { data: listener } = supabase.auth.onAuthStateChange(() => {
      void loadUser();
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, [loadUser]);

  const signIn = useCallback(async ({ email, password }: Credentials) => {
    setError(null);
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password });
    if (signInError) {
      setError(signInError.message);
      throw signInError;
    }
    await loadUser();
  }, [loadUser]);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setUser(null);
  }, []);

  return {
    user,
    loading,
    error,
    signIn,
    signOut
  };
}
