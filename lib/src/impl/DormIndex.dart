import 'package:dorm/dorm_interface.dart';

class DormIndex<T extends IDormEntity> implements IDormIndex<T> {
  DormIndex(this.columns, { this.unique = false });

  @override
  final List<IDormField<T>> columns;

  @override
  final bool unique;
}
