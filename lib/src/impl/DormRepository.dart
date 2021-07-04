import 'package:dorm/dorm_interface.dart';

import 'internals/extensions.dart';
import 'internals/LinkKeyMap.dart';

typedef PostMaterializer<K, T extends IDormEntity<K>> = Future Function(IDormTransaction transaction, Iterable<T> entities);

abstract class DormRepository<K, T extends IDormEntity<K>> implements IDormRepository<K, T> {
  DormRepository(this.dataContext);

  @override
  final Type keyType = K;

  @override
  final Type entityType = T;

  @override
  final IDormDataContext dataContext;
  
  late final IDormModel<K, T> model = dataContext.db.getModel<K, T>();

  IDormEntityCache<K, T>? cache;

  void _addToCache(T entity) => dataContext.tracker.track<T>(entity);
  T? _getFromCache(K key) => cache?.get(key) ?? dataContext.tracker.get<K, T>(key);
  void _removeFromCache(T entity) => dataContext.tracker.untrack<T>(entity);

  void removeAllFromCache(bool Function(T entity) predicate) => dataContext.tracker.untrackAll<T>(predicate);

  @override
  Iterable<K> keys(List list) => list.cast<K>();

  PostMaterializer<K, T>? postMaterializer;

  Future _linkLoader(IDormTransaction transaction, Iterable<T> entities, DormLinkSelector<T> linkSelectors) async {
    final keyMap = <IDormRepository, LinkKeyMap<K, T>>{};
    for (var entity in entities) {
      final links = linkSelectors(entity);
      for (var link in links) {
        if (link is IDormEntityRef) {
          if (link.needsLoad) {
            var repo = link.getRepository(dataContext);
            LinkKeyMap<K, T>? map;
            map = keyMap[repo];
            if (map == null) {
              map = LinkKeyMap<K, T>(repo, link.joinColumn);
              keyMap[repo] = map;
            }
            map.keys.add(link.key);
          }
        } else if (link is IDormEntitySet) {
          if (entity.key != null && link.needsLoad) {
            var repo = link.getRepository(dataContext);
            LinkKeyMap<K, T>? map;
            map = keyMap[repo];
            if (map == null) {
              map = LinkKeyMap<K, T>(repo, link.joinColumn);
              keyMap[repo] = map;
            }
            map.keys.add(entity.key);
          }
        }
      }
    }

    if (keyMap.isNotEmpty) {
      final futures = <Future>[];
      for (var keyMap in keyMap.values) {
        futures.add(keyMap.preload(transaction, entities));
      }
      await Future.wait(futures);
    }
  }

  Future eagerMaterializer(IDormTransaction transaction, Iterable<T> entities) {
    return _linkLoader(transaction, entities, (T e) => e.getLinks());
  }

  Iterable<T> _materialize(Iterable<DormRecord> items) {
    final entities = <T>[];
    for (var item in items) {
      final key = item[model.key.name];
      var entity = _getFromCache(key);
      if (entity == null) {
        entity = model.unmap(dataContext.db, item);
        _addToCache(entity);
      }
      entities.add(entity);
    }
    return entities;
  }

  @override
  Future<int> count(IDormTransaction transaction, [ IDormClause? whereClause ]) {
    return transaction.dbCount<K, T>(whereClause);
  }

  @override
  Future<bool> any(IDormTransaction transaction, [ IDormClause? whereClause ]) {
    return transaction.dbAny<K, T>(whereClause);
  }

  Future<Iterable<T>> dbLoad(IDormTransaction transaction, IDormClause? whereClause) async {
    final items = await transaction.dbLoad<K, T>(whereClause);
    var entities = _materialize(items);
    if (postMaterializer != null) {
      await postMaterializer!(transaction, entities);
    } else if (_linkSelector != null) {
      await _linkLoader(transaction, entities, _linkSelector!);
    }
    return entities;
  }

  Future<Iterable<T>> dbLoadByKeys(IDormTransaction transaction, Iterable<K> keys) async {
    var entities = <T>[];
    if (keys.isNotEmpty) {
      final missingKeys = <K>[];
      for (var key in keys) {
        final entity = _getFromCache(key);
        if (entity != null) {
          entities.add(entity);
        } else {
          missingKeys.add(key);
        }
      }
      if (entities.isNotEmpty && postMaterializer != null) {
        await postMaterializer!(transaction, entities);
      }
      if (missingKeys.isNotEmpty) {
        entities.addAll(await dbLoad(transaction, model.key.inList(missingKeys)));
      }
    }
    return entities;
  }

  Future dbUpsert(IDormTransaction transaction, T entity) async {
    if (dataContext.hasChanges(entity)) {
      final map = model.map(dataContext.db, entity);
      entity.key = await transaction.dbUpsert<K, T>(map);
      _removeFromCache(entity);
      _addToCache(entity);
    }
  }

