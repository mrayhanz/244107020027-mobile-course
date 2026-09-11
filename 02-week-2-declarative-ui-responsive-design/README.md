|  | Pemrograman Mobile |
|--|--|
| NIM |  244107020027|
| Nama |  Muhammad Rayhan Zamzami |
| Kelas | TI - 3G |
| Repository | [link] (https://github.com/mrayhanz/244107020027-mobile-course/tree/main/02-week-2-declarative-ui-responsive-design) |

# WEEK 2
## Declarative UI & Responsive Design

### Demo

1. Jalankan aplikasi hasil akhir pada emulator ukuran ponsel (misal 5"), lalu tablet (misal 10"), bandingkan jumlah kolomnya 

- 5" = 800 x 480 

![screenshot](screenshots/demo-1.png)

- 10" = 1920 x 1200

![screenshot](screenshots/demo-2.png)

2. Aktifkan dark mode pada emulator/perangkat dan amati perubahan tema secara otomatis.

![screenshot](screenshots/demo-darkmode.png)

3. Perhatikan pola declarative: UI tidak diubah satu per satu, hanya state yang diperbarui dan Flutter membangun ulang tampilan.

### Praktikum: layout sederhana (warm-up)

- tampilan kartu profil:

![screenshot](screenshots/warm-up.png)

- Hapus expanded di baris nama

![screenshot](screenshots/warm-up-1.png)

- Ganti mainAxisSize MainAxisSize.min menjadi nilai default 

![screenshot](screenshots/warm-up-2.png)

- tambahkan satu baris data (email):

![screenshot](screenshots/warm-up-3.png)

### Praktikum: dashboard responsif

- Buat aplikasi profil sederhana

![screenshot](screenshots/praktikum-1.jpg)

- Menambahkan interaksi: StatefulWidget dan Cupertino

![screenshot](screenshots/praktikum-2.jpg)
![screenshot](screenshots/praktikum-3.jpg)

- Eksperimen layout

1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom (diubah menjadi 300)

![screenshot](screenshots/eksperimen-1.png)

2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.

- tetap bertema gelap walau tidak sedang di mode gelap
![screenshot](screenshots/eksperimen-2.png)

- tema mengikuti tema system/perangkat (tema perangkat saya dark)

![screenshot](screenshots/eksperimen-2.png)

3. Uji aplikasi dengan ukuran layar emulator yang berbeda.

![screenshot](screenshots/eksperimen-3.png)

4. Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

```
child: Semantics(
label: '$title: $value',
```

### Tugas dan AI design exploration

Kembangkan dashboard menjadi halaman Academic Overview dengan ketentuan:

- Memiliki header profil dan minimal empat kartu informasi
- Menggunakan Row, Column, Expanded, dan Container
- Menampilkan satu kolom pada layar sempit dan dua kolom pada layar lebar
- Menyediakan light theme dan dark theme yang tetap terbaca, dengan toggle tema (misal CupertinoSwitch atau Switch.adaptive)
- Memiliki label aksesibilitas untuk informasi atau tombol penting
- Menyertakan screenshot layar sempit dan lebar pada folder screenshots/

hasil:

![screenshot](screenshots/tugas-1.png)

![screenshot](screenshots/tugas-2.png)

- AI Prompt Challenge

1. Prompt desain. Ajukan prompt ini (atau variasinya): "Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya."

![screenshot](screenshots/ai-prompt-1.png)

2. Prompt penguatan konsep. "Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya."

![screenshot](screenshots/ai-prompt-2.png)
![screenshot](screenshots/ai-prompt-2(1).png)

3. Verification prompt. Minta AI mengaudit hasilnya sendiri: "Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"

4. Dokumentasikan. Simpan prompt, output penting, keputusan yang dipilih, alasan teknis, dan bukti verifikasi (test/screenshots) di README tugas minggu ini.

![screenshot](screenshots/ai-prompt-3.png)

![screenshot](screenshots/ai-prompt-4.png)

![screenshot](screenshots/ai-prompt-5.png)

- Refactoring challenge

1. Ekstrak kartu informasi menjadi widget reusable (misal InfoCard) yang menerima title dan value, sehingga tidak ada duplikasi widget.

```
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    super.key,
  });
```

2. Ganti warna dan ukuran yang di-hardcode dengan Theme.of(context) agar mengikuti tema terang/gelap secara otomatis.

```
                            children: [
                              Text(
                                'Student Profile',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
```

3. Pindahkan breakpoint ke satu konstanta bernama (misal const kWideBreakpoint = 700;) agar hanya didefinisikan satu kali.

```
const double kWideBreakpoint = 700;
```

```
            final columns =
                constraints.maxWidth >= kWideBreakpoint ? 2 : 1;
```
4. Jalankan flutter analyze dan pastikan tidak ada error maupun warning baru.

![screenshot](screenshots/analyze.png)

- Testing Dasar

![screenshot](screenshots/test.png)

### Refleksi

1. Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?
    
    Imperative menjelaskan langkah-langkah untuk membuat UI, sedangkan declarative menjelaskan hasil UI yang diinginkan berdasarkan kondisi.
x
2. Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?
    
    Membantu membagi ruang yang tersedia dalam Row atau Column. Bisa error jika child memiliki ukuran yang dipaksakan terlalu besar atau constraint parent tidak sesuai.

3. Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?
    
    Breakpoint membuat UI menyesuaikan ukuran layar, sedangkan theme mengatur tampilan light/dark agar tetap nyaman dan terbaca.

4. Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?

    - memastikan layout tetap 1 kolom di layar sempit dan 2 kolom di layar lebar
    - memastikan light dan dark theme tetap terbaca, termasuk warna teks dan background
    - menjalankan aplikasi pada ukuran layar berbeda untuk memastikan hasil rekomendasi AI sesuai