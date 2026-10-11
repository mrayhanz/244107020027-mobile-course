import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  @override
  Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements() async {
    try {
      final items = [
        AnnouncementModel(
          id: '1',
          title: 'Pengumuman Perkuliahan',
          content: 'Ujian Tengah Semester dimulai minggu depan.',
          createdAt: DateTime.now(),
        ),
      ];
      return (announcements: items.map((e) => e.toEntity()).toList(), failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(String id) async {
    try {
      final model = AnnouncementModel(
        id: id,
        title: 'Pengumuman #$id',
        content: 'Detail pengumuman dengan ID $id',
        createdAt: DateTime.now(),
      );
      return (announcement: model.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Pengumuman tidak ditemukan: $e'),
      );
    }
  }
}
