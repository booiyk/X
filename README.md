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

## 1. Siapkan Supabase (sekali saja)
1. Daftar di supabase.com, lalu **New project**. Simpan kata sandi database-nya.
2. Buka **SQL Editor → New query**, tempel seluruh isi `supabase.sql`, klik **Run**.
3. Buka **Authentication → Users → Add user → Create new user**. Isi surel dan kata sandi Anda. Centang auto-confirm. Ini akun admin Anda. **Catat surelnya** — surel inilah yang harus diisi sebagai `ADMIN_EMAIL` di `supabase.sql` (lihat "Menerapkan perbaikan keamanan" di bawah).
4. Buka **Authentication → Sign In / Providers**, matikan **Allow new users to sign up** supaya orang lain tidak bisa mendaftar.
5. Buka **Project Settings → API**. Salin **Project URL** dan kunci **anon public**, lalu tempel ke `config.js`.

## 2. Unggah ke GitHub
1. Buat repository baru di github.com.
2. **Add file → Upload files**, seret semua isi folder ini, lalu **Commit changes**. (Tidak ada folder `media` di repo ini — foto hero dan video diatur lewat dashboard Supabase di menu Tampilan.)

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
- Foto hero bawaan adalah mockup kaos dari Pngtree. Pastikan Anda punya izin memakainya, atau ganti lewat dashboard.

## Menerapkan perbaikan keamanan (wajib, sekali saja)
Perbaikan bug 27 Nov 2026 mengubah `supabase.sql`. **Database live belum berubah** sampai langkah ini dilakukan — file di repo saja tidak cukup:
1. Buka `supabase.sql`, ganti `halo@heritiersduvide.id` di fungsi `is_admin()` dengan **surel login admin Supabase Anda** (akun dari langkah 1.3).
2. Buka **SQL Editor → New query**, tempel seluruh isi `supabase.sql`, klik **Run**.
3. Uji: masuk dashboard admin, ubah satu produk dan simpan. Kalau gagal menyimpan, surel di langkah 1 salah — ulangi dengan surel yang benar.
4. Aktifkan MFA untuk akun admin: **Authentication → Users → akun admin → Factors**.
5. Jangan hidupkan lagi "Allow new users to sign up".

Yang berubah di database: hanya akun admin yang boleh menulis; produk tersembunyi tidak bisa dibaca pengunjung; pesanan palsu dibatasi (status dipaksa 'baru', waktu dari server, nomor unik); upload hanya gambar/video oleh admin; aksi "hapus semua" tercatat di tabel `audit_log`.

## Perubahan 27 Nov 2026 (perbaikan bug, ronde 2)
- Halaman Wanita tidak lagi kosong: kalau Supabase belum punya produk wanita, katalog contoh wanita ikut tampil.
- Kronologi tidak lagi menggandakan item sampai 12x; tiap barang arsip tampil 1x per putaran carousel.
- Ukuran "habis" kini hanya dari data stok admin, bukan rumus acak.
- Kode diskon `X10` dihapus; kolom diskon di checkout dihapus.
- Tombol pembayaran cepat (Shop Pay/PayPal/Apple Pay/G Pay) yang tidak berfungsi dihapus; checkout kini jelas menyatakan pesanan dicatat dulu dan pembayaran dikonfirmasi manual, tombolnya "Buat pesanan".
- Video koleksi kini ada kontrolnya; fallback hero/video tidak lagi menunjuk file `media/` yang tidak ada di repo.
- Pencarian produk ditambahkan di halaman toko; footer dilengkapi tautan navigasi + surel; ditambahkan meta Open Graph; banner cookie tidak lagi menutupi footer.
- Keranjang produk asli tidak lagi terhapus saat halaman di-reload (dulu `drawCart` jalan sebelum data Supabase siap).
- Checkout tidak lagi "berhasil" saat Supabase tidak tersambung; checkout yang produknya sudah dihapus admin tidak lagi crash.
- Total tidak lagi tertulis "IDR Rp 225.000"; provinsi tidak lagi default Aceh (ada pilihan "Pilih provinsi", negara non-Indonesia memakai isian wilayah).
- Isian form checkout tidak lagi hilang saat jumlah diubah dari drawer; ukuran yang dipilih di halaman produk tidak lagi ke-reset saat data dimuat ulang; pilihan pembayaran dipertahankan kalau simpan gagal; data pembeli tidak lagi terbawa ke pesanan berikutnya.
- Keranjang divalidasi ulang ke server sebelum pesanan disimpan (produk dihapus/disembunyikan/berubah harga ditolak).
- Arsip kosong kini memakai data contoh (seperti produk); arsip format lama tidak lagi berubah gender saat disimpan; video gagal load kini bisa dicoba lagi; admin tidak bisa menyimpan produk tanpa nama seharga Rp 0; tipe barang tak dikenal tidak lagi tampil "undefined"; pencarian direset saat pindah gender.
- Keamanan: aturan akses diperketat (lihat "Menerapkan perbaikan keamanan"), script Supabase memakai SRI, ID produk di-escape di HTML, gambar rusak diganti placeholder, file di storage ikut terhapus saat referensinya dihapus, "hapus semua" tercatat di `audit_log`, katalog contoh diberi penanda.
- Layout: judul toko + pencarian bisa wrap di HP, carousel diberi fade di tepi, menu dropdown bisa dibuka dengan keyboard, kutipan boleh wrap di layar kecil, banner cookie tidak menutupi footer.
