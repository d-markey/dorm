import 'package:dorm/dorm_interface.dart';

class LinkKeyMap<K, T extends IDormEntity<K>> {
  LinkKeyMap(this.repo, this.column);
  final IDormRepository repo;
  final IDormField column;
  final List keys = [];

  Future preload(IDormTransaction transaction, Iterable<T> entities) {
    return (column.entityType == T)
      ? preloadRefs(transaction, entities)
      : preloadSets(transaction, entities);
  }

  Future preloadRefs(IDormTransaction transaction, Iterable<T> entities) async {
    final missingKeys = [];
    for (var k in keys) {
      if (!transaction.isTracked(repo.entityType, k)) {
        missingKeys.add(k);
      }
    }
    if (missingKeys.isNotEmpty) {
      await repo.loadByKeys(transaction, repo.keys(keys));
    }
    for (var entity in entities) {
      final key = entity.getValue(column);
      if (key != null) {
        final link = entity.getLink(column) as IDormEntityRef;
        await link.load(repo.dataContext, transaction);
      }
    }
  }

  Future preloadSets(IDormTransaction transaction, Iterable<T> entities) async {
    final linkedRefs = await repo.loadMany(transaction, column.inList(keys));
    final refsByKey = <K, List<IDormEntity>>{};
    for (var ref in linkedRefs) {
      final key = ref.getValue(column) as K?;
      if (key != null) {
        var refs = refsByKey[key];
        if (refs == null) {
          refs = [];
          refsByKey[key] = refs;
        }
        refs.add(ref);
      }
    }
    final noRef = <IDormEntity>[];
    for (var entity in entities) {
      var refs = refsByKey[entity.key] ?? noRef;
      final set = entity.getLink(column) as IDormEntitySet;
      set.loadWithRefs(refs);
    }
  }
}
