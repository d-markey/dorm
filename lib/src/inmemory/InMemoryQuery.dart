import 'package:dorm/dorm.dart';

typedef InMemoryPredicate = bool Function(DormRecord item);
typedef InMemoryOperand = dynamic Function(DormRecord item);

class _FindContext {
  _FindContext(this._limit, this._startAt, this._predicate);

  int _limit;
  int _startAt;
  final InMemoryPredicate _predicate;

  bool _match(DormRecord item) {
    if (_startAt > 0) {
      _startAt--;
      return false;
    }
    if (_limit == 0 || !_predicate(item)) {
      return false;
    }
    if (_limit > 0) {
      _limit--;
    }
    return true;
  }
}

class InMemoryQuery {
  InMemoryQuery(this._clause);

  final IDormClause _clause;

  late final InMemoryPredicate _predicate = _generatePredicate(_clause);
  int _pageLimit = -1;
  int _pageStartAt = 0;

  Iterable<DormRecord> find(Iterable<DormRecord> items) {
    final findContext = _FindContext(_pageLimit, _pageStartAt, _predicate);
    return items.where(findContext._match);
  }

  InMemoryPredicate _generatePredicate(IDormClause clause) {
    if (clause is IDormPageClause) return _generatePagePredicate(clause);
    if (clause is IDormComparisonExpression) return _generateComparisonPredicate(clause);
    if (clause is IDormRangeExpression) return _generateRangePredicate(clause);
    if (clause is IDormZeroaryExpression) return _generateZeroaryPredicate(clause);
    if (clause is IDormUnaryExpression) return _generateUnaryPredicate(clause);
    if (clause is IDormBinaryExpression) return _generateBinaryPredicate(clause);
    throw DormException('Unsupported clause $clause');
  }

  InMemoryPredicate _generatePagePredicate(IDormPageClause expr) {
    if (expr is IDormLimitClause) {
      _pageLimit = expr.max;
      return _generatePredicate(expr.clause);
    } else if (expr is IDormOffsetClause) {
      _pageStartAt = _pageStartAt;
      return _generatePredicate(expr.clause);
    } else {
      throw DormException('Unsupported clause $expr');
    }
  }

  InMemoryPredicate _generateComparisonPredicate(IDormComparisonExpression expr) {
    final operandEvaluator = _generateOperandEvaluator(expr.operand);
    switch (expr.op) {
      case DormExpressionOperator.IsNull:
        return (DormRecord item) => operandEvaluator(item) == null;
      case DormExpressionOperator.IsNotNull:
        return (DormRecord item) => operandEvaluator(item) != null;
      case DormExpressionOperator.Equals:
        return (DormRecord item) => operandEvaluator(item) == expr.value;
      case DormExpressionOperator.IsNotEqual:
        return (DormRecord item) => operandEvaluator(item) != expr.value;
      case DormExpressionOperator.LessThan:
        return (DormRecord item) => operandEvaluator(item) < expr.value;
      case DormExpressionOperator.LessOrEqual:
        return (DormRecord item) => operandEvaluator(item) <= expr.value;
      case DormExpressionOperator.MoreThan: 
        return (DormRecord item) => operandEvaluator(item) > expr.value;
      case DormExpressionOperator.MoreOrEqual:
        return (DormRecord item) => operandEvaluator(item) >= expr.value;
      case DormExpressionOperator.Contains:
        return (DormRecord item) => operandEvaluator(item).contains(expr.value);
      case DormExpressionOperator.StartsWith:
        return (DormRecord item) => operandEvaluator(item).startsWith(expr.value);
      case DormExpressionOperator.EndsWith:
        return (DormRecord item) => operandEvaluator(item).endsWith(expr.value);
      case DormExpressionOperator.InList:
        final values = expr.value as Iterable? ?? [];
        return (DormRecord item) => values.contains(operandEvaluator(item));
      case DormExpressionOperator.NotInList:
        final values = expr.value as Iterable? ?? [];
        return (DormRecord item) => !values.contains(operandEvaluator(item));
      default:
        throw DormException('Unsupported clause $expr');
    }
  }

  InMemoryPredicate _generateRangePredicate(IDormRangeExpression expr) {
    final operandEvaluator = _generateOperandEvaluator(expr.operand);
    final min = expr.min;
    final max = expr.max;
    switch (expr.op) {
      case DormExpressionOperator.InRange:
        if (min == null && max && true) {
          return (DormRecord item) => true;
        } else if (max == null) {
          return (DormRecord item) => operandEvaluator(item) >= min;
        } else if (min == null) {
          return (DormRecord item) => operandEvaluator(item) <= max;
        } else {
          return (DormRecord item) {
            final value = operandEvaluator(item);
            return (min <= value) && (value <= max);
          };
        }
      case DormExpressionOperator.NotInRange:
        if (min == null && max && true) {
          return (DormRecord item) => false;
        } else if (max == null) {
          return (DormRecord item) => operandEvaluator(item) < min;
        } else if (min == null) {
          return (DormRecord item) => operandEvaluator(item) > min;
        } else {
          return (DormRecord item) {
            final value = operandEvaluator(item);
            return (value < min) || (value > max);
          };
        }
      default:
        throw DormException('Unsupported clause $expr');
    }
  }

  InMemoryOperand _generateOperandEvaluator(IDormOperandExpression operand) {
    if (operand is IDormColumnExpression) {
      final name = operand.column.name;
      return (DormRecord item) => item[name];
    } else {
      final operandEvaluator = _generateOperandEvaluator(operand.operand!);
      switch (operand.op!) {
        case DormExpressionOperator.ToLower:
          return (DormRecord item) => operandEvaluator(item)?.toLowerCase();
        case DormExpressionOperator.Trim:
          return (DormRecord item) => operandEvaluator(item)?.trim();
        case DormExpressionOperator.Length:
          return (DormRecord item) => operandEvaluator(item)?.length;
        default:
          throw DormException('Unsupported clause $operand');
      }
    }
  }

  InMemoryPredicate _generateZeroaryPredicate(IDormZeroaryExpression expr) {
    switch (expr.op) {
      case DormExpressionOperator.All:
        return (DormRecord item) => true;
      case DormExpressionOperator.None:
        return (DormRecord item) => false;
      default:
        throw DormException('Unsupported clause $expr');
    }
  }

  InMemoryPredicate _generateUnaryPredicate(IDormUnaryExpression expr) {
    final predicate = _generatePredicate(expr.expression);
    switch (expr.op) {
      case DormExpressionOperator.Not:
        return (DormRecord item) => !predicate(item);
      default:
        throw DormException('Unsupported clause $expr');
    }
  }

  InMemoryPredicate _generateBinaryPredicate(IDormBinaryExpression expr) {
    final leftPredicate = _generatePredicate(expr.left);
    final rightPredicate = _generatePredicate(expr.right);
    switch (expr.op) {
      case DormExpressionOperator.And:
        return (DormRecord item) => leftPredicate(item) && rightPredicate(item);
      case DormExpressionOperator.Or:
        return (DormRecord item) => leftPredicate(item) || rightPredicate(item);
      default:
        throw DormException('Unsupported clause $expr');
    }
  }
}
