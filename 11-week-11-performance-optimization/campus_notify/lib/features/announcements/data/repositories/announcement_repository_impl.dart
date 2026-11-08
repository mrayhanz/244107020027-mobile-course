import '../../../../core/failures.dart';
import '../../../../core/performance/stale_cache.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({StaleCache<int, List<Announcement>>? cache})
    : _pageCache = cache ?? StaleCache<int, List<Announcement>>();

  final StaleCache<int, List<Announcement>> _pageCache;
  static const int pageSize = 10;
  static const int maxPages = 4;

  @override
  Future<({List<Announcement> announcements, Failure? failure, bool hasMore})>
  getAnnouncements({int page = 1}) async {
    // 1. Cek cache in-memory (stale-while-revalidate / cache-first)
    final cached = _pageCache.read(page);
    final isStale = _pageCache.isStale(page);

    if (cached != null && !isStale) {
      return (announcements: cached, failure: null, hasMore: page < maxPages);
    }

    try {
      // Simulasi fetch API paging
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (page > maxPages) {
        return (
          announcements: const <Announcement>[],
          failure: null,
          hasMore: false,
        );
      }

      final items = List.generate(pageSize, (i) {
        final index = (page - 1) * pageSize + i + 1;
        return AnnouncementModel(
          id: '$index',
          title: 'Pengumuman Akademik #$index',
          content: 'Informasi resmi kegiatan perkuliahan dan administrasi jurusan untuk semester ganjil.',
          createdAt: DateTime.now().subtract(Duration(hours: index * 2)),
          imageUrl: 'https://picsum.photos/seed/$index/300/200',
        );
      });

      final entities = items.map((e) => e.toEntity()).toList();
      _pageCache.write(page, entities);

      return (announcements: entities, failure: null, hasMore: page < maxPages);
    } catch (e) {
      // Fallback ke data stale jika jaringan bermasalah
      if (cached != null) {
        return (announcements: cached, failure: null, hasMore: page < maxPages);
      }
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
        hasMore: false,
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    try {
      final model = AnnouncementModel(
        id: id,
        title: 'Pengumuman #$id',
        content: 'Detail lengkap dan lampiran dokumen untuk pengumuman ID #$id',
        createdAt: DateTime.now(),
        imageUrl: 'https://picsum.photos/seed/$id/300/200',
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
