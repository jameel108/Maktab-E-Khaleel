// Maktab-E-Khaleel — js/auth.js
// Handles username login lookup (get_login_email), Supabase Auth verification,
// session persistence, remember username, and account recovery.

async function loginWithUsernameAndPassword(username, password, rememberUsername = true) {
  const cleanUser = String(username || "").trim();
  if (!cleanUser || !password) {
    throw new Error("Username and password are required.");
  }

  // If connected to live Supabase project:
  if (window.supabaseClientInstance) {
    const { data: email, error: rpcError } = await window.supabaseClientInstance.rpc(
      "get_login_email",
      { p_username: cleanUser }
    );
    if (rpcError || !email) {
      throw new Error("Unknown or deactivated username.");
    }
    const { data: authData, error: authError } = await window.supabaseClientInstance.auth.signInWithPassword({
      email: email,
      password: password
    });
    if (authError) {
      throw new Error(authError.message || "Invalid credentials.");
    }
    if (rememberUsername) {
      localStorage.setItem("mk_remembered_username", cleanUser);
    } else {
      localStorage.removeItem("mk_remembered_username");
    }
    return authData;
  }

  // Local Demo fallback delegates to in-app handler
  return { demoMode: true, username: cleanUser };
}

window.MaktabAuth = { loginWithUsernameAndPassword };
