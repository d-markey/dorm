import 'IDormField.dart';
import 'IDormEntity.dart';

abstract class IDormIndex<T extends IDormEntity> {
  Iterable<IDormField<T>> get columns;
  bool get unique;
}
