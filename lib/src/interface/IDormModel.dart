import 'IDormField.dart';
import 'IDormDatabase.dart';
import 'IDormEntity.dart';
import 'IDormIndex.dart';

abstract class IDormModel<K, T extends IDormEntity<K>>  {
  String get entityName;
  IDormField<T> get key;
  Iterable<IDormField<T>> get columns;
  Iterable<IDormIndex<T>> get indexes;

  T unmap(IDormDatabase db, DormRecord item);
  DormRecord map(IDormDatabase db, T entity);

  void check(T entity);  
}
