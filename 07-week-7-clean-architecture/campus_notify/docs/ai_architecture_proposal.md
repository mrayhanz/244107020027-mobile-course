# Dokumentasi Refactoring Clean Architecture (Minggu 7)

## 1. AI Prompt Challenge
```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Tabel Usulan vs Keputusan Final

| Komponen | Usulan Awal AI | Keputusan Final | Alasan Teknis |
|---|---|---|---|
| **Pemisahan Auth** | Pecah repo jadi entity, contract, model, impl | **Diterima** | Memutus coupling antara interface domain dan implementasi storage/HTTP. |
| **Use Case Granular** | 1 use case per operasi (Get, Add, Login, Logout) | **Diterima secara selektif** | Use case dipakai untuk `LoginUseCase` (validasi email/password + session) dan `GetNotes`. CRUD satu baris tanpa logika bisnis boleh langsung repo -> notifier. |
| **Error Handling** | Record Dart `({T? data, Failure? failure})` | **Diterima** | Mencegah kebocoran exception tidak tertangani ke layer UI. |
| **Token Storage** | Pindah ke `features/auth/data/datasources/` | **Diterima** | `TokenStore` dienkapsulasi sebagai data source lokal di bawah data layer. |
| **Format Helper** | Ekstrak ke `core/format.dart` | **Diterima** | Fungsi parser dan tanggal murni terpisah tanpa dependensi widget/Flutter. |

---

## 3. Hasil Tiga Grep Verifikasi Sterilitas

### 1. Presentation Steril dari Data Mentah
Perintah:
```bash
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages
```
**Hasil**: `No matches found` (0 temuan).

### 2. Domain & Core Steril dari Framework/Package Eksternal
Perintah:
```bash
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core
```
**Hasil**: `No matches found` (0 temuan).

### 3. Static Analysis & Unit Tests
- `flutter analyze`: **No issues found!**
- `flutter test`: **All 9 tests passed!**
  - `auth_push_test.dart` (4 tests)
  - `get_notes_test.dart` (2 tests)
  - `login_usecase_test.dart` (3 tests)
