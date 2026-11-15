/// Cache in-memory sederhana dengan TTL untuk pola
/// stale-while-revalidate / cache-first.
///
/// Nilai yang sudah kedaluwarsa tetap bisa dibaca sebagai fallback saat
/// jaringan gagal, tetapi ditandai [isStale] agar layer data tahu kapan harus
/// mengambil data baru.
class StaleCache<K, V> {
  StaleCache({this.ttl = const Duration(minutes: 5)});

  final Duration ttl;
  final Map<K, _CacheEntry<V>> _entries = {};

  V? read(K key) => _entries[key]?.value;

  bool contains(K key) => _entries.containsKey(key);

  bool isStale(K key) {
    final entry = _entries[key];
    if (entry == null) return true;
    return DateTime.now().difference(entry.storedAt) > ttl;
  }

  void write(K key, V value) {
    _entries[key] = _CacheEntry(value, DateTime.now());
  }

  void remove(K key) => _entries.remove(key);

  void clear() => _entries.clear();

  int get length => _entries.length;
}

class _CacheEntry<V> {
  const _CacheEntry(this.value, this.storedAt);

  final V value;
  final DateTime storedAt;
}
