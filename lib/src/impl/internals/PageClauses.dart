import 'package:dorm/dorm_interface.dart';

import 'Expressions.dart';

abstract class PageClause extends ChainableClause implements IDormPageClause {
  PageClause(this.clause);

  final IDormChainableClause clause;
}

class LimitClause extends PageClause implements IDormLimitClause {
  LimitClause(IDormChainableClause clause, { required this.max }) : super(clause);

  @override
  final int max;

  @override
  IDormChainableClause skip(int offset) => OffsetClause(this, startAt: offset);
}

class OffsetClause extends PageClause implements IDormOffsetClause {
  OffsetClause(IDormChainableClause clause, { required this.startAt }) : super(clause);

  @override
  final int startAt;

  @override
  IDormChainableClause limit(int max) => LimitClause(this, max: max);
}

