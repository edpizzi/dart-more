typedef LoaderImmediate<K, V> = Future<V> Function(K key);

class CacheItemImmedate<V> {
  CacheItemImmedate(this.future);
  Future<V>? future;
  V? value;

  void complete(V value) {
    this.value = value;
    future = null;
  }

  Future<V> wait() async {
    final future = this.future;
    if (future != null) {
      return future;
    }
    return value!;
  }
}

class LruImmediateCache<K, V> {
  LruImmediateCache(this.loader, this.maximumSize)
    : assert(maximumSize > 0, 'Maximum size must be positive.');

  final LoaderImmediate<K, V> loader;

  final int maximumSize;

  final Map<K, CacheItemImmedate<V>> cached = {};

  V? getIfPresent(K key) {
    final entry = promote(key);
    return entry?.value;
  }

  Future<V> get(K key) async {
    var item = promote(key);
    if (item == null) {
      final loadFuture = loader(key);
      item = CacheItemImmedate(loadFuture);
      cached[key] = item;
      cleanUp();
      final value = await loadFuture;
      item.complete(value);
    }
    return item.wait();
  }

  /*
  Future<V> set(K key, FutureOr<V> value) async {
    var item = promote(key);
    if (item == null) {
      item = cached[key] = CacheItem(value);
      cleanUp();
    } else {
      item.value = value;
    }
    return value;
  }
  */

  int size() => cached.length;

  void invalidate(K key) => cached.remove(key);

  void invalidateAll() => cached.clear();

  CacheItemImmedate<V>? promote(K key) {
    final item = cached.remove(key);
    if (item != null) {
      cached[key] = item;
    }
    return item;
  }

  void cleanUp() {
    while (cached.length > maximumSize) {
      cached.remove(cached.keys.first);
    }
  }
}
