import 'package:dorm/dorm_interface.dart';

import '../DormProperty.dart';

class InitialMigration implements IDormMigration {
  @override
  int get version => 0;

  @override
  Future up(IDormTransaction transaction) async {
    await transaction.createTable(
      DormProperty.model,
      columns: DormProperty.model.columns,
      indexes: DormProperty.model.indexes,
    );
  }

  @override
  Future down(IDormTransaction transaction) async {
    await transaction.deleteTable(DormProperty.model);
  }
}