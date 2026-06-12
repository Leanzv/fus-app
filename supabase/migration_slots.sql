-- ============================================================
-- FuS Migration: Venue Slots & Booking Update
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- ─── TABEL BARU: venue_slots ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.venue_slots (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_id     UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  day_of_week  INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  -- 1=Senin, 2=Selasa, 3=Rabu, 4=Kamis, 5=Jumat, 6=Sabtu, 7=Minggu
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  price        INT NOT NULL DEFAULT 0,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_time CHECK (end_time > start_time)
);

-- ─── UPDATE TABEL: bookings ───────────────────────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS slot_id      UUID REFERENCES public.venue_slots(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS booking_date DATE;

-- ─── INDEXES ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_slots_venue    ON public.venue_slots(venue_id);
CREATE INDEX IF NOT EXISTS idx_slots_day      ON public.venue_slots(day_of_week);
CREATE INDEX IF NOT EXISTS idx_bookings_slot  ON public.bookings(slot_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date  ON public.bookings(booking_date);

-- ─── RLS: venue_slots ────────────────────────────────────────
ALTER TABLE public.venue_slots ENABLE ROW LEVEL SECURITY;

-- Semua orang bisa lihat slot aktif
CREATE POLICY "slots_select_all"
  ON public.venue_slots FOR SELECT
  USING (true);

-- Hanya owner venue yang bisa insert slot
CREATE POLICY "slots_insert_owner"
  ON public.venue_slots FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

-- Hanya owner venue yang bisa update slot
CREATE POLICY "slots_update_owner"
  ON public.venue_slots FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

-- Hanya owner venue yang bisa hapus slot
CREATE POLICY "slots_delete_owner"
  ON public.venue_slots FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

-- ─── FUNCTION: cek slot tersedia ─────────────────────────────
-- Mengembalikan true jika slot tersedia untuk tanggal tertentu
CREATE OR REPLACE FUNCTION public.is_slot_available(
  p_slot_id     UUID,
  p_booking_date DATE
)
RETURNS BOOLEAN AS $$
DECLARE
  v_day_of_week INT;
  v_date_dow    INT;
  v_booked      BOOLEAN;
BEGIN
  -- Ambil day_of_week dari slot (1=Senin ... 7=Minggu)
  SELECT day_of_week INTO v_day_of_week
  FROM public.venue_slots
  WHERE id = p_slot_id AND is_active = true;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- Konversi tanggal ke day of week (ISODOW: 1=Senin ... 7=Minggu)
  v_date_dow := EXTRACT(ISODOW FROM p_booking_date)::INT;

  -- Pastikan hari cocok
  IF v_day_of_week != v_date_dow THEN
    RETURN FALSE;
  END IF;

  -- Cek apakah sudah ada booking confirmed/pending untuk slot+tanggal ini
  SELECT EXISTS (
    SELECT 1 FROM public.bookings
    WHERE slot_id = p_slot_id
      AND booking_date = p_booking_date
      AND status IN ('pending', 'confirmed')
  ) INTO v_booked;

  RETURN NOT v_booked;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
