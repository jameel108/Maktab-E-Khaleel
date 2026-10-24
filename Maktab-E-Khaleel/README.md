# Maktab-E-Khaleel — Smart Maktab Management System

Complete Android-first Web Application / PWA built according to the **Maktab-E-Khaleel Complete Project Documentation (29 Sections + Appendices A & B)**.

## Project Structure (Section 5 & Appendix B)
- `index.html` — Complete application entry point (Login, First Owner Registration, Account Recovery, Dashboard, Students, Fast Attendance, Fees, Staff, Reports, Khaleel AI, and Settings)
- `owner-register.html` — Direct entry point to First Owner Registration
- `dashboard.html` — Direct entry point to the Dashboard Shell
- `css/style.css` — Neumorphic Dark-Blue & White theme + Near-Black Dark Mode styles
- `css/dashboard.css` — Dashboard layout, responsive cards, and print stylesheet
- `js/config.js` — Supabase frontend configuration (`SUPABASE_URL` & `SUPABASE_ANON_KEY`)
- `js/auth.js` — Username lookup (`get_login_email`), session management, and login logic
- `js/owner-register.js` — Initial owner validation & `create_initial_owner` RPC wrapper
- `js/dashboard.js` — Dashboard & operational module helpers
- `supabase_setup.sql` — Complete PostgreSQL schema, `pgcrypto` extension, security-definer functions (`get_login_email`, `create_initial_owner`, `verify_recovery_code`), and Row Level Security (RLS) policies
- `manifest.json` & `sw.js` — PWA installation & Android APK packaging readiness

## Running Locally (Visual Studio Code + Live Server)
1. Open this folder in **Visual Studio Code**.
2. Right-click `index.html` and choose **Open with Live Server** (or open `index.html` directly in any browser).
3. Use the 1-tap demo accounts (`khaleel_admin` for Owner, `ustad_imran` for Active Staff, `ustad_zaid` for Disabled Staff) or connect your Supabase project in `js/config.js` (or via the in-app **Demo DB / Supabase** button).
