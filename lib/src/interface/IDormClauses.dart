import 'package:dorm/dorm_interface.dart';

abstract class IDormClause { }

abstract class IDormChainableClause extends IDormClause {
  IDormChainableClause limit(int max);
  IDormChainableClause skip(int offset);
  IDormExpression and(IDormExpression clause);
  IDormExpression or(IDormExpression clause);
}

abstract class IDormPageClause extends IDormChainableClause { }

abstract class IDormLimitClause extends IDormPageClause {
  int get max;
  IDormChainableClause get clause;
}

abstract class IDormOffsetClause extends IDormPageClause {
  int get startAt;
  IDormChainableClause get clause;
}

abstract class IDormExpression extends IDormChainableClause {
  DormExpressionOperator get op;
}

abstract class IDormZeroaryExpression extends IDormExpression {
}

abstract class IDormUnaryExpression extends IDormExpression {
  IDormChainableClause get expression;
}

abstract class IDormBinaryExpression extends IDormExpression {
  IDormChainableClause get left;
  IDormChainableClause get right;
}

mixin DormOperandMixin {
  IDormExpression isNull();
  IDormExpression isNotNull();

  IDormExpression equals<T>(T value);
  IDormExpression isNotEqual<T>(T value);

  IDormExpression lessThan<T>(T value);
  IDormExpression lessOrEqual<T>(T value);
  IDormExpression moreThan<T>(T value);
  IDormExpression moreOrEqual<T>(T value);

  IDormExpression contains(String text);
  IDormExpression startsWith(String text);
  IDormExpression endsWith(String text);

  IDormExpression inList<T>(Iterable<T> values);
  IDormExpression notInList<T>(Iterable<T> values);

  IDormExpression inRange<T>({ T? min, T? max });
  IDormExpression notInRange<T>({ T? min, T? max });

  IDormOperandExpression toLower();
  IDormOperandExpression trim();
  IDormOperandExpression length();
}

abstract class IDormOperandExpression extends IDormClause with DormOperandMixin {
  IDormOperandExpression? get operand;
  DormExpressionOperator? get op;
}

abstract class IDormColumnExpression extends IDormOperandExpression {
  IDormField get column;
}

abstract class IDormComparisonExpression<T> extends IDormExpression {
  IDormOperandExpression get operand;
  T? get value;
}

abstract class IDormRangeExpression<T> extends IDormExpression {
  IDormOperandExpression get operand;
  T? get min;
  T? get max;
}

enum DormExpressionOperator {
  None,
  All,
  And,
  Or,
  Not,
  IsNull,
  IsNotNull,
  Equals,
  IsNotEqual,
  LessThan,
  LessOrEqual,
  MoreThan,
  MoreOrEqual,
  Contains,
  StartsWith,
  EndsWith,
  InList,
  NotInList,
  InRange,
  NotInRange,
  ToLower,
  Trim,
  Length,
}
