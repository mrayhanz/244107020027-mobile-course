import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure, bool hasMore})>
  getAnnouncements({int page = 1});
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );
}
