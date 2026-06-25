<div align="center">

# FuS : Find ur Sport

**Aplikasi Mobile Pencarian Venue Olahraga Berbasis Lokasi**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*Temukan, booking, dan review venue olahraga terdekat dalam satu aplikasi*

</div>

---

## Daftar Isi

1. [Prasyarat](#prasyarat)
2. [Instalasi](#instalasi)
3. [Memulai Aplikasi](#memulai-aplikasi)
4. [Panduan Pengguna (User)](#panduan-pengguna-user)
5. [Panduan Pemilik Venue (Owner)](#panduan-pemilik-venue-owner)
6. [Fitur Lengkap](#fitur-lengkap)

---

## Prasyarat

Sebelum menjalankan aplikasi, pastikan perangkat memenuhi persyaratan berikut.

- Perangkat Android
- Koneksi internet aktif
- GPS atau layanan lokasi perangkat dalam kondisi aktif
- Izin lokasi diberikan kepada aplikasi saat diminta

---

## Instalasi

1. Unduh file APK aplikasi FuS
2. Buka file APK pada perangkat Android
3. Jika muncul peringatan instalasi dari sumber tidak dikenal, aktifkan izin tersebut melalui Pengaturan perangkat
4. Ikuti proses instalasi hingga selesai
5. Buka aplikasi FuS dari layar utama perangkat

---

## Memulai Aplikasi

### Registrasi Akun Baru

1. Buka aplikasi FuS
2. Pada halaman login, ketuk **Daftar** di bagian bawah layar
3. Isi formulir registrasi dengan data berikut:
   - Nama lengkap
   - Alamat email yang valid
   - Password
   - Pilih role akun: **User** (pencari venue) atau **Owner** (pengelola venue)
4. Ketuk tombol **Daftar** untuk menyelesaikan registrasi
5. Akun berhasil dibuat dan profil pengguna akan otomatis tersedia

### Login

1. Buka aplikasi FuS
2. Masukkan alamat email yang telah terdaftar pada kolom **Email**
3. Masukkan password pada kolom **Password**
4. Ketuk tombol **Masuk**
5. Aplikasi akan mengarahkan ke halaman utama sesuai role akun

### Logout

1. Buka tab **Profil** dari navigasi bawah
2. Gulir ke bawah dan ketuk menu **Keluar**
3. Sesi akan dihapus dan aplikasi kembali ke halaman login

---

## Panduan Pengguna (User)

### Menjelajahi Venue Olahraga

Setelah login, halaman **Beranda** menampilkan daftar venue olahraga terdekat dari posisi pengguna saat ini.

**Mencari venue berdasarkan nama:**
1. Ketuk kolom pencarian bertuliskan "Cari venue olahraga..." di bagian atas halaman Beranda
2. Ketik nama venue yang dicari
3. Daftar hasil pencarian akan muncul secara otomatis

**Memfilter venue berdasarkan jenis olahraga:**
1. Pada halaman Beranda, terdapat deret pilihan kategori di bawah kolom pencarian, seperti Semua, Futsal, Badminton, Basket, Renang, dan lainnya
2. Ketuk kategori yang diinginkan
3. Daftar venue akan diperbarui sesuai kategori yang dipilih
4. Ketuk **Semua** untuk kembali menampilkan seluruh venue

**Melihat detail venue:**
1. Ketuk kartu venue pada daftar di halaman Beranda
2. Halaman detail venue menampilkan foto, nama, jenis olahraga, deskripsi, lokasi, rating rata-rata, dan daftar ulasan

### Melakukan Booking Venue

1. Buka halaman detail venue yang ingin dibooking
2. Ketuk tombol **Booking**
3. Pada halaman Booking Venue, pilih tanggal yang diinginkan dari kalender yang tersedia (maksimal 14 hari ke depan)
4. Setelah memilih tanggal, daftar slot jam akan ditampilkan dengan keterangan status:
   - Hijau: slot tersedia dan dapat dipilih
   - Merah dengan tulisan "Penuh": slot sudah dibooking oleh pengguna lain
   - Abu-abu dengan tulisan "Sudah Lewat": jam slot sudah terlewati pada hari tersebut
5. Ketuk slot waktu yang diinginkan (hanya slot berwarna hijau yang dapat dipilih)
6. Isi kolom **Pesan untuk Owner** dengan keterangan keperluan booking (opsional)
7. Ketuk tombol **Kirim Booking**
8. Booking berhasil dikirim dan menunggu konfirmasi dari owner

**Catatan:** Pembayaran dilakukan langsung ke owner, tidak melalui aplikasi. Status booking akan diperbarui oleh owner menjadi Dikonfirmasi atau Ditolak.

### Melihat Riwayat dan Status Booking

1. Buka tab **Dashboard** atau tab **Chat** dari navigasi bawah
2. Daftar booking yang pernah dilakukan akan ditampilkan beserta statusnya:
   - **Menunggu**: booking sudah dikirim dan belum direspons owner
   - **Dikonfirmasi**: booking telah disetujui oleh owner
   - **Ditolak**: booking tidak disetujui oleh owner

### Memberikan Ulasan (Review)

Ulasan hanya dapat diberikan oleh pengguna yang sudah login. Setiap pengguna hanya dapat memberikan satu ulasan per venue.

1. Buka halaman detail venue
2. Ketuk tombol **Tulis Ulasan**
3. Pada halaman Tulis Ulasan, berikan penilaian bintang dengan mengetuk ikon bintang (skala 1 sampai 5)
4. Isi kolom **Komentar** dengan ulasan teks mengenai pengalaman menggunakan venue tersebut
5. Tambahkan foto secara opsional melalui dua cara:
   - Ketuk **Kamera** untuk mengambil foto langsung
   - Ketuk **Galeri** untuk memilih foto dari galeri perangkat
6. Ketuk tombol **Kirim Ulasan**
7. Ulasan akan langsung muncul di halaman detail venue secara realtime

### Mengelola Profil

1. Buka tab **Profil** dari navigasi bawah
2. Ketuk ikon pensil di pojok kanan atas untuk masuk ke mode edit profil
3. Ketuk ikon kamera pada foto profil untuk mengganti foto profil
4. Ubah nama pada kolom **Nama**
5. Ketuk tombol **Simpan** untuk menyimpan perubahan atau **Batal** untuk membatalkan

---

## Panduan Pemilik Venue (Owner)

### Menambahkan Venue Baru

1. Buka tab **Dashboard** dari navigasi bawah
2. Ketuk ikon tambah (+) di pojok kanan atas
3. Pada halaman **Tambah Venue**, isi formulir berikut:
   - **Foto Venue**: ketuk area foto untuk memilih gambar dari galeri
   - **Nama Venue**: isi nama venue olahraga
   - **Jenis Olahraga**: ketuk dropdown dan pilih kategori yang sesuai. Pilihan yang tersedia adalah Futsal, Badminton, Basket, Renang, Tenis, Voli, Gym / Fitness, Skate Park, Climbing, Golf, dan Lainnya
   - **Deskripsi**: isi keterangan singkat mengenai venue
   - **Lokasi Venue**: ketuk tombol **GPS** agar koordinat lokasi venue diambil secara otomatis dari GPS perangkat
4. Ketuk tombol **Simpan Venue**
5. Venue baru berhasil ditambahkan dan akan muncul di halaman Beranda

### Mengelola Slot Booking

Slot booking menentukan jam-jam yang tersedia untuk dibooking oleh pengguna pada setiap hari dalam seminggu.

**Membuka halaman kelola slot:**
1. Buka tab **Dashboard**
2. Temukan venue yang ingin dikelola slotnya
3. Ketuk tombol **Slot Jam** pada kartu venue tersebut

**Menambahkan slot baru:**
1. Pada halaman Kelola Slot Booking, pilih hari dari deret tab hari (Senin hingga Minggu) di bagian atas
2. Ketuk tombol tambah untuk membuka panel **Tambah Slot Baru**
3. Pilih hari yang berlaku pada tombol-tombol hari yang tersedia
4. Atur **Jam Mulai** dan **Jam Selesai** menggunakan time picker
5. Isi **Harga per Slot** dalam rupiah (isi 0 untuk slot gratis)
6. Ketuk tombol **Simpan Slot**
7. Slot akan muncul pada daftar dan berlaku berulang setiap minggu secara otomatis

**Mengaktifkan atau menonaktifkan slot:**
1. Pada daftar slot, setiap slot memiliki tombol toggle di sisi kanan
2. Ketuk toggle untuk mengaktifkan (hijau) atau menonaktifkan slot
3. Slot yang dinonaktifkan tidak akan ditampilkan kepada pengguna

**Menghapus slot:**
1. Ketuk ikon tempat sampah (merah) pada slot yang ingin dihapus
2. Slot akan langsung dihapus dari daftar

### Mengedit Venue

1. Buka tab **Dashboard**
2. Temukan venue yang ingin diedit
3. Ketuk ikon pensil (kuning) pada kartu venue
4. Ubah data venue yang diperlukan pada halaman **Edit Venue**, termasuk foto, nama, jenis olahraga, dan deskripsi
5. Ketuk tombol **Simpan Perubahan**

### Menghapus Venue

1. Buka tab **Dashboard**
2. Temukan venue yang ingin dihapus
3. Ketuk ikon tempat sampah (merah) pada kartu venue
4. Dialog konfirmasi akan muncul bertuliskan nama venue yang akan dihapus
5. Ketuk **Hapus** untuk mengkonfirmasi penghapusan atau **Batal** untuk membatalkan

### Mengelola Permintaan Booking

1. Buka tab **Profil**
2. Ketuk menu **Permintaan Booking**
3. Daftar semua booking yang masuk ke seluruh venue milik owner akan ditampilkan
4. Setiap permintaan menampilkan informasi pengguna, nama venue, tanggal, slot waktu, harga, dan pesan dari pengguna
5. Untuk setiap permintaan dengan status **Menunggu**, terdapat dua tombol:
   - **Konfirmasi**: menyetujui booking. Status berubah menjadi Dikonfirmasi
   - **Tolak**: menolak booking. Status berubah menjadi Ditolak

### Melihat Pesan dari Pengguna

1. Buka tab **Profil**
2. Ketuk menu **Pesan dari Pengguna**
3. Daftar seluruh pesan yang disertakan pengguna pada saat mengirim booking akan ditampilkan beserta status booking masing-masing

---

## Fitur Lengkap

| Fitur | User | Owner |
|---|---|---|
| Login dan Registrasi | Ya | Ya |
| Lihat daftar venue terdekat | Ya | Ya |
| Cari dan filter venue | Ya | Ya |
| Lihat detail venue dan review | Ya | Ya |
| Booking venue | Ya | Tidak |
| Lihat riwayat booking | Ya | Tidak |
| Tulis ulasan dan rating | Ya | Tidak |
| Tambah venue baru | Tidak | Ya |
| Edit dan hapus venue | Tidak | Ya |
| Kelola slot jam booking | Tidak | Ya |
| Konfirmasi atau tolak booking | Tidak | Ya |
| Lihat pesan dari pengguna | Ya (Dari Owner) | Ya |
| Edit profil | Ya | Ya |

---

## Teknologi

Aplikasi FuS dikembangkan menggunakan Flutter sebagai framework frontend dengan arsitektur MVVM, Riverpod sebagai state management, dan Go Router untuk navigasi. Backend menggunakan Supabase yang mencakup autentikasi berbasis email, database PostgreSQL dengan Row Level Security, penyimpanan file untuk foto venue dan ulasan, serta sinkronisasi ulasan secara realtime.

---

## Tim Pengembang

Kelompok 2, Program Studi Informatika, Fakultas Ilmu Komputer, Universitas Jember 2026.

- Mochammad Ryan Alviansyah (242410103005)
- Arul Pramana Bahari (242410103035)
- Muhammad Raihan Ramdhani (242410103059)
- M. Agil Asshofi (242410103090)

---
<div align="center">
Dibuat menggunakan Flutter & Supabase
</div>
