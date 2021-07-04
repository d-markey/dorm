import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_inmemory.dart';
import 'package:dorm/src/inmemory/InMemoryDatabase.dart';

import 'Status.dart';
import 'Tasks.dart';

final _completed = Future.value();

class _TasksDbConfiguration extends DormConfiguration {
  _TasksDbConfiguration.use(IDormRepositoryFactory factory) : super.use(factory);

  @override
  Future applyTo(IDormDatabase db) {
    TaskRepository.configure(factory, db);
    StatusRepository.configure(factory, db);
    return super.applyTo(db);
  }

  @override
  Iterable<IDormMigration> getMigration() {
    return super.getMigration().followedBy([
      _TasksDbMigration(),
    ]);
  }
}

class _TasksDbMigration implements IDormMigration {
  @override
  final int version = 1;

  @override
  Future up(IDormTransaction transaction) {
    transaction.createTable(Status.model, columns: Status.model.columns);
    transaction.createTable(Task.model, columns: Task.model.columns);
    return _completed;
  }

  @override
  Future down(IDormTransaction transaction) {
    transaction.deleteTable(Task.model);
    transaction.deleteTable(Status.model);
    return _completed;
  }
}

typedef TaskCommand<T> = Future<T> Function(TasksDataContext dataContext, IDormTransaction transaction);

class TasksDb {
  TasksDb() : factory = DormRepositoryFactory();

  final IDormRepositoryFactory factory;
  late final InMemoryDatabase db;

  Future open() async {
    final dbProvider = DormInMemoryDatabaseProvider();
    final config = _TasksDbConfiguration.use(factory);
    db = await dbProvider.openDatabase('tasks', config) as InMemoryDatabase;
  }

  void dump() {
    print('');
    print('=================   DATABASE CONTENTS   =================');
    for (var collection in db.collections) {
      print('   COLLECTION OF ${collection.entityType} (name = "${collection.name}", count = (${collection.items.length})');
      for (var item in collection.items) {
        print('      * $item');
      }
    }
    print('=========================================================');
    print('');
  }

  Future<T> execute<T>(TaskCommand<T> command) {
    final dataContext = TasksDataContext(db, factory);
    try {
      return dataContext.transaction((transaction) async {
        return await command(dataContext, transaction);
      });
    } finally {
      dataContext.dispose();
    }
  }
}

class TasksDataContext extends DormDataContext {
  TasksDataContext(IDormDatabase db, IDormRepositoryFactory factory) : super(db, factory);

  late final IDormRepository<int, Task> tasks = repository<int, Task>().eager();
  late final IDormRepository<String, Status> statusCodes = repository<String, Status>();
}
