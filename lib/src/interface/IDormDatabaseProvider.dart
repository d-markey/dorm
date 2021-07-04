import 'IDormConfiguration.dart';
import 'IDormDatabase.dart';

abstract class IDormDatabaseProvider {
  Future<IDormDatabase> openDatabase(String databaseName, IDormConfiguration configuration, { bool inMemory = false, bool reset = false });
}
