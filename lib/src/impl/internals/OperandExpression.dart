
import 'package:dorm/dorm_interface.dart';
import 'package:dorm/src/impl/internals/ComparisonExpressions.dart';

abstract class DormOperandExpression implements IDormOperandExpression {
  @override
  IDormExpression isNull() => ComparisonExpression(this, DormExpressionOperator.IsNull);

  @override
  IDormExpression isNotNull() => ComparisonExpression(this, DormExpressionOperator.IsNotNull);

  @override
  IDormExpression equals<T>(T value) => ComparisonExpression(this, DormExpressionOperator.Equals, value);

  @override
  IDormExpression isNotEqual<T>(T value) => ComparisonExpression(this, DormExpressionOperator.IsNotEqual, value);

  @override
  IDormExpression lessThan<T>(T value) => ComparisonExpression(this, DormExpressionOperator.LessThan, value);

  @override
  IDormExpression lessOrEqual<T>(T value) => ComparisonExpression(this, DormExpressionOperator.LessOrEqual, value);

  @override
  IDormExpression moreThan<T>(T value) => ComparisonExpression(this, DormExpressionOperator.MoreThan, value);

  @override
  IDormExpression moreOrEqual<T>(T value) => ComparisonExpression(this, DormExpressionOperator.MoreOrEqual, value);

  @override
  IDormExpression contains(String text) => ComparisonExpression(this, DormExpressionOperator.Contains, text);

  @override
  IDormExpression startsWith(String text) => ComparisonExpression(this, DormExpressionOperator.StartsWith, text);

  @override
  IDormExpression endsWith(String text) => ComparisonExpression(this, DormExpressionOperator.EndsWith, text);

  @override
  IDormExpression inList<T>(Iterable<T> values) => ComparisonExpression(this, DormExpressionOperator.InList, values);

  @override
  IDormExpression notInList<T>(Iterable<T> values) => ComparisonExpression(this, DormExpressionOperator.NotInList, values);

  @override
  IDormExpression inRange<T>({ T? min, T? max }) => RangeExpression(this, DormExpressionOperator.InRange, min: min, max: max);

  @override
  IDormExpression notInRange<T>({ T? min, T? max }) => RangeExpression(this, DormExpressionOperator.NotInRange, min: min, max: max);

  @override
  IDormOperandExpression toLower() => OperandExpression(this, DormExpressionOperator.ToLower);

  @override
  IDormOperandExpression trim() => OperandExpression(this, DormExpressionOperator.Trim);

  @override
  IDormOperandExpression length() => OperandExpression(this, DormExpressionOperator.Length);
}

class ColumnExpression extends DormOperandExpression implements IDormColumnExpression {
  ColumnExpression(this.column);

  @override
  final IDormField column;

  @override
  final operand = null;

  @override
  final op = null;
}

class OperandExpression extends DormOperandExpression {
  OperandExpression(this.operand, this.op);

  @override
  final operand;

  @override
  final op;
}
