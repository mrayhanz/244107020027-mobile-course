import 'dart:async';

/// Menunda eksekusi callback sampai input berhenti berubah.
///
/// Dipakai pada kolom pencarian agar filter daftar tidak dijalankan pada setiap
/// ketikan (setiap karakter memicu rebuild + filter seluruh list).
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  Timer? _timer;

  bool get isPending => _timer?.isActive ?? false;

  /// Jadwalkan [action]; panggilan berikutnya membatalkan jadwal sebelumnya.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Batalkan callback yang belum sempat berjalan.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Wajib dipanggil saat owner (Notifier/State) di-dispose.
  void dispose() => cancel();
}
