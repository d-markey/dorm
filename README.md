Dorm is a Dart ORM.

## Usage

Create a DormDatabase from a database implementation provider. Providers for [Sqlite3][dorm-sqlite3] and [Sembast][dorm-sembast] are available.

    class TasksDb {
      TasksDb() : factory = DormRepositoryFactory();

      final IDormRepositoryFactory factory;
      late final InMemoryDatabase db;

      Future open() async {
        final dbProvider = DormInMemoryDatabaseProvider();
        final config = _TasksDbConfiguration.use(factory);
        db = await dbProvider.openDatabase('tasks', config) as InMemoryDatabase;
      }
    }

The configuration object allows for registration of repositories as well as migrations.

    class _TasksDbConfiguration extends DormConfiguration {
      _TasksDbConfiguration.use(IDormRepositoryFactory factory) : super.use(factory);

      @override
      Future applyTo(IDormDatabase db) {
        // register your application's repositories here
        TaskRepository.configure(factory, db);
        StatusRepository.configure(factory, db);
        return super.applyTo(db);
      }

      @override
      Iterable<IDormMigration> getMigration() {
        // provide migrations
        return super.getMigration().followedBy([
          _TasksDbMigration(),
        ]);
      }
    }

Migrations are used to add tables / collections / columns / indexes... depending on the underlying database capabilities.

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

Repositories allow querying the database for data entities via a DormDataContext.

    class TaskRepository extends DormRepository<int, Task> {
      TaskRepository(IDormDataContext dataContext) : super(dataContext);

      @override
      TaskRepository create() => TaskRepository(dataContext);

      static void configure(IDormRepositoryFactory factory, IDormDatabase db) {
        factory.register<int, Task>((dataContext) => TaskRepository(dataContext));
        TaskModel.configure(db);
      }
    }

Data entities implement the attributes that are persisted to / loaded from the database. Navigational properties are available with DormEntityRef (1-to 0 or 1) and DormEntitySet (1-to-many). Navigational properties are lazy-loaded by default but can be eagerly loaded.

    class Task extends DormEntity<int> {
      Task() : super();

      Task.fromDb(int key, { required String label, DateTime? dueDate, required bool done, String? status }) : super.fromDb(key) {
        this.label = label;
        this.dueDate = dueDate;
        this.done = done;
        this.statusRef.key = status; // ignore: unnecessary_this
      }

      static late final TaskModel model;

      String? label;
      DateTime? dueDate;
      bool done = false;
      final IDormEntityRef<String, Status> statusRef = DormEntityRef<String, Status>(model.status);

      @override
      dynamic getValue(IDormField column) {
        if (column.isColumn(model.key)) return key;
        if (column.isColumn(model.label)) return label;
        if (column.isColumn(model.dueDate)) return dueDate;
        if (column.isColumn(model.done)) return done;
        if (column.isColumn(model.status)) return statusRef.key;
        throw Exception('Unknown column $column');
      }

      @override
      IDormEntityLink getLink(IDormField column) {
        if (column.isColumn(model.status)) return statusRef;
        throw Exception('Unknown ref for $column');
      }

      @override
      List<IDormEntityLink> getLinks() => [ statusRef ];

      @override
      String toString() {
        final status = (statusRef.entity == null) ? '<${statusRef.key ?? 'NULL'}> (unloaded)' : '<${statusRef.key ?? 'CODE NOT SET!'}>';
        return '#${key?.toString() ?? 'NEW'} ${label == null ? '(no label)' : '"$label"'}, status=$status, due date=${dueDate == null ? '(none)' : dueDate!.toIso8601String()}';
      }
    }

Entities are backed by a model describing the data structure and responsible for serializing to / deserialising from the underlying database.

    class TaskModel implements IDormModel<int, Task> {
      TaskModel(IDormDatabase db) {
        key = DormField<Task>(db.defaultKeyName, type: 'int', unique: true);
      }

      @override
      final String entityName = 'todo';

      @override
      late final DormField<Task> key;

      final label = DormField<Task>('label', type: 'string');
      final dueDate = DormField<Task>('due_date', type: 'datetime?');
      final done = DormField<Task>('done', type: 'bool');
      final status = DormField<Task>('status', type: 'string?');

      @override
      late final List<DormField<Task>> columns = List.unmodifiable([ label, dueDate, done, status ]);

      @override
      late final List<DormIndex<Task>> indexes = List.unmodifiable([ ]);

      static void configure(IDormDatabase db) {
        Task.model = TaskModel(db);
        db.registerModel<int, Task>(Task.model);
      }

      @override
      void check(Task entity) {
        if (entity.label == null) throw Exception('missing label');
      }

      @override
      Task unmap(IDormDatabase db, DormRecord item) =>
        Task.fromDb(
          db.castFromDb<int>(item[key.name])!,
          label: db.castFromDb<String>(item[label.name])!,
          dueDate: db.castFromDb<DateTime>(item[dueDate.name]),
          done: db.castFromDb<bool>(item[done.name])!,
          status: db.castFromDb<String>(item[status.name]),
        );

      @override
      DormRecord map(IDormDatabase db, Task entity) => {
        key.name: db.castToDb(entity.key),
        label.name: db.castToDb(entity.label),
        dueDate.name: db.castToDb(entity.dueDate),
        done.name: db.castToDb(entity.done),
        status.name: db.castToDb(entity.statusRef.key),
      };
    }
    
The DataContext bridges repositories and the database, including a cache and transaction management.

    class TasksDataContext extends DormDataContext {
      TasksDataContext(IDormDatabase db, IDormRepositoryFactory factory) : super(db, factory);

      late final IDormRepository<int, Task> tasks = repository<int, Task>().eager();
      late final IDormRepository<String, Status> statusCodes = repository<String, Status>();
    }

Example usage:

    Future<int> createTask(TasksDb db, String label) {
      final task = Task()
        ..label = label
        ..statusRef.key = 'TODO';

      return db.execute((dataContext, transaction) async {
        await dataContext.tasks.save(transaction, task);
        return task.key!;
      });
    }


    Future<Iterable<Task>> searchTasksContaining(TasksDb db, String text) {
      return db.execute((dataContext, transaction) {
        return dataContext.tasks.loadMany(transaction, Task.model.label.toLower().contains(text));
      });
    }


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
[dorm-sqlite3]: https://github.com/d-markey/dorm-sqlite3
[dorm-sembast]: https://github.com/d-markey/dorm-sembast
