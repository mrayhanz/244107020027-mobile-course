# Performance Profiling Findings — Week 11

**Aplikasi:** Campus Notify  
**Target:** Flutter Windows & Android (Profile Mode)  
**Tools:** Flutter DevTools (Performance, Memory, Network) & Automated Benchmark Tests

---

## Ringkasan Temuan Bottleneck

Berdasarkan hasil baseline profiling pada alur navigasi utama (halaman Home, pencarian Catatan, feed Pengumuman, dan bolak-balik navigasi detail):

| No | Kategori | Bottleneck Teridentifikasi | Dampak Performa | Lokasi Kode Awal |
|:---:|---|---|---|---|
| 1 | **CPU / Widget Rebuild** | Root widget `NotesPage` me-rebuild seluruh tree pada setiap ketikan huruf di input search | Flame Chart UI Thread tersendat (~34 ms/frame), UI lag saat typing | `lib/features/notes/presentation/pages/notes_page.dart` |
| 2 | **Raster Thread & Memori** | Pemuatan gambar pengumuman tanpa pembatasan ukuran decode (`Image.network` full-res) | Tekanan memori melonjak (>84 MB), image decode berulang di raster thread | `lib/features/announcements/presentation/pages/announcements_page.dart` |
| 3 | **Jaringan & I/O** | Request API pengumuman tidak memiliki mekanisme cache lokal (request berulang tanpa TTL) | Latensi ~313 ms tiap pembukaan halaman, boros bandwidth & kuota | `lib/features/announcements/data/repositories/announcement_repository_impl.dart` |
| 4 | **Memory Leak** | `ScrollController` dan `TextEditingController` tidak dibersihkan dengan method `dispose()` | Objek controller dan listener menumpuk di Dart Heap saat buka-tutup halaman | `NotesSearchHeader` & `AnnouncementsPage` |

---

## 1. Temuan 1: Rebuild Berlebih pada Fitur Pencarian

### Gejala
Ketika pengguna mengetik 10 karakter pada kolom pencarian:
- `NoteSearchQueryNotifier` langsung memperbarui state string tanpa mekanisme penundaan.
- `NotesPage` (root Scaffold) memanggil `ref.watch(noteSearchQueryProvider)` dan `ref.watch(filteredNotesProvider)`.
- Akibatnya, 10 kali keystroke memicu 10 kali full-widget-rebuild pada seluruh hirarki, termasuk AppBar, TextField, dan ListView.

### Bukti Flame Chart & Benchmark
- Call stack didominasi oleh `NotesPage.build` -> `TextField.build` -> `_NotesListView.build`.
- Pengujian benchmark tanpa debounce mencatat **50 mutasi state** untuk 50 pengetikan berturut-turut.
- Frame time mencapai **34.2 ms** (melebihi frame budget 16.6 ms / 60 FPS).

---

## 2. Temuan 2: Decode Gambar Resolusi Penuh & Ketiadaan Caching

### Gejala
Feed pengumuman kampus menampilkan gambar sampul pengumuman menggunakan widget bawaan tanpa penyesuaian cache memori:
- Gambar berukuran asli (misal 1920x1080) diunduh dan di-decode secara mentah ke memori native (skia/impeller texture).
- Tidak ada cache disk lokal sehingga navigasi ulang mengunduh ulang gambar yang sama dari remote URL.

### Bukti DevTools
- Tab Memory menunjukkan external native memory naik drastis hingga **84.6 MB**.
- Tab Performance menunjukkan spike pada Raster Thread (`ImageDecoder::Decode`) saat scroll cepat.

---

## 3. Temuan 3: Request API Berulang Tanpa Strategi Offline/Stale-While-Revalidate

### Gejala
Setiap kali pengguna membuka halaman Pengumuman atau kembali dari sub-halaman:
- `getAnnouncements()` mengeksekusi request jaringan baru secara sinkron.
- Pengguna melihat indikator loading berputar meski data belum tentu berubah.
- Bila koneksi internet putus, aplikasi langsung melempar error tanpa menampilkan data yang sebelumnya sudah pernah diambil.

### Bukti Network & Benchmark
- Latensi pemanggilan data pertama tercatat **313 ms**.
- Tidak ada layer cache lokal in-memory yang menyimpan entri per halaman.

---

## 4. Temuan 4: Risiko Memory Leak pada Controller & Listener

### Gejala
Komponen yang menggunakan `ScrollController` untuk pagination dan `TextEditingController` untuk input pencarian rentan tertinggal di memori jika:
- Listener navigasi tidak dilepas saat widget di-unmount.
- Navigasi bolak-balik antara Home -> Announcements -> Notes sebanyak 5 kali mengakibatkan instance controller tetap hidup di Heap snapshot.

---

## Rencana Aksi Optimasi (Prioritas Perbaikan)

1. **Penerapan Riverpod `.select()` dan `Debouncer`**:
   - Membatasi rebuild widget search header hanya saat status tombol clear berubah.
   - Menunda eksekusi filter sebanyak 250 ms untuk meredam keystroke spam.
2. **Penerapan `ListView.builder` + `RepaintBoundary`**:
   - Memastikan hanya widget di viewport yang di-build (terbukti memangkas dari 1000 build menjadi 18 build).
   - Memisahkan layer repaint tiap kartu pengumuman dan tile catatan.
3. **Penerapan `CachedNetworkImage` dengan `memCacheWidth` / `memCacheHeight`**:
   - Mengunci ukuran decode gambar ke 600x320 px (thumbnail mode), menghemat memori GPU/native.
4. **Pola Repository Stale-While-Revalidate (`StaleCache`) & Retry Interceptor Dio**:
   - Cache hit instan (< 1 ms), fallback saat offline, dan auto-retry backoff (1s/2s/4s) untuk transient error.
5. **Pembersihan Resource (`dispose()`)**:
   - Menambahkan lifecycle cleanup pada seluruh controller, timer debouncer, dan stream listener.
