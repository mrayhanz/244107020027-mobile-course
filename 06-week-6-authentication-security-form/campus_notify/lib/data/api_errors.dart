import 'package:dio/dio.dart';

String getFriendlyErrorMessage(DioException e) {
  // Menangani masalah jaringan (offline / timeout)
  if (e.type == DioExceptionType.connectionTimeout || 
      e.type == DioExceptionType.receiveTimeout || 
      e.type == DioExceptionType.connectionError) {
    return 'Koneksi terputus. Silakan periksa koneksi internet Anda.';
  }
  
  // Menangani error dari server
  if (e.response != null) {
    if (e.response?.statusCode == 401) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    if (e.response?.statusCode == 404) {
      return 'Data tidak ditemukan.';
    }
    if (e.response?.statusCode == 500) {
      return 'Terjadi gangguan pada server kampus.';
    }
  }

  return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
}