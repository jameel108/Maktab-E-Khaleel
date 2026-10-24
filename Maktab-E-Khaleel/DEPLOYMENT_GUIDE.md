# Maktab-E-Khaleel — Final Deployment & Database Setup Guide

## Phase 1: Supabase PostgreSQL & Auth Setup
1. Go to [https://supabase.com](https://supabase.com) and create a new free project named `Maktab-E-Khaleel`.
2. In the left sidebar, open **SQL Editor** → **New Query**.
3. Paste the entire contents of `supabase_setup.sql` (or click **Copy Full SQL Script** inside the app's **Demo DB** modal) and click **Run**.
4. In the left sidebar, open **Authentication** → **Providers** → **Email** and disable **"Confirm email"** for instant owner/staff onboarding (per Section 21 of the project documentation).
5. Go to **Project Settings** → **API** and copy:
   - **Project URL** (`https://xyz.supabase.co`)
   - **Project API Keys → `anon` `public` key** (Never use the `service_role` secret key in frontend code!).
6. Paste your URL and Anon Key into `js/config.js` (or directly in the app's **Demo DB** connection modal).

## Phase 2: Free Web Deployment (Vercel / Netlify / GitHub Pages)
1. Push the `Maktab-E-Khaleel` folder to a GitHub repository (or drag-and-drop the folder into Vercel / Netlify).
2. Connect the repository to **Vercel** (`vercel.json` is pre-configured).
3. Click **Deploy** — your HTTPS production URL will be live in ~15 seconds.

## Phase 3: Android PWA & APK Packaging (Section 24.2)
- **Option A (Direct PWA Install — Recommended Free-First Path)**: Open your deployed HTTPS URL in Chrome on Android, tap the browser menu (`⋮`), and select **Install App / Add to Home Screen**.
- **Option B (Conventional `.apk` Package)**: Enter your deployed HTTPS URL into **PWABuilder** (`https://www.pwabuilder.com`) or **Capacitor / WebView Wrapper** to generate a signed Android `.apk` for direct installation without requiring Google Play Store fees.
