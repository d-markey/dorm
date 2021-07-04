import 'IDormEntity.dart';

abstract class IDormEntityCache<K, T extends IDormEntity<K>> {
  T? get(K key);
  void register(T entity);
}
