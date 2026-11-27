-- Héritiers du Vide — skema + keamanan Supabase
-- CARA PAKAI: jalankan file ini SEKALI di Supabase Dashboard → SQL Editor → New query → Run.
-- File ini AMAN dijalankan ulang (semua pernyataan idempotent).
--
-- ⚠️ LANGKAH WAJIB SEBELUM RUN: ganti ADMIN_EMAIL di bawah dengan email login admin
-- Supabase Anda (akun di Authentication → Users). Kalau email ini salah, akun admin
-- TIDAK BISA menyimpan apa pun dari dashboard (toko tetap bisa dibaca pengunjung).
-- Perbaiki dengan menjalankan ulang file ini dengan email yang benar.
-- Juga pastikan "Allow new users to sign up" MATI di Authentication → Sign In /
-- Providers (sudah mati saat ini — jangan dihidupkan lagi), dan aktifkan MFA untuk
-- akun admin (Authentication → Users → akun admin → Factors).
--
-- Perubahan dari versi sebelumnya (27 Nov 2026, perbaikan bug hunt):
-- 1. "Admin" bukan lagi sembarang akun login: hanya akun dengan email di bawah.
-- 2. Produk yang disembunyikan tidak lagi bisa dibaca pengunjung lewat API.
-- 3. Pesanan palsu dibatasi server: status selalu dipaksa 'baru', waktu selalu
--    dari server, total/ongkir tidak boleh negatif, nomor pesanan harus unik.
-- 4. Upload file hanya gambar/video dan hanya oleh admin; file yang dihapus dari
--    produk ikut dihapus dari storage oleh aplikasi.
-- 5. Tabel audit_log: mencatat aksi "hapus semua" dari dashboard.

-- ===== Admin: hanya akun dengan email ini yang boleh menulis =====
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from auth.users
    where id = auth.uid()
      and email = 'halo@heritiersduvide.id'  -- <-- GANTI dengan email login admin
  );
$$;

-- ===== Tabel =====
create table if not exists products (
  id text primary key,
  g text not null default 'pria',
  c text not null default 'rtw',
  n text not null,
  p integer not null default 0,
  s text not null default 'tee',
  nw boolean not null default false,
  hidden boolean not null default false,
  d text, z text[], x text[], img text,
  created_at timestamptz not null default now()
);
create table if not exists archive (
  id text primary key,
  n text not null,
  p integer not null default 0,
  s text not null default 'tee',
  season text not null,
  img text,
  created_at timestamptz not null default now()
);
create table if not exists site (
  id text primary key,
  data jsonb not null default '{}'
);
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  no text, items jsonb, total integer, info jsonb, ship integer,
  status text not null default 'baru',
  ts bigint
);
create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  action text not null,
  target text,
  ts timestamptz not null default now()
);

alter table products enable row level security;
alter table archive  enable row level security;
alter table site     enable row level security;
alter table orders   enable row level security;
alter table audit_log enable row level security;

-- ===== Baca: pengunjung hanya melihat produk yang tidak disembunyikan =====
drop policy if exists "baca produk"  on products;
drop policy if exists "baca produk anon" on products;
drop policy if exists "baca produk admin" on products;
drop policy if exists "baca arsip"   on archive;
drop policy if exists "baca tampilan" on site;
create policy "baca produk anon"  on products for select to anon using (hidden = false);
create policy "baca produk admin" on products for select to authenticated using (true);
create policy "baca arsip"    on archive  for select using (true);
create policy "baca tampilan" on site     for select using (true);

-- ===== Tulis: hanya akun admin (lihat is_admin di atas) =====
drop policy if exists "admin produk"  on products;
drop policy if exists "admin arsip"   on archive;
drop policy if exists "admin tampilan" on site;
create policy "admin produk"   on products for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin arsip"    on archive  for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin tampilan" on site     for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ===== Pesanan: pembeli boleh membuat, hanya admin yang boleh membaca/mengubah =====
-- Total dan status tetap dihitung/dipaksa di server (lihat trigger di bawah).
drop policy if exists "pembeli buat pesanan" on orders;
drop policy if exists "admin pesanan" on orders;
create policy "pembeli buat pesanan" on orders for insert to anon, authenticated with check (true);
create policy "admin pesanan" on orders for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Nomor pesanan harus unik (mencegah duplikat dari client)
create unique index if not exists orders_no_unique on orders (no) where no is not null;

-- Status hanya boleh nilai yang dikenal; total/ongkir tidak boleh negatif
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'orders_status_valid') then
    alter table orders add constraint orders_status_valid check (status in ('baru','diproses','dikirim','selesai'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'orders_total_nonneg') then
    alter table orders add constraint orders_total_nonneg check (total is null or total >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'orders_ship_nonneg') then
    alter table orders add constraint orders_ship_nonneg check (ship is null or ship >= 0);
  end if;
end $$;

-- Trigger: paksa status 'baru' dan waktu server pada setiap pesanan baru,
-- apa pun yang dikirim client (mencegah status palsu 'selesai' dan timestamp palsu)
create or replace function public.orders_insert_guard()
returns trigger
language plpgsql
as $$
begin
  new.status := 'baru';
  new.ts := (extract(epoch from now()) * 1000)::bigint;
  if new.total is not null and new.total < 0 then
    raise exception 'total tidak boleh negatif';
  end if;
  if new.ship is not null and new.ship < 0 then
    raise exception 'ongkir tidak boleh negatif';
  end if;
  return new;
end;
$$;
drop trigger if exists orders_insert_guard on orders;
create trigger orders_insert_guard before insert on orders
for each row execute function public.orders_insert_guard();

-- ===== Audit: jejak aksi berbahaya dari dashboard =====
drop policy if exists "audit tulis" on audit_log;
drop policy if exists "audit baca" on audit_log;
create policy "audit tulis" on audit_log for insert to authenticated with check (true);
create policy "audit baca" on audit_log for select to authenticated using (public.is_admin());

-- ===== Tempat penyimpanan foto dan video =====
insert into storage.buckets (id, name, public) values ('media', 'media', true)
  on conflict (id) do nothing;
drop policy if exists "media baca"  on storage.objects;
drop policy if exists "media tulis" on storage.objects;
drop policy if exists "media ubah"  on storage.objects;
drop policy if exists "media hapus" on storage.objects;
create policy "media baca"  on storage.objects for select using (bucket_id = 'media');
create policy "media tulis" on storage.objects for insert to authenticated
  with check (bucket_id = 'media'
    and public.is_admin()
    and ((metadata ->> 'mimetype') like 'image/%' or (metadata ->> 'mimetype') like 'video/%'));
create policy "media ubah"  on storage.objects for update to authenticated using (bucket_id = 'media' and public.is_admin());
create policy "media hapus" on storage.objects for delete to authenticated using (bucket_id = 'media' and public.is_admin());
