import 'package:dorm/dorm.dart';
import 'package:dorm/src/inmemory/InMemoryCollection.dart';
import 'package:dorm/src/inmemory/InMemoryTransaction.dart';

class InMemoryDatabase extends DormDatabase {
  InMemoryDatabase(this.name);

  final String name;

  int _lastKey = 0;

  int getNextKey() {
    _lastKey++;
    return _lastKey;
  }

  final _collections = <Type, InMemoryCollection>{};

  Iterable<InMemoryCollection> get collections => _collections.values;

  InMemoryCollection<K, T> getCollection<K, T extends IDormEntity<K>>() {
    final coll = _collections[T] as InMemoryCollection<K, T>?;
    if (coll == null) throw DormException('No collection found for $T');
    return coll;
  }

  void createCollection<K, T extends IDormEntity<K>>(IDormModel model) {
    var coll = _collections[T];
    if (coll == null) {
      coll = InMemoryCollection<K, T>(model.entityName, model.key.name);
      _collections[T] = coll;
    }
  }

  void deleteCollection<K, T extends IDormEntity<K>>(IDormModel model) {
    var coll = _collections[T];
    if (coll != null) {
      if (coll.name != model.entityName) throw DormException('Collection ${model.entityName} does not exist');
      _collections.remove(T);
    }
  }

  void renameCollection<K, T extends IDormEntity<K>>(String name, String newName) {
    var coll = _collections[T];
    if (coll != null) {
      if (coll.name != name) throw DormException('Collection $name does not exist');
      coll.rename(newName);
    }
  }

  @override
  final String defaultKeyName = '__memid';

  @override
  T? castFromDb<T>(dynamic value) => value as T?;

  @override
  dynamic castToDb(dynamic value) => value;

  @override
  Future<T> transaction<T>(DormWorker<T> work) async {
    final transaction = InMemoryTransaction(this);
    try {
      final result = await work(transaction);
      transaction.commit();
      return result;
    } on Exception catch (ex) {
      transaction.rollback();
      throw DormException('An exception was raised during a transaction: $ex', inner: ex);
    } finally {
      transaction.dispose();
    }
  }

  @override
  Future<T> readonly<T>(DormWorker<T> work) {
    final transaction = InMemoryTransaction.readonly(this);
    try {
      return work(transaction);
    } finally {
      transaction.dispose();
    }
  }

  @override
  void dispose() {
  }
}
