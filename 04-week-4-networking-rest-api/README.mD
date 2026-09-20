|  | Pemrograman Mobile |
|--|--|
| NIM |  244107020027|
| Nama |  Muhammad Rayhan Zamzami |
| Kelas | TI - 3G |
| Repository | [link] () |

# WEEK 4

## Networking & Rest API

### Praktikum 1

![screenshot](screenshots/praktikum1.png)

### Praktikum 2

Uji 3 Skenario error : 

1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.

![screenshot](screenshots/praktikum2-1.png)

2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.

![screenshot](screenshots/praktikum2-2.png)
![screenshot](screenshots/praktikum2-1.png)

3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.

```
    BaseOptions(
      baseUrl: 'https://jsonplaceholder1.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'}, 
    ),
```

![screenshot](screenshots/praktikum2-2.png)



