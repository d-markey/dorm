import 'package:dorm/dorm_interface.dart';

import 'Expressions.dart';

class ComparisonExpression<T> extends ChainableClause implements IDormComparisonExpression {
  ComparisonExpression(this.operand, this.op, [ this.value ]);

  @override
  final operand;

  @override
  final op;

  @override
  final T? value;
}

class RangeExpression<T> extends Expression {
  RangeExpression(this.operand, this.op, { this.min, this.max });

  final IDormOperandExpression operand;

  @override
  final op;

  final T? min;
  final T? max;
}
