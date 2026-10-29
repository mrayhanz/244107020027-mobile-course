# AI Engineering & Verification Log: Fitur Search Notes

Dokumentasi proses *AI-Assisted Development* penambahan fitur pencarian catatan (*search notes*) pada aplikasi **Campus Notify** (Clean Architecture + Riverpod).

---

## 1. Praktikum 1: Prompt & Context Engineering

### A. Formula 5 Slot Prompting
```text
[Peran]   : Senior Flutter Developer & Clean Architecture Specialist
[Konteks] : Feature-first (presentation -> domain <- data), Riverpod (v3), SQLite, Dio
[Tugas]   : Fitur search judul notes + empty state
[Batas]   : Jangan ubah arsitektur, dilarang panggil DB dari widget, domain murni Dart, fungsi maks 40 baris
[Output]  : Use case SearchNotes + Notifier & Provider + UI NotesPage + 3 test case
```

### B. Analisis Buruk vs Baik
- **Buruk:** *"Buatkan search notes yang keren dong"* -> Tanpa arsitektur, query DB langsung di widget, case-sensitive, tanpa handling empty state & test.
- **Baik:** *"Tambah search judul notes. Arsitektur: presentation->domain<-data. Jangan panggil SQLite dari widget. Sertakan empty state + 1 widget test."* -> Modular, layer jelas, usecase terisolasi, teruji.

### C. Context vs Secret
- **Disertakan:** Entity `Note`, kontrak `NoteRepository`, struktur direktori fitur, dependensi `pubspec.yaml`.
- **Disaring:** Kredensial auth, token FCM, API key diganti placeholder (`TOKEN_PLACEHOLDER`).

---

## 2. Praktikum 2: Generate & Verifikasi Search

### A. Draf Awal AI
```dart
// lib/features/notes/domain/usecases/search_notes.dart
import 'package:flutter/material.dart'; // Pelanggaran: Framework di domain

class SearchNotes {
  List<Note> filterNotes(List<Note> notes, String query) {
    return notes.where((n) => n.title.contains(query)).toList(); // Bug: Case-sensitive
  }
}

// lib/features/notes/presentation/providers/notes_providers.dart
final noteSearchQueryProvider = StateProvider<String>((ref) => ''); // Usang di Riverpod 3
```

### B. Pelaksanaan 6 Langkah Verifikasi
1. **Baca Baris demi Baris:** Ditemukan impor framework di usecase dan query case-sensitive.
2. **Cek Import Domain:** Impor `flutter/material.dart` langsung dihapus dari layer domain.
3. **Cek API & Versi:** `StateProvider` diganti `NotifierProvider` + class `Notifier<String>`.
4. **Static Analysis:** `flutter analyze` hingga 0 issue.
5. **Automated Test:** Dibuat unit test pencarian cocok dan kata kunci tidak ditemukan.
6. **Uji Manual:** Verifikasi query kosong, cocok, dan empty state.

### C. Bukti Bug & Halusinasi AI
1. **Import Framework di Domain:**  
   `grep -rn "package:flutter" lib/features/notes/domain/` menemukan impor `flutter/material.dart` pada usecase domain.
2. **Bug Case-Sensitivity:**  
   Unit test `filterNotes(list, 'belanja')` gagal (`Expected: 2, Actual: 0`) karena data berisi `'Belanja Bulanan'` dan `'Daftar BELANJA Lab'`.

---

## 3. Praktikum 3: Debug & Refactor

### A. Debug Siklus Test Merah (Red-Green-Refactor)
1. **Reproduksi:** Query lowercase `'belanja'` gagal mencocokkan kata dengan huruf kapital.
2. **Isolasi:** Pindah algoritma ke pure use case `SearchNotes.call(List<Note> notes, String query)`.
3. **Test Merah:** Unit test gagal di `test/search_filter_test.dart`.
4. **Fix (Green):** Sanitasi dengan `.trim().toLowerCase()`:
   ```dart
   class SearchNotes {
     const SearchNotes();

     List<Note> call(List<Note> notes, String query) {
       final sanitized = query.trim().toLowerCase();
       if (sanitized.isEmpty) return notes;
       return notes.where((n) => n.title.toLowerCase().contains(sanitized)).toList();
     }
   }
   ```
5. **Akar Masalah:** String comparison Dart case-sensitive bawaan, wajib dinormalisasi manual.

### B. Refactor ke Layer yang Benar
```text
Widget (NotesPage UI)
  └── Notifier (NoteSearchQueryNotifier: state query)
        └── Use Case (SearchNotes: filter murni di Domain)
              └── Repository (NoteRepository / SQLite: data provider)
```
- Semua fungsi widget di bawah 30 baris (`_NotesSearchHeader`, `_NotesListView`, `_NotesEmptyState`, `_NotesErrorView`).
- Widget bebas dari akses database atau network langsung.

---

## 4. AI Challenge & Keputusan

### A. Ringkasan Temuan Reviewer AI
1. **[Blocker] Enkapsulasi Mutasi State:** UI dilarang ubah `state = val` langsung; wajib lewat method Notifier (`setQuery` / `clear`).
2. **[Saran] SQLite `LIKE %query%`:** Pindahkan pencarian ke database query SQL.
3. **[Saran] Dekomposisi Widget:** Pecah TextField & Empty State jadi private widgets terpisah.

### B. Tabel Usulan vs Keputusan

| No | Temuan AI | Level | Keputusan | Alasan Teknis |
|---|---|---|:---:|---|
| 1 | Wajib pakai method Notifier | Blocker | **Diterima** | Riverpod 3 mewajibkan mutasi terarah via class Notifier. |
| 2 | Pindah search ke SQLite `LIKE` | Saran | **Ditolak** | Data lokal sudah di Riverpod cache. Disk I/O async tiap keystroke memicu lock DB & lag UI. Filter in-memory sinkron (<1ms) & offline-ready. |
| 3 | Pecah sub-widgets terpisah | Saran | **Diterima** | Fungsi `build()` terjaga ringkas (<30 baris) & modular diuji. |

### C. Keputusan Tiap Berkas
- `search_notes.dart`: **Terima + Refactor** (Pure domain usecase, case-insensitive).
- `notes_providers.dart`: **Terima + Refactor** (Riverpod 3 `NotifierProvider` & `filteredNotesProvider`).
- `notes_page.dart`: **Terima + Refactor** (Dekomposisi widget, event notifier, tombol clear).
- `search_filter_test.dart`: **Tulis Manual** (Unit test domain + widget test empty state & interaksi).

---

## 5. Ringkasan Verifikasi & Solusi Error

### A. Eksekusi Test
```bash
flutter test test/search_filter_test.dart
```
Output: 7 test lolos (4 unit test domain + 3 widget test UI).

### B. Matriks Solusi Error Umum
- **Method tidak ada:** Cek pubspec & dokumentasi API library; migrasi ke API resmi terbaru.
- **Import lintas layer:** Tegaskan batasan "domain murni Dart" pada prompt; audit via `grep`.
- **Test merah semua:** Perkecil lingkup prompt ke 1 fitur kecil + 1 unit test fokus.
- **Prompt looping:** Sertakan langkah reproduksi terukur + test merah pembukti bug.
- **Tak paham kode:** Baca ulang per baris, sederhanakan, dan dekomposisi fungsi ke < 30 baris.
