import 'IDormEntity.dart';

abstract class IDormTracker {
  T? get<K, T extends IDormEntity<K>>(K key);
  void track<T extends IDormEntity>(T entity);
  void untrack<T extends IDormEntity>(T entity);
  void untrackAll<T extends IDormEntity>(bool Function(T entity) predicate);
  Future<Iterable<T>> find<T extends IDormEntity>(bool Function(T entity) predicate);
  bool hasChanges<T extends IDormEntity>(T entity);

  void dispose();
}