  Future dbDeleteByKeys(IDormTransaction transaction, Iterable<K> keys) async {
    if (keys.isNotEmpty) {
      final whereClause = model.key.inList(keys);
      await transaction.dbDelete<K, T>(whereClause);
      removeAllFromCache((item) => keys.contains(item.key));
    }
  }

  @override
  Future<T?> findByKey(IDormTransaction transaction, K key) async {
    var entity = _getFromCache(key);
    if (entity != null) return Future.value(entity);
    return dbLoadByKeys(transaction, [ key ]).then((results) => results.singleOrNull);
  }

  @override
  Future load(IDormTransaction transaction, T entity) => eagerMaterializer(transaction, [ entity ]);

  @override
  Future<Iterable<K>> loadKeys(IDormTransaction transaction, [ IDormClause? whereClause ]) => transaction.dbLoadKeys<K, T>(whereClause);

  @override
  Future<Iterable<T>> loadMany(IDormTransaction transaction, [ IDormClause? whereClause ]) => dbLoad(transaction, whereClause);

  @override
  Future<Iterable<T>> loadByKeys(IDormTransaction transaction, Iterable<K> keys) => dbLoadByKeys(transaction, keys);

  @override
  Future<T?> loadByKey(IDormTransaction transaction, K  key) => dbLoadByKeys(transaction, [ key ]).then((stamps) => stamps.singleOrNull);

  @override
  Future save(IDormTransaction transaction, T entity) async {
    model.check(entity);
    final links = entity.getLinks().where((e) => e.needsSave).toList();
    if (links.isNotEmpty) {
      for (var i = 0; i < links.length; i++) {
        final link = links[i];
        if (link is IDormEntityRef && link.needsSave && !link.nullable) {
          final repo = link.getRepository(dataContext);
          await repo.save(transaction, link.entity!);
        }
      }
    }

    await dbUpsert(transaction, entity);

    if (links.isNotEmpty) {
      for (var i = 0; i < links.length; i++) {
        final link = links[i];
        if (link is IDormEntityRef && link.needsSave) {
          final repo = link.getRepository(dataContext);
          await repo.save(transaction, link.entity!);
        } else if (link is IDormEntitySet) {
          final repo = link.getRepository(dataContext);
          for (var ref in link.entityRefs.where((e) => e.needsSave)) {
            await repo.save(transaction, ref.entity!);
          }
        }
      }
    }
  }

  @override
  Future saveMany(IDormTransaction transaction, Iterable<T> entities) async {
    if (entities.isNotEmpty) {
      for (var entity in entities) {
        model.check(entity);
      }
      final futures = <Future>[];
      for (var entity in entities) {
        futures.add(save(transaction, entity));
      }
      await Future.wait(futures);
    }
  }

  @override
  Future deleteByKeys(IDormTransaction transaction, Iterable<K> keys) => dbDeleteByKeys(transaction, keys);

  @override
  Future deleteByKey(IDormTransaction transaction, K key) => dbDeleteByKeys(transaction, [ key ]);

  @override
  Future delete(IDormTransaction transaction, Iterable<T> entities) {
    if (entities.isNotEmpty) {
      final keys = entities.map((e) => e.key).whereNotNull().toList();
      return dbDeleteByKeys(transaction, keys);
    } else {
      return Future.value(null);
    }
  }

  DormRepository<K, T> create();

  DormRepository<K, T> clone() {
    final repo = create();
    repo.postMaterializer = postMaterializer;
    repo._linkSelector = _linkSelector;
    repo.cache = cache;
    return repo;
  }

  @override
  IDormRepository<K, T> eager() {
    if (postMaterializer != null) {
      return this;
    } else {
      final repo = clone();
      repo.postMaterializer = eagerMaterializer;
      return repo;
    }
  }

  @override
  IDormRepository<K, T> lazy() {
    if (postMaterializer == null && _linkSelector == null) {
      return this;
    } else {
      final repo = clone();
      repo.postMaterializer = null;
      repo._linkSelector = null;
      return repo;
    }
  }

  @override
  IDormRepository<K, T> withCache(IDormEntityCache<K, T> cache) {
    final repo = clone();
    repo.cache = cache;
    return repo;
  }

  DormLinkSelector<T>? _linkSelector;

  @override
  IDormRepository<K, T> include(DormLinkSelector<T> linkSelector) {
    final repo = clone();
    final currentLinkSelector = repo._linkSelector;
    if (currentLinkSelector == null) {
      repo._linkSelector = linkSelector;
    } else {
      repo._linkSelector = (T e) => currentLinkSelector(e).followedBy(linkSelector(e));
    }
    return repo;
  }
}
