// Maktab-E-Khaleel — js/owner-register.js
// Validates initial owner registration and invokes create_initial_owner(...) RPC (Appendix A).

async function registerInitialOwner({ fullName, username, email, mobile, password, confirmPassword, recoveryCode }) {
  if (!fullName || fullName.trim().length < 2) {
    throw new Error("Valid full name is required.");
  }
  if (!/^[a-zA-Z0-9_]{3,30}$/.test(username || "")) {
    throw new Error("Username must be 3–30 letters, numbers, or underscores.");
  }
  if (password !== confirmPassword) {
    throw new Error("Passwords do not match.");
  }
  if (!recoveryCode || recoveryCode.trim().length < 6) {
    throw new Error("Recovery code must be at least 6 characters.");
  }

  if (window.supabaseClientInstance) {
    // 1. Sign up user in Supabase Auth
    const { data: signUpData, error: signUpError } = await window.supabaseClientInstance.auth.signUp({
      email: email.trim(),
      password: password
    });
    if (signUpError) throw new Error(signUpError.message);

    // 2. Call secure security-definer function create_initial_owner
    const { data: rpcData, error: rpcError } = await window.supabaseClientInstance.rpc("create_initial_owner", {
      p_full_name: fullName.trim(),
      p_username: username.trim(),
      p_mobile: mobile.trim(),
      p_recovery_code: recoveryCode.trim()
    });
    if (rpcError) throw new Error(rpcError.message);
    return rpcData;
  }

  return { demoMode: true };
}

window.MaktabOwnerRegister = { registerInitialOwner };
