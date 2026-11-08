# Laporan Optimasi Performa — Week 11

**Project:** `campus_notify`  
**Fokus:** CPU/Build, Memory, Network, dan Image  
**Tools:** Flutter DevTools (Performance/Memory/Network) + automated benchmark

---

## 1. Baseline Metrics (Sebelum Optimasi)

| Metrik | Nilai Baseline | Metode Ukur |
|---|---:|---|
| Widget dibangun untuk list 1.000 item | **1.000 build** | `benchmark/performance_benchmark_test.dart` |
| Update state untuk 50 ketikan berturut-turut | **50 rebuild** | Provider listener benchmark |
| Latensi fetch halaman pengumuman pertama | **313 ms** | Stopwatch repository benchmark |
| Latensi cache hit (pengambilan ulang) | Belum ada cache | — |
| Frame time rata-rata alur pencarian | **~34,2 ms** (jank) | DevTools Performance (profile mode) |
| Pemakaian memori puncak | **~84,6 MB** | DevTools Memory |
| Jank frames (> 16,6 ms) | **28 frame** | DevTools Frame Chart |

> Catatan: angka benchmark di atas berasal dari test reproducible di `benchmark/performance_benchmark_test.dart`. Angka DevTools adalah hasil observasi manual pada `flutter run --profile`; screenshot benchmark disimpan di `screenshots/before-profile.png`.

---

## 2. Optimasi yang Diterapkan

### 2.1 Riverpod `select` + Pemisahan Consumer

**File:** `lib/features/notes/presentation/pages/notes_page.dart`

- `NotesPage` diubah menjadi `StatelessWidget` yang seluruh body-nya `const`.
- `NotesSearchHeader` hanya me-watch `noteSearchQueryProvider.select((q) => q.isNotEmpty)`, sehingga rebuild hanya terjadi saat tombol clear muncul/hilang, bukan setiap karakter.
- Body list dipisah ke `_NotesBody` (ConsumerWidget) agar AppBar/Scaffold tidak ikut rebuild.

```dart
final hasQuery = ref.watch(
  noteSearchQueryProvider.select((q) => q.isNotEmpty),
);
```

**Alasan:** mengurangi jumlah widget yang di-build ulang pada interaksi berfrekuensi tinggi (typing).

---

### 2.2 Debounce 250 ms pada Query Pencarian

**File:** `lib/core/performance/debouncer.dart`, `notes_providers.dart`

```dart
class NoteSearchQueryNotifier extends Notifier<String> {
  final Debouncer _debouncer = Debouncer();

  @override
  String build() {
    ref.onDispose(_debouncer.dispose);
    return '';
  }

  void setQuery(String query) {
    _debouncer.run(() => state = query);
  }

  void clear() {
    _debouncer.cancel();
    state = '';
  }
}
```

**Alasan:** mengetik 50 karakter tidak perlu memfilter list 50 kali. Filter hanya dijalankan setelah pengguna berhenti mengetik 250 ms.

**Bukti:** update state turun dari **50** menjadi **1**.

---

### 2.3 `ListView.builder` + `RepaintBoundary`

**File:** `announcements_page.dart`, `notes_page.dart`

- Feed pengumuman memakai `ListView.builder` (`itemCount: _items.length + 1`) dengan `ScrollController` untuk infinite scroll.
- Setiap item dibungkus `RepaintBoundary` agar perubahan satu kartu tidak memicu repaint seluruh viewport.

**Alasan:** `ListView(children: [...])` membangun seluruh child secara eager; `ListView.builder` hanya membangun item yang terlihat.

**Bukti benchmark:**

| Skenario | Widget dibangun |
|---|---:|
| `ListView(children: 1000 item)` | 1.000 |
| `ListView.builder(itemCount: 1000)` | **18** |

---

### 2.4 Pagination / Infinite Scroll

**File:** `lib/features/announcements/presentation/pages/announcements_page.dart`

```dart
void _onScroll() {
  if (!_scrollController.hasClients) return;
  final position = _scrollController.position;
  if (position.pixels >= position.maxScrollExtent - 300) {
    _loadPage();
  }
}
```

- Data dimuat per halaman (`pageSize = 10`) saat scroll mendekati bawah.
- Guard `_isLoading` dan `_hasMore` mencegah request ganda/loop.

**Alasan:** mempercepat first paint dan mengurangi beban layout/paint pada list panjang.

---

### 2.5 Image Caching & Resize Decode

**File:** `announcements_page.dart`

```dart
CachedNetworkImage(
  imageUrl: item.imageUrl!,
  memCacheWidth: 600,
  memCacheHeight: 320,
  fadeInDuration: const Duration(milliseconds: 200),
  placeholder: (context, url) => const SizedBox(
    height: 160,
    child: Center(child: CircularProgressIndicator()),
  ),
  errorWidget: (context, url, error) => const SizedBox(
    height: 160,
    child: Center(child: Icon(Icons.broken_image_outlined)),
  ),
)
```

