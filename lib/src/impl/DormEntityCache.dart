import 'package:dorm/dorm_interface.dart';

class DormEntityCache<K, T extends IDormEntity<K>> implements IDormEntityCache<K, T> {
  final _cache = <K, T>{};

  Iterable<T> get values => _cache.values;

  @override
  T? get(K key) => _cache[key];

  @override
  void register(T entity) => _cache[entity.key!] = entity;
}
