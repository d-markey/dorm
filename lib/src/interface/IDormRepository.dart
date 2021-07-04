import 'IDormClauses.dart';
import 'IDormDataContext.dart';
import 'IDormEntity.dart';
import 'IDormEntityCache.dart';
import 'IDormEntityLink.dart';
import 'IDormTransaction.dart';

abstract class IDormRepository<K, T extends IDormEntity<K>> {

  IDormDataContext get dataContext;
  Type get keyType;
  Type get entityType;

  Iterable<K> keys(List list);

  Future<T?> findByKey(IDormTransaction transaction, K key);

  Future load(IDormTransaction transaction, T entity);

  Future<int> count(IDormTransaction transaction, [ IDormClause? whereClause ]);
  Future<bool> any(IDormTransaction transaction, [ IDormClause? whereClause ]);

  Future<Iterable<K>> loadKeys(IDormTransaction transaction, [ IDormClause? whereClause ]);
  Future<Iterable<T>> loadMany(IDormTransaction transaction, [ IDormClause? whereClause ]);
  Future<Iterable<T>> loadByKeys(IDormTransaction transaction, Iterable<K> keys);
  Future<T?> loadByKey(IDormTransaction transaction, K key);

  Future saveMany(IDormTransaction transaction, Iterable<T> entities);
  Future save(IDormTransaction transaction, T entity);

  Future deleteByKeys(IDormTransaction transaction, Iterable<K> keys);
  Future deleteByKey(IDormTransaction transaction, K key);
  Future delete(IDormTransaction transaction, Iterable<T> entities);

  IDormRepository<K, T> eager();
  IDormRepository<K, T> lazy();
  IDormRepository<K, T> withCache(IDormEntityCache<K, T> cache);
  IDormRepository<K, T> include(DormLinkSelector<T> linkSelector);
}
