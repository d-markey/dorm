import 'package:dorm/dorm_interface.dart';

import 'PageClauses.dart';

abstract class ChainableClause implements IDormChainableClause {
  @override
  IDormChainableClause limit(int max) => LimitClause(this, max: max); 

  @override
  IDormChainableClause skip(int startAt) => OffsetClause(this, startAt: startAt);

  @override
  IDormExpression and(IDormExpression clause) => AndClause(this, clause);

  @override
  IDormExpression or(IDormExpression clause) => OrClause(this, clause);
}

abstract class Expression extends ChainableClause implements IDormExpression { }

class AllExpression extends Expression implements IDormZeroaryExpression {
  @override
  final op = DormExpressionOperator.All;
}

class NoneExpression extends Expression {
  @override
  final op = DormExpressionOperator.None;
}

class NotClause extends Expression implements IDormUnaryExpression {
  NotClause(this.expression): super();

  @override
  final IDormChainableClause expression;

  @override
  final op = DormExpressionOperator.Not;
}

abstract class BinaryExpression extends Expression implements IDormBinaryExpression {
  BinaryExpression(this.left, this.right) : super();

  @override
  final IDormChainableClause left;

  @override
  final IDormChainableClause right;
}

class AndClause extends BinaryExpression implements IDormBinaryExpression {
  AndClause(IDormChainableClause left, IDormChainableClause right) : super(left, right);

  @override
  final op = DormExpressionOperator.And;
}

class OrClause extends BinaryExpression implements IDormBinaryExpression {
  OrClause(IDormChainableClause left, IDormChainableClause right) : super(left, right);

  @override
  final op = DormExpressionOperator.Or;
}
