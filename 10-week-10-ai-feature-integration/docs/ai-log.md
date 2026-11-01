# AI Log Week 10

## 1. Prompt Sistem
```text
Kamu asisten kampus ramah. Jawab dalam Bahasa Indonesia,
maksimal 2 kalimat. Jangan meminta atau mengungkap NIK,
nomor telepon, alamat, token, password, atau data pribadi.
```

## 2. User Prompt
```text
Saya mahasiswa baru di kampus. Bagaimana cara mencatat tugas kuliah dengan baik?
```

## 3. Output Awal AI
```text
Catat setiap tugas segera setelah diberikan dengan mencantumkan tenggat waktu dan skala prioritasnya. Gunakan fitur Notes pada aplikasi atau buku catatan harian agar tidak ada jadwal yang terlewat.
```

## 4. Verifikasi dan Keputusan Arsitektur
| Usulan Awal | Keputusan | Alasan Teknis |
|---|---|---|
| Simpan API key di konstanta Dart | **Ditolak** | Secret berisiko bocor saat push ke repository git publik. Disimpan aman lewat `flutter_secure_storage`. |
| Pakai `StateProvider` Riverpod v1/v2 | **Ditolak** | Riverpod 3 mendepresiasi `StateProvider`. Diimplementasikan dengan `NotifierProvider<AiChatNotifier, AiChatState>`. |
| Tampilkan raw exception ke user | **Ditolak** | Pesan error teknis membingungkan user. Dikonversi jadi pesan singkat user-friendly di layer presentation. |
| Model `gemini-3.1-flash-lite` | **Diterima** | Sesuai ketersediaan kuota free tier Google AI Studio (500 RPD), respons cepat, dan efisien token. |
