import 'package:dorm/dorm_interface.dart';

import 'DormException.dart';
import 'internals/extensions.dart';
import 'DormPropertyRepository.dart';
import 'DormProperty.dart';
import 'internals/InitialMigration.dart';

class DormConfiguration extends IDormConfiguration {
  DormConfiguration.use(this._factory);

  final IDormRepositoryFactory _factory;

  @override
  IDormRepositoryFactory get factory => _factory;

  @override
  Future applyTo(IDormDatabase db) {
    DormPropertyRepository.configure(_factory, db);
    return up(db);
  }

  Iterable<IDormMigration> getMigration() sync* {
    yield InitialMigration();
  }

  int get currentVersion => getMigration().map((m) => m.version).fold(0, (value, version) => (version > value) ? version : value);

  Future<DormProperty?> _getVersion(IDormDatabase db, IDormTransaction transaction) async {
    final whereClause = DormProperty.model.key.equals('version');
    final row = (await transaction.dbLoad<String, DormProperty>(whereClause)).firstOrNull;
    return (row == null) ? null : DormProperty.model.unmap(db, row);
  }

  Future up(IDormDatabase db) async {
    DormProperty? version;
    try {
      version = await db.readonly((IDormTransaction transaction) => _getVersion(db, transaction));
    } on DormException {
      // the first run will install the DormProperty repository
    }
    version ??= DormProperty('version', '-1');
    final ver = int.parse(version.value);
    final migrations = getMigration().where((m) => m.version > ver).toList();
    if (migrations.isNotEmpty) {
      migrations.sort((a, b) => a.version - b.version);
      for (var migration in migrations) {
        await db.transaction((transaction) async {
          await migration.up(transaction);
          version!.value = migration.version.toString();
          await transaction.dbUpsert<String, DormProperty>(DormProperty.model.map(db, version));
        });
      }
    }
  }
}
