# Rental PS App

Aplikasi Flutter untuk membantu operasional rental PlayStation dan pencatatan kas sederhana.

## Fitur utama

- Dashboard status unit PS, pelanggan yang sedang bermain, antrean, dan sisa waktu.
- Pencatatan, pengubahan, dan penghapusan transaksi sewa.
- Pilihan durasi, tarif paket yang dapat diatur, serta metode pembayaran tunai atau transfer.
- Penyimpanan deposit/sisa waktu pelanggan.
- Pengingat lokal lima menit sebelum waktu habis dan saat sesi selesai.
- Pencatatan pengeluaran operasional.
- Rekap harian dan laporan periode tujuh hari, bulan berjalan, dan bulan sebelumnya.
- Berbagi rekap melalui WhatsApp.
- Pengaturan nama rental, jumlah unit, tarif, PIN lokal kasir, serta backup/pemulihan database.

Aplikasi ini berfokus pada rental PS. Fitur katalog, stok, dan kasir jajanan/snack telah dihapus dari antarmuka dan kode aplikasi. Database lama tidak menghapus tabel snack secara otomatis saat aplikasi diperbarui, demi mencegah penghapusan data lama tanpa sengaja; tabel tersebut tidak lagi digunakan aplikasi.

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

Angka “Selisih Kas” merupakan total pemasukan sewa dikurangi pengeluaran yang dicatat dalam aplikasi. Angka ini bukan laporan laba akuntansi lengkap, karena belum memperhitungkan komponen seperti penyusutan perangkat atau biaya lain yang belum dimasukkan.
