import 'package:dorm/dorm_interface.dart';

class _TrackedItem {
  _TrackedItem(IDormDatabase db, this.entity) {
    final model = db.getModelFor(entity.runtimeType);
    _values = model.map(db, entity);
  }

  final IDormEntity entity;
  late final DormRecord _values;

  @override
  String toString() => '$entity (${entity.hashCode})';

  bool hasChanges(IDormDatabase db, IDormEntity entity) {
    final model = db.getModelFor(entity.runtimeType);
    final values = model.map(db, entity);
    for (var keys in values.keys) {
      if (values[keys] != _values[keys]) {
        return true;
      }
    }
    return false;
  }
}

class DormTracker implements IDormTracker {
  DormTracker(this._db);

  final IDormDatabase _db;
  final _cache = <String, _TrackedItem>{};

  String _getKey(Type type, dynamic key) => '$type/$key';

  @override
  T? get<K, T extends IDormEntity<K>>(K key) {
    final k = _getKey(T, key);
    final tracked = _cache[k];
    if (tracked == null) {
      return null;
    } else {
      return tracked.entity as T;
    }
  }

  String _getItemKey<K, T extends IDormEntity<K>>(T entity) => _getKey(T, entity.key);

  @override
  void track<T extends IDormEntity>(T entity) {
    if (entity.key != null) {
      final key = _getItemKey(entity);
      if (!_cache.containsKey(key)) {
        _cache[key] = _TrackedItem(_db, entity);
      }
    }
  }

  @override
  void untrack<T extends IDormEntity>(T entity) {
    final k = _getItemKey(entity);
    _cache.remove(k);
  }

  @override
  void untrackAll<T extends IDormEntity>(bool Function(T entity) predicate) {
    final keyPrefix = '$T/';
    var keys = _cache.entries.where((e) => e.key.startsWith(keyPrefix) && predicate(e.value.entity as T)).map((e) => e.key).toList();
    _cache.removeWhere((key, value) => keys.contains(key));
  }

  @override
  Future<Iterable<T>> find<T extends IDormEntity>(bool Function(T entity) predicate) {
    final keyPrefix = '$T/';
    return Future.value(_cache.entries.where((e) => e.key.startsWith(keyPrefix)).map((e) => e.value.entity as T).where(predicate));
  }

  @override
  bool hasChanges<T extends IDormEntity>(T entity) {
    final k = _getKey(T, entity.key);
    final tracked = _cache[k];
    if (tracked == null) return true;
    return tracked.hasChanges(_db, entity);
  }

  @override
  void dispose() {
    _cache.clear();
  }
}
