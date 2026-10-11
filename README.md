# Rental PS App

Aplikasi Flutter untuk membantu operasional rental PlayStation dan pencatatan kas sederhana.

## Fitur utama

- Dashboard status unit PS, pelanggan yang sedang bermain, antrean, dan sisa waktu.
- Pencatatan, pengubahan, dan penghapusan transaksi sewa.
- Pilihan durasi, tarif paket yang dapat diatur, serta metode pembayaran tunai atau transfer.
- Penyimpanan deposit/sisa waktu pelanggan.
- Pengingat lokal lima menit sebelum waktu habis dan saat sesi selesai.
- Arsip foto buku catatan per tanggal dari kamera atau galeri, dengan pembacaan teks lokal (OCR) yang dapat dikoreksi sebelum disimpan.
- Pencatatan pengeluaran operasional.
- Rekap harian dan laporan periode tujuh hari, bulan berjalan, dan bulan sebelumnya.
- Berbagi rekap melalui WhatsApp.
- Pengaturan nama rental, jumlah unit, tarif, PIN lokal kasir, serta backup/pemulihan database.

Aplikasi ini berfokus pada rental PS. Foto buku catatan, teks hasil OCR, dan baris rekap enam kolom tersimpan lokal di database yang sama, sehingga ikut tercakup dalam backup database. OCR hanya bantuan pembacaan; tulisan tangan, angka, dan nominal tetap harus dicek dan dikoreksi secara manual. Rekap foto tidak otomatis membuat transaksi rental resmi. Fitur katalog, stok, dan kasir jajanan/snack telah dihapus dari antarmuka dan kode aplikasi. Database lama tidak menghapus tabel snack secara otomatis saat aplikasi diperbarui, demi mencegah penghapusan data lama tanpa sengaja; tabel tersebut tidak lagi digunakan aplikasi.

## Menjalankan aplikasi

1. Pasang Flutter SDK yang sesuai dengan batas versi pada `pubspec.yaml`.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter run` pada perangkat atau emulator yang didukung.

## Data dan backup

Data transaksi disimpan secara lokal menggunakan SQLite. Pengaturan aplikasi, termasuk konfigurasi tarif dan PIN lokal, disimpan terpisah menggunakan `SharedPreferences` sehingga tidak termasuk dalam file database backup. Simpan file cadangan di lokasi aman dan lakukan pemulihan hanya dari file cadangan Rental PS yang valid.

## Pengujian

Jalankan pengujian logika tarif dan waktu rental dengan:

```sh
flutter test
```

## Catatan laporan

Angka “Sisa Operasional” merupakan omzet sewa dikurangi pengeluaran yang dicatat dalam aplikasi. Angka ini adalah ringkasan operasional sederhana, bukan laba akuntansi lengkap atau saldo uang tunai fisik, karena belum memperhitungkan komponen seperti penyusutan perangkat dan biaya lain yang belum dimasukkan.
