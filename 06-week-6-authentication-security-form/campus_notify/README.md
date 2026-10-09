# campus_notify

A new Flutter project.

## Matriks Pengujian FCM

| State | Yang diharapkan | Cara uji |
| :--- | :--- | :--- |
| Foreground | Banner lokal muncul, klik masuk ke /pengumuman/3 | Aplikasi terbuka, kirim dari console/backend |
| Background | Banner sistem muncul, klik masuk ke rute yang benar | Tekan Home, kirim, klik banner |
| Terminated | Aplikasi terbuka ke rute yang benar via getInitialMessage | Swipe-close aplikasi, kirim, klik banner |

