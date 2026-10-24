-- =====================================================================
-- MAKTAB-E-KHALEEL — 100% RE-RUNNABLE (IDEMPOTENT) SUPABASE SQL SCRIPT
-- Safe to run multiple times in Supabase SQL Editor without 42710 errors!
-- =====================================================================

-- 1. Enable pgcrypto for password / recovery-code hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Main Tables (Section 8.1)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    mobile TEXT,
    role TEXT NOT NULL CHECK (role IN ('owner', 'staff')) DEFAULT 'staff',
    designation TEXT DEFAULT 'Ustad / Teacher',
    monthly_salary NUMERIC(12,2) DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
    recovery_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique case-insensitive username index (Section 8.2)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower ON public.profiles (LOWER(username));

CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roll_no TEXT,
    student_name TEXT NOT NULL,
    guardian_name TEXT NOT NULL,
    parent_mobile TEXT,
    class_level TEXT NOT NULL,
    monthly_fee NUMERIC(10,2) NOT NULL DEFAULT 500,
    joining_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'archived', 'paused')) DEFAULT 'active',
    notes TEXT DEFAULT '',
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_students_status ON public.students (status);

CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Present', 'Absent', 'Not Marked')) DEFAULT 'Not Marked',
    whatsapp_status TEXT NOT NULL CHECK (whatsapp_status IN ('Not Sent', 'Send Later', 'Sent')) DEFAULT 'Not Sent',
    marked_by UUID REFERENCES public.profiles(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, attendance_date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance (attendance_date);

CREATE TABLE IF NOT EXISTS public.fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    fee_month TEXT NOT NULL,
    amount_due NUMERIC(10,2) NOT NULL DEFAULT 0,
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('Paid', 'Partial', 'Pending')) DEFAULT 'Pending',
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Cash', 'UPI', 'Bank', 'Other')) DEFAULT 'Cash',
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT DEFAULT '',
    recorded_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fees_student_month ON public.fees (student_id, fee_month);

CREATE TABLE IF NOT EXISTS public.salary_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    salary_month TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Cash', 'UPI', 'Bank', 'Other')) DEFAULT 'Cash',
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT DEFAULT '',
    recorded_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.settings (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    maktab_name TEXT NOT NULL DEFAULT 'Maktab-E-Khaleel',
    tagline TEXT NOT NULL DEFAULT 'Smart Maktab Management System',
    address TEXT DEFAULT 'Secunderabad, Telangana, India',
    contact_mobile TEXT DEFAULT '+91 98480 00000',
    currency_symbol TEXT NOT NULL DEFAULT '₹',
    sunday_holiday BOOLEAN NOT NULL DEFAULT TRUE,
    default_monthly_fee NUMERIC(10,2) NOT NULL DEFAULT 500,
    whatsapp_template TEXT NOT NULL DEFAULT 'Assalamu Alaikum {guardian}, this is to inform you from {maktab} that your ward {student} ({class}) was marked Absent on {date}. Please inform the Maktab regarding the reason. JazakAllahu Khairan.',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    actor_name TEXT NOT NULL,
    actor_role TEXT NOT NULL,
    action_type TEXT NOT NULL,
    details TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Helper Security Functions (Section 7.2, 8.2, Appendix A)
CREATE OR REPLACE FUNCTION public.is_active_owner()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'owner' AND status = 'active'
    );
$$;

CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND status = 'active'
    );
$$;

