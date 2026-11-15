import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

/// Daftar pengumuman dengan infinite scroll (pagination) + image cache.
///
/// Optimasi yang diterapkan:
/// - `ListView.builder` hanya membangun item yang terlihat.
/// - `ScrollController` di-dispose untuk mencegah memory leak.
/// - `CachedNetworkImage` + `memCacheWidth/Height` agar gambar tidak di-decode
///   pada resolusi penuh.
/// - `RepaintBoundary` mengisolasi repaint tiap kartu.
class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Announcement> _items = [];

  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    // Wajib: lepas listener & controller agar tidak bocor memori.
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(getAnnouncementsProvider).call(page: _page);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      final failure = result.failure;
      if (failure != null) {
        _error = failure.message;
        return;
      }
      _items.addAll(result.announcements);
      _hasMore = result.hasMore && result.announcements.isNotEmpty;
      _page++;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman Kampus')),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return _AnnouncementsError(message: _error!, onRetry: _loadPage);
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: Text('Belum ada pengumuman.')),
        ],
      );
    }

    return ListView.builder(
      key: const Key('announcements_list'),
      controller: _scrollController,
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return _AnnouncementsFooter(isLoading: _isLoading, hasMore: _hasMore);
        }
        return RepaintBoundary(child: _AnnouncementTile(item: _items[index]));
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            CachedNetworkImage(
              imageUrl: item.imageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              // Decode sesuai ukuran tampil, bukan resolusi asli.
              memCacheWidth: 600,
              memCacheHeight: 320,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                height: 160,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsFooter extends StatelessWidget {
  const _AnnouncementsFooter({required this.isLoading, required this.hasMore});

  final bool isLoading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          hasMore
              ? 'Tarik ke bawah untuk memuat...'
              : 'Semua pengumuman sudah dimuat.',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _AnnouncementsError extends StatelessWidget {
  const _AnnouncementsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
