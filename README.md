# X — toko pakaian + dashboard admin

Situs statis (tanpa build). Toko untuk pembeli ada di alamat utama, dashboard admin di `/admin`.
Data produk, foto, dan video disimpan di **Supabase** (gratis), situs di-host di **Vercel**.
Pembayaran belum ada (checkout masih simulasi).

## Isi paket
- `index.html` — toko dan dashboard
- `admin.html` — pintu masuk dashboard (membuka `/admin`)
- `vercel.json` — pengaturan alamat bersih
- `config.js` — tempat mengisi data Supabase
- `supabase.sql` — pembuat tabel dan aturan keamanan
- `media/` — foto hero bawaan (`hero-pria.jpg`, `hero-wanita.jpg`). Video opsional: taruh `media/video.mp4`

## 1. Siapkan Supabase (sekali saja)
1. Daftar di supabase.com, lalu **New project**. Simpan kata sandi database-nya.
2. Buka **SQL Editor → New query**, tempel seluruh isi `supabase.sql`, klik **Run**.
3. Buka **Authentication → Users → Add user → Create new user**. Isi surel dan kata sandi Anda. Centang auto-confirm. Ini akun admin Anda.
4. Buka **Authentication → Sign In / Providers**, matikan **Allow new users to sign up** supaya orang lain tidak bisa mendaftar.
5. Buka **Project Settings → API**. Salin **Project URL** dan kunci **anon public**, lalu tempel ke `config.js`.

## 2. Unggah ke GitHub
1. Buat repository baru di github.com.
2. **Add file → Upload files**, seret semua isi folder ini (termasuk folder `media`), lalu **Commit changes**.

## 3. Pasang di Vercel
1. Di vercel.com klik **Add New → Project → Import** repository tadi.
2. Framework Preset: **Other**. Biarkan kolom Build Command dan Output Directory kosong. Klik **Deploy**.
3. Situs aktif di `nama-proyek.vercel.app`. Domain sendiri bisa ditambah di **Settings → Domains**.

## 4. Memakai dashboard
Buka `alamat-situs/admin` (tidak ada tautannya di toko, hanya Anda yang tahu), lalu masuk dengan akun tadi.
- **Produk**: klik *Impor produk contoh* sekali untuk mengisi contoh, lalu ubah atau hapus. Foto diunggah langsung dari komputer atau ponsel.
- **Kronologi**: kelola barang arsip untuk Pria dan Wanita. Pilih Untuk, Kategori (Siap Pakai, Sepatu, Tas, Aksesoris, Perhiasan), dan foto. Tiap kategori menjadi satu carousel di halaman Kronologi.
- **Tampilan**: ganti foto hero Pria dan Wanita serta video layar penuh. Ada dua kolom video: satu untuk laptop (lebar) dan satu khusus HP (potret 9:16).
- **Pesanan**: lihat pesanan masuk dan ubah statusnya.

## Catatan
- Ukuran file maksimal di Supabase gratis 50 MB. Untuk video, pakai mp4 sekitar 5–15 detik dan di bawah 20 MB. Foto sebaiknya di bawah 500 KB.
- Kunci `anon` boleh publik. **Jangan** pernah menaruh kunci `service_role` di file mana pun.
- Alamat pembeli tersimpan di tabel `orders` dan hanya bisa dibaca admin.
- Foto hero bawaan adalah karya seniman lain. Pastikan Anda punya izin memakainya, atau ganti lewat dashboard.
- Sebelum `config.js` diisi, toko tetap tampil dengan produk contoh, tetapi dashboard belum bisa dipakai.
- Pembayaran: belum ada. Saat siap, tambahkan Midtrans atau Xendit lewat fungsi server di Vercel (`/api`).
