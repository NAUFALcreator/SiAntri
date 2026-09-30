# SIAntri (Flutter + Supabase)

Versi Flutter dari SIAntri: Ambil Nomor, Monitor (dengan suara), dan Panel Petugas. Backend sama dengan versi web (`supabase.sql`).

## Menjalankan di Cursor
1. Siapkan Supabase: jalankan `supabase.sql` di SQL Editor, lalu buat akun petugas di Authentication > Users (centang Auto Confirm). Kalau sudah punya dari versi web, lewati langkah ini.
2. Isi `lib/config.dart` dengan URL dan anon key.
3. Di terminal Cursor, dalam folder ini:
   ```
   flutter create . --platforms=android,ios,web --project-name siantri
   rm test/widget_test.dart
   flutter pub get
   flutter run -d chrome
   ```
   Untuk Android: `flutter run` (emulator atau HP terhubung).
4. Android rilis: tambahkan `<uses-permission android:name="android.permission.INTERNET"/>` di `android/app/src/main/AndroidManifest.xml`. Untuk APK: `flutter build apk`.

Ekstensi yang disarankan di Cursor: **Dart** dan **Flutter**.

## Struktur
- `lib/main.dart` navigasi 3 tab
- `lib/register.dart` pengunjung
- `lib/monitor.dart` monitor + suara
- `lib/admin.dart` petugas (login)
- `lib/data.dart` akses Supabase realtime & komponen UI
