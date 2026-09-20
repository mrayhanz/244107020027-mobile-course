import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  // Fungsi ini menyatukan semua mapping error jaringan agar bisa dipakai
  // di halaman paged maupun non-paged. Dengan cara ini, UI tidak perlu tahu
  // detail DioException dan error tidak tersebar di banyak file.
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Waktu koneksi habis. Periksa jaringan Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan internet aktif.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) {
          return 'Data tidak ditemukan (404).';
        }
        if (code == 500) {
          return 'Server sedang bermasalah. Coba beberapa saat lagi.';
        }
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Silakan coba lagi nanti.';
        }
        return 'Server merespons dengan error $code. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }

  return 'Terjadi kesalahan tak terduga: $error';
}
