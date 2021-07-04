import 'IDormClauses.dart';
import 'IDormEntity.dart';

abstract class IDormField<T extends IDormEntity> with DormOperandMixin {
  Type get entityType;
  String get name;
  String get type;
  bool get unique;
  bool get nullable;

  bool isColumn(IDormField column);
}
