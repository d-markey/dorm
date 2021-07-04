library dorm_inmemory;

import 'package:dorm/dorm_interface.dart';

import 'src/inmemory/InMemoryDatabase.dart';

class DormInMemoryDatabaseProvider extends IDormDatabaseProvider {
  Future<IDormDatabase> _initialize(InMemoryDatabase memDb, IDormConfiguration configuration) async {
    final db = memDb;
    await configuration.applyTo(db);
    return db;
  }

  @override
  Future<IDormDatabase> openDatabase(String databaseName, IDormConfiguration configuration, { bool inMemory = false, bool reset = false }) async {
    final memDb = InMemoryDatabase(databaseName);
    return await _initialize(memDb, configuration);
  }
}
