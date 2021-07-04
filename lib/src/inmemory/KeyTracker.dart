class KeyTracker {
  KeyTracker();

  final _cache = <String, bool>{};

  String _getKey(Type entityType, dynamic key) => '$entityType/$key';

  bool isTracked(Type entityType, dynamic key) {
    final k = _getKey(entityType, key);
    return _cache[k] ?? false;
  }

  void track(Type entityType, dynamic key) {
    final k = _getKey(entityType, key);
    _cache[k] = true;
  }

  void dispose() {
    _cache.clear();
  }
}
