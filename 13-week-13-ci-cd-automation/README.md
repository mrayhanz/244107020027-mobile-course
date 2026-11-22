|            | Pemrograman Mobile                                                                                            |
| ---------- | ------------------------------------------------------------------------------------------------------------- |
| NIM        | 244107020027                                                                                                  |
| Nama       | Muhammad Rayhan Zamzami                                                                                       |
| Kelas      | TI - 3G                                                                                                       |
| Repository | [link](https://github.com/mrayhanz/244107020027-mobile-course/tree/main/13-week-13-ci-cd-automation) |

# WEEK 13 — CI/CD & Automation

Tujuan utama praktikum ini adalah mengotomatiskan alur pengujian dan pembangunan aplikasi Flutter menggunakan GitHub Actions.

## 1. Alur CI/CD yang Diterapkan

Pipeline dikonfigurasi dalam file `.github/workflows/flutter-ci.yml`.

| Tahap | Perintah | Tujuan |
| ----- | -------- | ------ |
| **Linting** | `dart format` | Memastikan kode mengikuti standar format Dart. |
| **Analisis** | `flutter analyze` | Mencari potensi bug dan pelanggaran rule lints. |
| **Testing** | `flutter test` | Menjalankan unit & widget test untuk menjamin logika benar. |
| **Build APK** | `flutter build apk` | Membuat file instalasi Android (Release). |
| **Build AAB** | `flutter build appbundle` | Membuat file distribusi Play Store. |
| **Artifacts** | `actions/upload-artifact` | Menyimpan hasil build agar bisa diunduh di GitHub Actions. |

## 2. Bukti Konfigurasi Workflow

```yaml
# .github/workflows/flutter-ci.yml excerpt
jobs:
  test-and-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - run: flutter build apk --release
      - run: flutter build appbundle --release
```

## 3. Strategi Versioning & Keamanan

- **Versioning:** Mengikuti *Semantic Versioning* pada `pubspec.yaml`. Setiap rilis baru harus menaikkan `version` (misal `1.0.0+1` ke `1.0.1+2`).
- **Security:**
  - Token, API Key, dan Keystore **tidak dimasukkan** ke repository.
  - Menggunakan *GitHub Secrets* untuk menyimpan data sensitif yang dibutuhkan saat build (misal: password signing).
  - Branch protection (optional) dapat digunakan untuk memastikan PR harus lolos CI sebelum di-merge.

## 4. Hasil Pemeriksaan Lokal

Semua pemeriksaan telah dijalankan secara lokal dengan hasil sebagai berikut:

- `dart format`: Berhasil (2 files formatted).
- `flutter analyze`: **No issues found!**
- `flutter test`: **All tests passed!**

## Refleksi

1. **Masalah yang ditemukan otomatis:** Kesalahan penulisan (syntax), pelanggaran aturan lint (misal: missing `const`), dan regresi logika yang menyebabkan test gagal.
2. **Informasi untuk investigasi build gagal:** Log dari GitHub Actions pada step yang merah (biasanya error pesan compiler atau stack trace test).
3. **Pemeriksaan manual:** Peninjauan visual UI (UX), pengujian pada perangkat fisik nyata untuk sensor/fitur hardware, dan persetujuan QA sebelum rilis ke Store.
