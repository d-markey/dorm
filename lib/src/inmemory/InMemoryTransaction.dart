import 'package:dorm/dorm.dart';

import 'InMemoryDatabase.dart';
import 'InMemoryQuery.dart';
import 'KeyTracker.dart';

typedef DeferredChange = void Function();

class InMemoryTransaction implements IDormTransaction {
  InMemoryTransaction(this.db) : _deferredChanges = <DeferredChange>[];

  InMemoryTransaction.readonly(this.db) : _deferredChanges = null;

  void commit() {
    if (_deferredChanges == null) {
      throw DormException('No active transaction');
    }
    for (var deferredChange in _deferredChanges!) {
      deferredChange();
    }
    _deferredChanges!.clear();
  }

  void rollback() {
    if (_deferredChanges == null) {
      throw DormException('No active transaction');
    }
    _deferredChanges!.clear();
  }

  @override
  final InMemoryDatabase db;

  final List<DeferredChange>? _deferredChanges;

  static final Future _completed = Future.value(null);

  @override
  Future createTable<K, T extends IDormEntity<K>>(IDormModel<K, T> model, { required Iterable<IDormField<T>> columns, Iterable<IDormIndex<T>>? indexes  }) {
    db.createCollection<K, T>(model);
    return _completed;
  }

  @override
  Future addColumns<K, T extends IDormEntity<K>>(IDormModel<K, T> model, { required Iterable<IDormField<T>> columns, Iterable<IDormIndex<T>>? indexes }) {
    return _completed;
  }

  @override
  Future addIndexes<K, T extends IDormEntity<K>>(IDormModel<K, T> model, { required Iterable<IDormIndex<T>>? indexes }) {
    return _completed;
  }

  @override
  Future deleteTable<K, T extends IDormEntity<K>>(IDormModel<K, T> model) {
    db.deleteCollection<K, T>(model);
    return _completed;
  }

  @override
  Future deleteIndexes<K, T extends IDormEntity<K>>(IDormModel<K, T> model, Iterable<IDormIndex<T>> indexNames) {
    return _completed;
  }

  @override
  Future deleteColumns<K, T extends IDormEntity<K>>(IDormModel<K, T> model, Iterable<IDormField<T>> columnName) {
    return _completed;
  }

  @override
  Future renameTable<K, T extends IDormEntity<K>>(IDormModel<K, T> model, String name, String newName) {
    db.renameCollection<K, T>(name, newName);
    return _completed;
  }

  final _keyTracker = KeyTracker();

  @override
  bool isTracked(Type entityType, dynamic key) => _keyTracker.isTracked(entityType, key);

  @override
  Future<int> dbCount<K, T extends IDormEntity<K>>([ IDormClause? expr ]) {
    final coll = db.getCollection<K, T>();
    final query = InMemoryQuery(expr ?? all());
    return Future.value(query.find(coll.items).length);
  }

  @override
  Future<bool> dbAny<K, T extends IDormEntity<K>>([ IDormClause? expr ]) {
    final coll = db.getCollection<K, T>();
    final query = InMemoryQuery(expr ?? all());
    return Future.value(query.find(coll.items).isNotEmpty);
  }

  @override
  Future<Iterable<K>> dbLoadKeys<K, T extends IDormEntity<K>>([ IDormClause? expr ]) {
    final coll = db.getCollection<K, T>();
    final query = InMemoryQuery(expr ?? all());
    final model = db.getModel<K, T>();
    final matches = <K>[];
    for (var item in query.find(coll.items)) {
      matches.add(item[model.key.name]);
    }
    return Future.value(matches);
  }

  @override
  Future<Iterable<DormRecord>> dbLoad<K, T extends IDormEntity<K>>([ IDormClause? expr ]) {
    final coll = db.getCollection<K, T>();
    final query = InMemoryQuery(expr ?? all());
    final model = db.getModel<K, T>();
    final matches = <DormRecord>[];
    for (var item in query.find(coll.items)) {
      _keyTracker.track(T, item[model.key.name]);
      matches.add(item);
    }
    return Future.value(matches);
  }

  @override
  Future dbDelete<K, T extends IDormEntity<K>>(IDormClause expr) {
    final coll = db.getCollection<K, T>();
    final query = InMemoryQuery(expr);
    final model = db.getModel<K, T>();
    final changes = <DeferredChange>[];
    for (var item in query.find(coll.items)) {
      final key = item[model.key.name];
      changes.add(() => coll.delete(key));
    }
    if (_deferredChanges == null) {
      for (var change in changes) {
        change();
      }
    } else {
      _deferredChanges!.addAll(changes);
    }
    return _completed;
  }

  @override
  Future<K> dbUpsert<K, T extends IDormEntity<K>>(DormRecord item) {
    final model = db.getModel<K, T>();
    var key = item[model.key.name];
    if (key == null) {
      if (model.key.name != db.defaultKeyName) {
        throw DormException('Cannot upsert a record without an empty custom key');
      }
      key = db.getNextKey();
    }
    final coll = db.getCollection<K, T>();
    if (_deferredChanges == null) {
      coll.upsert(key, item);
    } else {
      _deferredChanges!.add(() => coll.upsert(key, item));
    }
    return Future.value(key);
  }

  void dispose() {    
    if (_deferredChanges != null && _deferredChanges!.isNotEmpty) {
      throw DormException('A transaction is pending');
    }
    _keyTracker.dispose();
  }
}
