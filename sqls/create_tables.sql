-- ============================================================
--  Kindle Diary – Supabase Database Setup
--  Run this script in the Supabase SQL Editor
-- ============================================================

-- 1. Create the diary_entries table
CREATE TABLE IF NOT EXISTS diary_entries (
    id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    title      TEXT        NOT NULL DEFAULT '',
    content    TEXT        NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 2. Index for fast chronological listing
CREATE INDEX IF NOT EXISTS idx_diary_entries_created_at
    ON diary_entries (created_at DESC);

-- 3. Enable Row Level Security
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

-- 4. Policy: allow all operations via the public (anon) key
--    (personal device – no per-user auth required)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'diary_entries'
          AND policyname = 'anon_all'
    ) THEN
        CREATE POLICY "anon_all" ON diary_entries
            FOR ALL
            TO anon
            USING (true)
            WITH CHECK (true);
    END IF;
END;
$$;

-- 5. Function: keep updated_at current on every UPDATE
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 6. Trigger: fire the function before each UPDATE row
DROP TRIGGER IF EXISTS set_updated_at ON diary_entries;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON diary_entries
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();
