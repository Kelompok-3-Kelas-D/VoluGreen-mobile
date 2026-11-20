# 🌱 VoluGreen Mobile

**VoluGreen Mobile** adalah platform yang menghubungkan masyarakat dengan komunitas/organisasi untuk kegiatan volunteer *sustainable living*. Aplikasi ini adalah klien dari web service Django REST Framework milik proyek web yang telah dibuat sebelumnya.

## 👥 Anggota Kelompok 3 Kelas D

| Nama | NPM |
| --- | --- |
| Aqila Zoya Yuwono | 2506620293 |
| Felisha Angeline | 2506656740 |
| Micguel Katili | 2506588065 |
| Muhammad Syamil | 2506547746 |
| Rayhan Fairuz Aqram | 2506586186 |

## 💡 Deskripsi Aplikasi

Relawan dapat mencari dan mendaftar kegiatan seperti aksi bersih lingkungan, urban farming, dan penanaman pohon. Penyelenggara mengelola lowongan dan kehadiran relawan serta mencatat dampak kegiatan. Admin memverifikasi penyelenggara dan memoderasi konten.

## 🔗 Tautan

- Repositori web (Django + REST API): https://github.com/Kelompok-3-Kelas-D/VoluGreen
- Situs web / server API (PWS): https://rayhan-fairuz51-volugreen.pws.cs.ui.ac.id/
- Desain Figma: https://www.figma.com/design/ffTeu2AFsZg3GF3bK5UDJX/VoluGreen---UI-UX-Design
- APK: _menyusul_

## 🎭 Peran Pengguna

| Peran | Kemampuan di aplikasi | Navigasi |
| --- | --- | --- |
| 🤝 Relawan | Jelajah & peta kegiatan, arsip, daftar/ubah/batalkan pendaftaran, riwayat & refleksi | Bottom navigation (Jelajah · Pendaftaran · Riwayat · Profil) |
| 🙋 Penyelenggara | Ajukan/ubah kegiatan, tinjau pendaftar, tandai kehadiran, catat dampak | Bottom navigation (Ringkasan · Kegiatan · Profil) |
| ⚙️ Admin | Verifikasi organisasi, moderasi kegiatan, kelola kategori, tangani laporan | Navigation drawer |

Tamu (belum masuk) dapat melihat daftar, peta, dan detail kegiatan.

## 🧩 Modul & Pembagian Tugas

| Modul | Penanggung jawab | Folder | Endpoint (`/api/v1/…`) |
| --- | --- | --- | --- |
| 1. Autentikasi & Profil | Syamil | `lib/screens/auth`, `lib/screens/profile_screen.dart`, `lib/core/auth_provider.dart` | `auth/register/` `auth/login/` `auth/logout/` `auth/me/` (GET, PATCH) `auth/password/` |
| 2. Eksplorasi & Pemetaan | Felisha | `lib/screens/explore` | `categories/` `activities/` `activities/<id>/` `bookmarks/` `bookmarks/<id>/` (PUT, DELETE) |
| 3. Alur Relawan | Micguel | `lib/screens/volunteer` | `volunteer/registrations/` `volunteer/activities/<id>/register/` `volunteer/registrations/<uuid>/` (GET, PATCH) `…/cancel/` `…/reflection/` `volunteer/history/` |
| 4. Dashboard Penyelenggara | Zoya | `lib/screens/organizer` | `organizer/summary/` `organizer/activities/` (GET, POST) `organizer/activities/<id>/` (GET, PUT, DELETE) `…/applications/` `…/impact/` (GET, PUT) `organizer/applications/<uuid>/` (PATCH) |
| 5. Admin Panel & Integrasi Data | Rayhan | `lib/screens/admin` | `admin/summary/` `admin/categories/` `admin/categories/<id>/` `admin/organizations/` `admin/organizations/<id>/decision/` `admin/activities/` `admin/activities/<organizer\|moderation>/<id>/decision/` `admin/reports/` (GET, POST) `admin/reports/<id>/` (PATCH) |

Kode bersama: `lib/core` (klien HTTP, model, state sesi) dan `lib/widgets` (daftar async, chip status, dialog).

## 🔌 Integrasi dengan Django

- Autentikasi **token**: `POST auth/login/` mengembalikan `token`, dikirim sebagai header `Authorization: Token <token>` (disimpan di `shared_preferences`; 401 otomatis mengeluarkan pengguna).
- Validasi ditangani server dan dikembalikan sebagai `{"detail": "...", "errors": {"field": ["..."]}}`; form menampilkan pesan per kolom.
- Peta memakai OpenStreetMap lewat `flutter_map`.

## ▶️ Menjalankan

1. Jalankan backend (lihat README repo web): `python manage.py runserver 0.0.0.0:8000`.
2. `flutter pub get`
3. Emulator Android (default memakai `http://10.0.2.2:8000`):
   `flutter run`
   Perangkat fisik / server PWS:
   `flutter run --dart-define=API_BASE=https://rayhan-fairuz51-volugreen.pws.cs.ui.ac.id`
4. Analisis & tes: `flutter analyze` dan `flutter test`.