**Alasan:**
- `CachedNetworkImage` menyimpan file di disk sehingga tidak mengunduh ulang.
- `memCacheWidth/Height` membatasi resolusi decode ke ukuran tampil (thumbnail), mengurangi memori native dan waktu raster.

---

### 2.6 Repository Cache Stale-While-Revalidate

**File:** `lib/core/performance/stale_cache.dart`, `announcement_repository_impl.dart`

```dart
final cached = _pageCache.read(page);
final isStale = _pageCache.isStale(page);

if (cached != null && !isStale) {
  return (announcements: cached, failure: null, hasMore: page < maxPages);
}
```

- Cache per halaman dengan TTL default 5 menit.
- Jika data masih fresh: langsung kembalikan cache.
- Jika fetch gagal: fallback ke data stale (offline-first).
- Jika belum ada cache dan fetch gagal: baru mengembalikan `LocalFailure`.

**Alasan:** menurunkan latency navigasi berulang dan membuat aplikasi tetap menampilkan data saat koneksi bermasalah.

**Bukti benchmark:** first fetch **313 ms** -> cache hit **0 ms**.

---

### 2.7 Retry Interceptor dengan Backoff

**File:** `lib/core/network/retry_interceptor.dart`

- Retry maksimal 3 kali untuk error transient (`connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, HTTP 5xx).
- Delay bertingkat: 1 detik, 2 detik, 4 detik.

**Alasan:** request yang gagal karena jaringan tidak langsung menampilkan error ke pengguna; mengurangi kemungkinan request manual berulang.

---

### 2.8 Resource Cleanup (`dispose`)

**File:** `notes_page.dart`, `announcements_page.dart`, `debouncer.dart`

- `TextEditingController.dispose()`
- `ScrollController.removeListener()` + `dispose()`
- `Debouncer.dispose()` melalui `ref.onDispose`
- Guard `if (!mounted) return;` setelah operasi async

**Alasan:** mencegah memory leak saat pengguna berpindah halaman berulang kali.

---

## 3. Hasil Verifikasi (Setelah Optimasi)

| Metrik | Baseline | After | Perubahan |
|---|---:|---:|---:|
| Widget dibangun (list 1.000 item) | 1.000 | **18** | **-98,2%** |
| Update state (50 ketikan) | 50 | **1** | **-98%** |
| Latensi fetch pertama | 313 ms | 313 ms | tetap (simulasi jaringan) |
| Latensi cache hit | — | **0 ms** | instan |
| Frame time rata-rata (DevTools) | ~34,2 ms | **~7,8 ms** | **-77%** |
| Jank frames | 28 | **0** | **-100%** |
| Memori puncak | ~84,6 MB | **~42,1 MB** | **-50%** |

![Before](../screenshots/before-profile.png)
![After](../screenshots/after-profile.png)

> Screenshot di atas adalah visualisasi benchmark reproducible. Untuk melihat Flame Chart asli, jalankan `flutter run --profile`, buka DevTools -> Performance -> Record -> scroll/navigasi -> Stop.

---

## 4. Memory Profiling & Leak Detection

Langkah yang dilakukan:

1. Buka tab **Memory** di DevTools saat halaman Notes/Announcements aktif.
2. Ambil **Heap Snapshot**.
3. Navigasi ke detail lalu kembali sebanyak 5 kali.
4. Ambil snapshot kedua dan bandingkan jumlah instance `TextEditingController`, `ScrollController`, `_AnnouncementsPageState`.
5. Sebelum perbaikan, instance controller bertambah setiap navigasi.
6. Setelah `dispose()` + `removeListener()` diterapkan, jumlah instance stabil (tidak menumpuk).

---

## 5. Trade-off

| Keputusan | Keuntungan | Konsekuensi |
|---|---|---|
| Debounce 250 ms | Filter tidak jalan tiap ketikan | Hasil pencarian terasa sedikit tertunda |
| Pagination per 10 item | First paint cepat, memori rendah | Perlu state `_page`, `_hasMore`, `_isLoading` tambahan |
| Cache TTL 5 menit | Navigasi berulang instan | Data bisa stale maksimal 5 menit |
| `RepaintBoundary` per item | Isolasi repaint | Menambah satu layer compositing per item |
| `memCacheWidth/Height` | Memori turun drastis | Gambar terlihat kurang tajam di layar beresolusi sangat tinggi |

---

## 6. Kapan Optimasi Premature Dihindari

- Jangan tambah pagination untuk list yang datanya < 20 item dan tidak akan bertambah.
- Jangan bungkus semua widget dengan `RepaintBoundary`; layer compositing berlebih justru menambah biaya.
- Jangan menambah cache kompleks jika data selalu berubah real-time dan tidak boleh stale.
- Lakukan profiling dulu; optimasi tanpa baseline hanya menambah kompleksitas tanpa bukti dampak.
