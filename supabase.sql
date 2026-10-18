-- Jalankan sekali di Supabase: SQL Editor > New query > tempel > Run

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

alter table products enable row level security;
alter table archive  enable row level security;
alter table site     enable row level security;
alter table orders   enable row level security;

-- Semua orang boleh MELIHAT produk, arsip, dan tampilan toko
drop policy if exists "baca produk"  on products;
drop policy if exists "baca arsip"   on archive;
drop policy if exists "baca tampilan" on site;
create policy "baca produk"   on products for select using (true);
create policy "baca arsip"    on archive  for select using (true);
create policy "baca tampilan" on site     for select using (true);

-- Hanya admin (pengguna yang login) boleh mengubah
drop policy if exists "admin produk"  on products;
drop policy if exists "admin arsip"   on archive;
drop policy if exists "admin tampilan" on site;
create policy "admin produk"   on products for all to authenticated using (true) with check (true);
create policy "admin arsip"    on archive  for all to authenticated using (true) with check (true);
create policy "admin tampilan" on site     for all to authenticated using (true) with check (true);

-- Pesanan: pembeli boleh membuat, hanya admin yang boleh membaca dan mengubah
drop policy if exists "pembeli buat pesanan" on orders;
drop policy if exists "admin pesanan" on orders;
create policy "pembeli buat pesanan" on orders for insert to anon, authenticated with check (true);
create policy "admin pesanan" on orders for all to authenticated using (true) with check (true);

-- Tempat penyimpanan foto dan video
insert into storage.buckets (id, name, public) values ('media', 'media', true)
  on conflict (id) do nothing;
drop policy if exists "media baca"  on storage.objects;
drop policy if exists "media tulis" on storage.objects;
drop policy if exists "media ubah"  on storage.objects;
drop policy if exists "media hapus" on storage.objects;
create policy "media baca"  on storage.objects for select using (bucket_id = 'media');
create policy "media tulis" on storage.objects for insert to authenticated with check (bucket_id = 'media');
create policy "media ubah"  on storage.objects for update to authenticated using (bucket_id = 'media');
create policy "media hapus" on storage.objects for delete to authenticated using (bucket_id = 'media');