-- Lookup email for active username (Section 7.2)
CREATE OR REPLACE FUNCTION public.get_login_email(p_username TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
BEGIN
    SELECT email INTO v_email
    FROM public.profiles
    WHERE LOWER(username) = LOWER(TRIM(p_username))
      AND status = 'active'
    LIMIT 1;
    RETURN v_email;
END;
$$;

-- Restricted First Owner Registration (Appendix A)
CREATE OR REPLACE FUNCTION public.create_initial_owner(
    p_full_name TEXT,
    p_username TEXT,
    p_mobile TEXT,
    p_recovery_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID;
    v_email TEXT;
    v_owner_exists BOOLEAN;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required to create initial owner.';
    END IF;

    SELECT EXISTS (SELECT 1 FROM public.profiles WHERE role = 'owner') INTO v_owner_exists;
    IF v_owner_exists THEN
        RAISE EXCEPTION 'An owner account already exists. Unrestricted second owner creation is blocked.';
    END IF;

    IF LENGTH(TRIM(COALESCE(p_full_name, ''))) < 2 THEN
        RAISE EXCEPTION 'Valid full name is required.';
    END IF;

    IF p_username !~ '^[a-zA-Z0-9_]{3,30}$' THEN
        RAISE EXCEPTION 'Username must be 3-30 characters (letters, numbers, underscore).';
    END IF;

    IF LENGTH(COALESCE(p_recovery_code, '')) < 6 THEN
        RAISE EXCEPTION 'Recovery code must be at least 6 characters.';
    END IF;

    IF EXISTS (SELECT 1 FROM public.profiles WHERE LOWER(username) = LOWER(p_username)) THEN
        RAISE EXCEPTION 'Username is already taken.';
    END IF;

    SELECT email INTO v_email FROM auth.users WHERE id = v_uid;

    INSERT INTO public.profiles (
        id, full_name, username, email, mobile, role, status, recovery_hash
    ) VALUES (
        v_uid,
        TRIM(p_full_name),
        TRIM(p_username),
        v_email,
        TRIM(p_mobile),
        'owner',
        'active',
        crypt(p_recovery_code, gen_salt('bf'))
    );

    INSERT INTO public.activity_logs (actor_id, actor_name, actor_role, action_type, details)
    VALUES (v_uid, TRIM(p_full_name), 'owner', 'OWNER_REGISTERED', 'Initial owner account created.');

    RETURN jsonb_build_object('success', true, 'role', 'owner');
END;
$$;

-- Verify Recovery Code (Section 7.4)
CREATE OR REPLACE FUNCTION public.verify_recovery_code(
    p_username TEXT,
    p_email TEXT,
    p_recovery_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hash TEXT;
BEGIN
    SELECT recovery_hash INTO v_hash
    FROM public.profiles
    WHERE LOWER(username) = LOWER(TRIM(p_username))
      AND LOWER(email) = LOWER(TRIM(p_email))
      AND status = 'active';

    IF v_hash IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN (v_hash = crypt(p_recovery_code, v_hash));
END;
$$;

-- Update Username / Recovery RPC Function (Supports Login & Recovery Username Changes)
CREATE OR REPLACE FUNCTION public.update_account_username(
    p_current_username TEXT,
    p_new_username TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF p_new_username !~ '^[a-zA-Z0-9_]{3,30}$' THEN
        RAISE EXCEPTION 'New username must be 3-30 characters (letters, numbers, underscore).';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.profiles
        WHERE LOWER(username) = LOWER(TRIM(p_new_username))
          AND id <> v_uid
    ) THEN
        RAISE EXCEPTION 'Username is already taken.';
    END IF;

    UPDATE public.profiles
    SET username = TRIM(p_new_username),
        updated_at = NOW()
    WHERE id = v_uid AND status = 'active';

    INSERT INTO public.activity_logs (actor_id, actor_name, actor_role, action_type, details)
    VALUES (v_uid, TRIM(p_new_username), 'user', 'CREDENTIALS_UPDATED', 'Username updated from ' || p_current_username || ' to ' || p_new_username);

    RETURN jsonb_build_object('success', true, 'new_username', TRIM(p_new_username));
END;
$$;

-- 4. Row Level Security (RLS) Policies (Section 9)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies first so this script can be re-run safely at any time!
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_owner_all ON public.profiles;
DROP POLICY IF EXISTS students_active_users ON public.students;
DROP POLICY IF EXISTS attendance_active_users ON public.attendance;
DROP POLICY IF EXISTS fees_owner_only ON public.fees;
DROP POLICY IF EXISTS salary_owner_only ON public.salary_payments;
DROP POLICY IF EXISTS settings_read_active ON public.settings;
DROP POLICY IF EXISTS settings_write_owner ON public.settings;
DROP POLICY IF EXISTS logs_insert_active ON public.activity_logs;
DROP POLICY IF EXISTS logs_select_owner ON public.activity_logs;

-- Profiles: Active users can read own profile; Owner can read/manage all profiles
CREATE POLICY profiles_select_own ON public.profiles FOR SELECT USING (id = auth.uid() AND status = 'active');
CREATE POLICY profiles_owner_all ON public.profiles FOR ALL USING (public.is_active_owner());

-- Students: Active staff & owner can view and manage operational student records
CREATE POLICY students_active_users ON public.students FOR ALL USING (public.is_active_user());

-- Attendance: Active staff & owner can view and mark attendance
CREATE POLICY attendance_active_users ON public.attendance FOR ALL USING (public.is_active_user());

-- Fees: STRICTLY OWNER ONLY (Staff cannot read or modify financial records)
CREATE POLICY fees_owner_only ON public.fees FOR ALL USING (public.is_active_owner());

-- Salary Payments: STRICTLY OWNER ONLY
CREATE POLICY salary_owner_only ON public.salary_payments FOR ALL USING (public.is_active_owner());

-- Settings: Active users can read basic settings; only Owner can update
CREATE POLICY settings_read_active ON public.settings FOR SELECT USING (public.is_active_user());
CREATE POLICY settings_write_owner ON public.settings FOR UPDATE USING (public.is_active_owner());

-- Activity Logs: Active users can insert logs; only Owner can view full audit history
CREATE POLICY logs_insert_active ON public.activity_logs FOR INSERT WITH CHECK (public.is_active_user());
CREATE POLICY logs_select_owner ON public.activity_logs FOR SELECT USING (public.is_active_owner());
