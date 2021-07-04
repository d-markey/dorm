import 'package:dorm/dorm_interface.dart';

import 'DormEntityRef.dart';

class DormEntitySet<K, T extends IDormEntity<K>> extends IDormEntitySet<K, T> {  
  DormEntitySet(this._join, this._joinKey);

  @override
  final entityType = T;

  final IDormField _join;
  final DormJoinKey _joinKey;

  @override
  IDormField get joinColumn => _join;

  @override
  Future load(IDormDataContext dataContext, IDormTransaction transaction) async {
    final joinKey = _joinKey();
    final repo = getRepository(dataContext);
    if (!_loaded && joinKey != null) {
      final entities = await repo.loadMany(transaction, _join.equals(joinKey));
      _refs.addAll(entities.map((e) => DormEntityRef<K, T>(_join)..entity = e));
    }
    final missingKeys = _refs.where((e) => e.needsLoad).map((e) => e.key!).toList();
    if (missingKeys.isNotEmpty) {
      await repo.loadByKeys(transaction, missingKeys);
      for (var i = 0; i < _refs.length; i++) {
        await _refs[i].load(dataContext, transaction);
      }
    }
    _loaded = (joinKey != null);
  }

  @override
  void loadWithRefs(Iterable<IDormEntity> entities) {
    _refs.clear();
    for (var entity in entities) {
      _refs.add(DormEntityRef<K, T>(_join)..entity = entity as T);
    }
    _loaded = true;
  }

  @override
  IDormRepository<K, T> getRepository(IDormDataContext dataContext) => dataContext.repository<K, T>();

  @override
  void unload() {
    if (_loaded) {
      _refs.clear();
      _loaded = false;
    }
  }

  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  bool get needsSave => (_refs.isNotEmpty) && _refs.any((e) => e.needsSave);

  @override
  bool get needsLoad => (_refs.isEmpty && !_loaded) || (_refs.isNotEmpty && _refs.any((e) => e.needsLoad));

  final _refs = <DormEntityRef<K, T>>[];

  @override
  Iterable<IDormEntityRef<K, T>> get entityRefs => _refs;

  @override
  int get length => _refs.length;

  @override
  Iterable<T?> get entities => _refs.map((e) => e.entity);

  Iterable<K?> get keys => _refs.map((e) => e.key);

  @override
  void add(T entity) => _refs.add(DormEntityRef<K, T>(_join)..entity = entity);

  void addAll(Iterable<T> entities) => _refs.addAll(entities.map((e) => DormEntityRef<K, T>(_join)..entity = e));

  @override
  void addKey(K key) => _refs.add(DormEntityRef<K, T>(_join)..key = key);

  void addAllKeys(Iterable<K> keys) => _refs.addAll(keys.map((k) => DormEntityRef<K, T>(_join)..key = k));

  @override
  void remove(T entity) {
    for (var i = 0; i < _refs.length; i++) {
      if (_refs[i].entity == entity) {
        _refs.removeAt(i);
        break;
      }
    }
  }

  @override
  void removeKey(K key) {
    for (var i = 0; i < _refs.length; i++) {
      if (_refs[i].key == key) {
        _refs.removeAt(i);
        break;
      }
    }
  }

  @override
  void copyFrom(IDormEntitySet<K, T> other) {
    if (this == other) return;
    unload();
    for (var otherRef in other.entityRefs) {
      if (otherRef.entity != null) {
        add(otherRef.entity!);
      } else if (otherRef.key != null) {
        addKey(otherRef.key!);
      }
    }
    _loaded = other.isLoaded;
  }

  @override
  String toString() => '$_refs';
}
