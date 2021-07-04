import 'IDormClauses.dart';
import 'IDormField.dart';
import 'IDormDatabase.dart';
import 'IDormEntity.dart';
import 'IDormIndex.dart';
import 'IDormModel.dart';

abstract class IDormTransaction {
  IDormDatabase get db;

  Future createTable<K, T extends IDormEntity<K>>(IDormModel<K, T> model, { required Iterable<IDormField<T>> columns, Iterable<IDormIndex<T>>? indexes  });
  Future addColumns<K, T extends IDormEntity<K>>(IDormModel<K, T> model, { required Iterable<IDormField<T>> columns, Iterable<IDormIndex<T>>? indexes });
  Future addIndexes<K, T extends IDormEntity<K>>(IDormModel<K, T> model, { required Iterable<IDormIndex<T>>? indexes });

  Future deleteTable<K, T extends IDormEntity<K>>(IDormModel<K, T> model);
  Future deleteIndexes<K, T extends IDormEntity<K>>(IDormModel<K, T> model, Iterable<IDormIndex<T>> indexNames);
  Future deleteColumns<K, T extends IDormEntity<K>>(IDormModel<K, T> model, Iterable<IDormField<T>> columnName);

  Future renameTable<K, T extends IDormEntity<K>>(IDormModel<K, T> model, String name, String newName);

  bool isTracked(Type entityType, dynamic key);

  Future<int> dbCount<K, T extends IDormEntity<K>>([ IDormClause? expr ]);
  Future<bool> dbAny<K, T extends IDormEntity<K>>([ IDormClause? expr ]);

  Future<Iterable<K>> dbLoadKeys<K, T extends IDormEntity<K>>([ IDormClause? expr ]);
  Future<Iterable<DormRecord>> dbLoad<K, T extends IDormEntity<K>>([ IDormClause? expr ]);
  Future dbDelete<K, T extends IDormEntity<K>>(IDormClause expr);
  Future<K> dbUpsert<K, T extends IDormEntity<K>>(DormRecord item);
}
