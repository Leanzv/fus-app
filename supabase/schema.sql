-- ============================================================
-- FuS - Find ur Sport
-- Supabase PostgreSQL Schema + RLS Policies
-- ============================================================

-- ─── EXTENSIONS ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── TABLE: profiles ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  email       TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'owner')),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── TABLE: venues ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.venues (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL,
  description TEXT DEFAULT '',
  latitude    DOUBLE PRECISION NOT NULL,
  longitude   DOUBLE PRECISION NOT NULL,
  image_url   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── TABLE: reviews ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reviews (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  venue_id   UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  rating     NUMERIC(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment    TEXT DEFAULT '',
  image_url  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, venue_id)  -- Satu user hanya bisa review satu venue sekali
);

-- ─── TABLE: bookings ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bookings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  venue_id   UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  message    TEXT NOT NULL,
  status     TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_venues_owner    ON public.venues(owner_id);
CREATE INDEX IF NOT EXISTS idx_venues_type     ON public.venues(type);
CREATE INDEX IF NOT EXISTS idx_reviews_venue   ON public.reviews(venue_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user    ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_venue  ON public.bookings(venue_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user   ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);

-- ─── ENABLE RLS ───────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venues   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- ─── RLS: profiles ───────────────────────────────────────────
-- Siapa saja bisa lihat profil (untuk menampilkan nama reviewer)
CREATE POLICY "profiles_select_all"
  ON public.profiles FOR SELECT USING (true);

-- Hanya user itu sendiri yang bisa insert/update profilnya
CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- ─── RLS: venues ─────────────────────────────────────────────
-- Semua user (termasuk yang belum login) bisa lihat venue
CREATE POLICY "venues_select_all"
  ON public.venues FOR SELECT USING (true);

-- Hanya owner yang bisa insert venue
CREATE POLICY "venues_insert_owner"
  ON public.venues FOR INSERT
  WITH CHECK (
    auth.uid() = owner_id AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'owner'
    )
  );

-- Hanya owner venue itu sendiri yang bisa update
CREATE POLICY "venues_update_own"
  ON public.venues FOR UPDATE
  USING (auth.uid() = owner_id);

-- Hanya owner venue itu sendiri yang bisa delete
CREATE POLICY "venues_delete_own"
  ON public.venues FOR DELETE
  USING (auth.uid() = owner_id);

-- ─── RLS: reviews ────────────────────────────────────────────
-- Semua orang bisa baca review
CREATE POLICY "reviews_select_all"
  ON public.reviews FOR SELECT USING (true);

-- User yang login bisa insert review
CREATE POLICY "reviews_insert_auth"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- User hanya bisa hapus review miliknya sendiri
CREATE POLICY "reviews_delete_own"
  ON public.reviews FOR DELETE
  USING (auth.uid() = user_id);

-- ─── RLS: bookings ───────────────────────────────────────────
-- User bisa lihat booking miliknya sendiri
CREATE POLICY "bookings_select_user"
  ON public.bookings FOR SELECT
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

-- User yang login bisa insert booking
CREATE POLICY "bookings_insert_auth"
  ON public.bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Owner venue bisa update status booking
CREATE POLICY "bookings_update_owner"
  ON public.bookings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

-- ─── TRIGGER: Auto-create profile on signup ───────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Pengguna Baru'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ─── VIEW: venue_with_stats (opsional, untuk query mudah) ─────
CREATE OR REPLACE VIEW public.venue_with_stats AS
SELECT
  v.*,
  COALESCE(AVG(r.rating), 0)::NUMERIC(3,2) AS average_rating,
  COUNT(r.id)::INT AS review_count
FROM public.venues v
LEFT JOIN public.reviews r ON r.venue_id = v.id
GROUP BY v.id;

-- ─── STORAGE BUCKETS (jalankan di Supabase Storage) ──────────
-- Buat bucket ini di Supabase Dashboard > Storage:
--   1. venues   (public)
--   2. reviews  (public)
--   3. avatars  (public)
--
-- Atau via SQL:
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('venues',  'venues',  true),
  ('reviews', 'reviews', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS untuk venues bucket
CREATE POLICY "venue_images_select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'venues');

CREATE POLICY "venue_images_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'venues' AND auth.uid() IS NOT NULL);

CREATE POLICY "venue_images_delete"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'venues' AND auth.uid() IS NOT NULL);

-- Storage RLS untuk reviews bucket
CREATE POLICY "review_images_select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'reviews');

CREATE POLICY "review_images_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'reviews' AND auth.uid() IS NOT NULL);

-- Storage RLS untuk avatars bucket
CREATE POLICY "avatar_images_select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatar_images_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid() IS NOT NULL);

CREATE POLICY "avatar_images_delete"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid() = (storage.foldername(name))[1]::uuid);
