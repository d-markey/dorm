import 'IDormEntity.dart';
import 'IDormModel.dart';
import 'IDormTransaction.dart';

typedef DormRecord = Map<String, dynamic>;

typedef DormWorker<T> = Future<T> Function(IDormTransaction transaction);

abstract class IDormDatabase {
  String get defaultKeyName;

  void registerModel<K, T extends IDormEntity<K>>(IDormModel<K, T> model);
  IDormModel<K, T> getModel<K, T extends IDormEntity<K>>();
  IDormModel getModelFor(Type entityType);

  Future<T> transaction<T>(DormWorker<T> work);
  Future<T> readonly<T>(DormWorker<T> work);

  T? castFromDb<T>(dynamic value);
  dynamic castToDb(dynamic value);

  void dispose();
}
