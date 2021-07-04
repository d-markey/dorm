import 'package:dorm/dorm.dart';

import 'IDormDatabase.dart';

abstract class IDormConfiguration {
  IDormRepositoryFactory get factory;
  Future applyTo(IDormDatabase db);
}
