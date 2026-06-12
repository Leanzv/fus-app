-- ============================================================
-- FuS - Find ur Sport | Full Schema
-- Jalankan PERTAMA sebelum migration_slots.sql
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  email      TEXT NOT NULL,
  role       TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','owner')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- venues
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

-- reviews
CREATE TABLE IF NOT EXISTS public.reviews (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  venue_id   UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  rating     NUMERIC(2,1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment    TEXT DEFAULT '',
  image_url  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, venue_id)
);

-- bookings (dasar, akan di-update oleh migration_slots.sql)
CREATE TABLE IF NOT EXISTS public.bookings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  venue_id   UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  message    TEXT NOT NULL,
  status     TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_venues_owner   ON public.venues(owner_id);
CREATE INDEX IF NOT EXISTS idx_reviews_venue  ON public.reviews(venue_id);
CREATE INDEX IF NOT EXISTS idx_bookings_venue ON public.bookings(venue_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user  ON public.bookings(user_id);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venues   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- profiles policies
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- venues policies
CREATE POLICY "venues_select" ON public.venues FOR SELECT USING (true);
CREATE POLICY "venues_insert" ON public.venues FOR INSERT
  WITH CHECK (auth.uid() = owner_id AND EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'owner'));
CREATE POLICY "venues_update" ON public.venues FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "venues_delete" ON public.venues FOR DELETE USING (auth.uid() = owner_id);

-- reviews policies
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reviews_delete" ON public.reviews FOR DELETE USING (auth.uid() = user_id);

-- bookings policies
CREATE POLICY "bookings_select" ON public.bookings FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.venues WHERE id = venue_id AND owner_id = auth.uid()));
CREATE POLICY "bookings_insert" ON public.bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookings_update" ON public.bookings FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.venues WHERE id = venue_id AND owner_id = auth.uid()));

-- Auto-create profile trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name','Pengguna Baru'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role','user'))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('venues','venues',true),('reviews','reviews',true),('avatars','avatars',true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "storage_venues_select"  ON storage.objects FOR SELECT USING (bucket_id='venues');
CREATE POLICY "storage_venues_insert"  ON storage.objects FOR INSERT WITH CHECK (bucket_id='venues' AND auth.uid() IS NOT NULL);
CREATE POLICY "storage_reviews_select" ON storage.objects FOR SELECT USING (bucket_id='reviews');
CREATE POLICY "storage_reviews_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id='reviews' AND auth.uid() IS NOT NULL);
CREATE POLICY "storage_avatars_select" ON storage.objects FOR SELECT USING (bucket_id='avatars');
CREATE POLICY "storage_avatars_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id='avatars' AND auth.uid() IS NOT NULL);
