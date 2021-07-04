import 'package:dorm/dorm_interface.dart';

import 'DormClauses.dart';

class DormField<T extends IDormEntity> implements IDormField<T> {
  DormField(this.name, { required this.type, this.unique = false });

  @override
  final Type entityType = T;

  @override
  final String name;

  @override
  final String type;

  @override
  final bool unique;

  @override
  late final bool nullable = type.endsWith('?');

  late final _expr = col(this);  

  @override
  IDormExpression equals<V>(V value) => _expr.equals(value);

  @override
  IDormExpression isNotEqual<V>(V value) => _expr.isNotEqual(value);

  @override
  IDormExpression isNull() => _expr.isNull();

  @override
  IDormExpression isNotNull() => _expr.isNotNull();

  @override
  IDormExpression lessThan<V>(V value) => _expr.lessThan(value);

  @override
  IDormExpression lessOrEqual<V>(V value) => _expr.lessOrEqual(value);

  @override
  IDormExpression moreThan<V>(V value) => _expr.moreThan(value);

  @override
  IDormExpression moreOrEqual<V>(V value) => _expr.moreOrEqual(value);

  @override
  IDormExpression contains(String text) => _expr.contains(text);

  @override
  IDormExpression startsWith(String text) => _expr.contains(text);

  @override
  IDormExpression endsWith(String text) => _expr.contains(text);

  @override
  IDormExpression inList<V>(Iterable<V> values) => _expr.inList(values);

  @override
  IDormExpression notInList<V>(Iterable<V> values) => _expr.notInList(values);

  @override
  IDormExpression inRange<V>({ V? min, V? max }) => _expr.inRange(min: min, max: max);

  @override
  IDormExpression notInRange<V>({ V? min, V? max }) => _expr.notInRange(min: min, max: max);

  @override
  IDormOperandExpression toLower() => _expr.toLower();

  @override
  IDormOperandExpression trim() => _expr.trim();

  @override
  IDormOperandExpression length() => _expr.length();

  @override
  bool isColumn(IDormField column) {
    return (entityType == column.entityType) && (name.toLowerCase() == column.name.toLowerCase());
  }

  @override
  String toString() {
    return '$entityType.$name $type${unique ? ' UNIQUE' : ''}${nullable ? '' : ' NOT NULL'}';
  }
}
