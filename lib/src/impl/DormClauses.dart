import 'package:dorm/dorm_interface.dart';
import 'package:dorm/src/impl/internals/Expressions.dart';
import 'package:dorm/src/impl/internals/PageClauses.dart';

import 'internals/OperandExpression.dart';

IDormOperandExpression col(IDormField column) => ColumnExpression(column);
IDormUnaryExpression not(IDormExpression condition) => NotClause(condition);

IDormExpression none({ Iterable<IDormExpression>? conditions }) {
  if (conditions == null || conditions.isEmpty) return NoneExpression();
  var condition = conditions.first;
  for (var otherCondition in conditions.skip(1)) {
    condition = condition.and(not(otherCondition));
  }
  return condition;
} 

IDormExpression all({ Iterable<IDormExpression>? conditions }) {
  if (conditions == null || conditions.isEmpty) return AllExpression();
  var condition = conditions.first;
  for (var otherCondition in conditions.skip(1)) {
    condition = condition.and(otherCondition);
  }
  return condition;
}

IDormExpression any({ Iterable<IDormExpression>? conditions }) {
  if (conditions == null || conditions.isEmpty) return AllExpression();
  var condition = conditions.first;
  for (var otherCondition in conditions.skip(1)) {
    condition = condition.or(otherCondition);
  }
  return condition;
}

IDormPageClause limit(int max) => LimitClause(AllExpression(), max: max);
IDormPageClause startAt(int startAt) => OffsetClause(AllExpression(), startAt: startAt);
