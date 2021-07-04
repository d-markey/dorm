import 'package:dorm/dorm_interface.dart';

import 'DormTracker.dart';

class DormDataContext extends IDormDataContext {
  DormDataContext(this.db, this._repositoryFactory) : _tracker = DormTracker(db);

  @override
  final IDormDatabase db;

  final IDormTracker _tracker;
  final IDormRepositoryFactory _repositoryFactory;
  final _repositories = <Type, IDormRepository>{};
  final _caches = <Type, IDormEntityCache>{};
  final _includes = <Type, DormLinkSelector<IDormEntity>>{};
  final _eagerFlags = <Type, bool>{};

  @override
  IDormTracker get tracker => _tracker;

  @override
  IDormDataContext withCache<K, T extends IDormEntity<K>>(IDormEntityCache<K, T> cache) {
    _caches[T] = cache;
    return this;
  }

  @override
  IDormDataContext include<T extends IDormEntity>(DormLinkSelector<T> linkSelector) {
    var includes = _includes[T];
    if (includes == null) {
      _includes[T] = (IDormEntity e) => linkSelector(e as T);
    } else {
      _includes[T] = (IDormEntity e) => includes(e as T).followedBy(linkSelector(e));
    }
    return this;
  }

  @override
  IDormDataContext eager<T extends IDormEntity>() {
    final eager = _eagerFlags[T] ?? false;
    if (!eager) {
      _eagerFlags[T] = true;
    }
    return this;
  }

  @override
  IDormRepository<K, T> repository<K, T extends IDormEntity<K>>() {
    var repo = _repositories[T] as IDormRepository<K, T>?;
    if (repo == null) {
      repo = _repositoryFactory.build<K, T>(this);
      final cache = _caches[T] as IDormEntityCache<K, T>?;
      if (cache != null) {
        repo = repo.withCache(cache);
      }
      final eager = _eagerFlags[T] ?? false;
      if (eager) {
        repo = repo.eager();
      } else {
        final includes = _includes[T];
        if (includes != null) {
          repo = repo.include(includes);
        }
      }
      _repositories[T] = repo;
    }
    return repo;
  }

  @override
  Future<T> transaction<T>(DormWorker<T> work) => db.transaction(work);

  @override
  Future<T> readonly<T>(DormWorker<T> work) => db.readonly(work);

  @override
  bool hasChanges<T extends IDormEntity>(T entity) => _tracker.hasChanges(entity);

  @override
  void dispose() {
    _repositories.clear();
    _caches.clear();
    _includes.clear();
    _eagerFlags.clear();
    _tracker.dispose();
  }
}
