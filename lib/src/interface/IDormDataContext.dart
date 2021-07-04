import 'IDormDatabase.dart';
import 'IDormEntity.dart';
import 'IDormEntityCache.dart';
import 'IDormEntityLink.dart';
import 'IDormRepository.dart';
import 'IDormTracker.dart';

abstract class IDormDataContext {
  IDormDatabase get db;
  IDormTracker get tracker;

  Future<T> transaction<T>(DormWorker<T> work);
  Future<T> readonly<T>(DormWorker<T> work);

  IDormRepository<K, T> repository<K, T extends IDormEntity<K>>();

  bool hasChanges<T extends IDormEntity>(T entity);

  IDormDataContext withCache<K, T extends IDormEntity<K>>(IDormEntityCache<K, T> cache);
  IDormDataContext include<T extends IDormEntity>(DormLinkSelector<T> linkSelector);
  IDormDataContext eager<T extends IDormEntity>();

  void dispose();
}
