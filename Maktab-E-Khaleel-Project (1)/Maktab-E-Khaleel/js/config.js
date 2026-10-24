// Maktab-E-Khaleel — js/config.js
// Supabase Frontend Client Configuration (Section 4.1, 24.1, Appendix B)
// Security Rule (Section 25): NEVER put service-role Supabase keys in frontend JavaScript.
// Only use your public SUPABASE_URL and SUPABASE_ANON_KEY (publishable key).

const MAKTAB_CONFIG = {
  SUPABASE_URL: "https://pzxupipbxlinyfwepcbn.supabase.co", // Paste your Supabase Project URL here when ready (e.g. "https://xyz.supabase.co")
  SUPABASE_ANON_KEY: "sb_publishable_JL5pxsTl7eYIz6wKg4BF6A_gPQPJSGg", // Paste your Supabase Anon/Publishable Key here when ready
  CURRENCY: "₹",
  DEFAULT_MAKTAB_NAME: "Maktab-E-Khaleel",
  SUNDAY_IS_HOLIDAY: true
};

// Initialize Supabase client if credentials are provided, else use local persistent DB mode
let supabaseClientInstance = null;
if (MAKTAB_CONFIG.SUPABASE_URL && MAKTAB_CONFIG.SUPABASE_ANON_KEY && window.supabase) {
  supabaseClientInstance = window.supabase.createClient(
    MAKTAB_CONFIG.SUPABASE_URL,
    MAKTAB_CONFIG.SUPABASE_ANON_KEY
  );
}
window.MAKTAB_CONFIG = MAKTAB_CONFIG;
window.supabaseClientInstance = supabaseClientInstance;
