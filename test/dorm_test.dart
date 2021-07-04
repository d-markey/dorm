import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_inmemory.dart';
import 'package:test/test.dart';

void main() {
  group('Test Group', () async {
    final dbProvider = DormInMemoryDatabaseProvider();
    final repoFactory = DormRepositoryFactory();
    final config = ToDoConfiguration.use(repoFactory);
    final db = await dbProvider.openDatabase('test', config);

    setUp(() {
      // Additional setup goes here.
    });

    test('Test', () async {
      final test = ToDo();
      test.label = 'A task';

      final dataContext = DormDataContext(db, repoFactory);
      try {
        await dataContext.transaction((transaction) async {
          print('before save: test.key = ${test.key}');
          await dataContext.repository<int, ToDo>().save(transaction, test);
          print('after save: test.key = ${test.key}');
        });
      } finally {
        dataContext.dispose();
      }
    });
  });
}

final _completed = Future.value();

class ToDoConfiguration extends DormConfiguration {
  ToDoConfiguration.use(IDormRepositoryFactory factory) : super.use(factory);

  @override
  Future applyTo(IDormDatabase db) {
    ToDoRepository.configure(factory, db);
    return super.applyTo(db);
  }

  @override
  Iterable<IDormMigration> getMigration() {
    return super.getMigration().followedBy([
      ToDoMigration(),
    ]);
  }
}

class ToDoMigration implements IDormMigration {
  @override
  final int version = 1;

  @override
  Future up(IDormTransaction transaction) {
    final model = ToDo.model;
    transaction.createTable(model, columns: model.columns);
    return _completed;
  }

  @override
  Future down(IDormTransaction transaction) {
    final model = ToDo.model;
    transaction.deleteTable(model);
    return _completed;
  }
}

class ToDo extends DormEntity<int> {
  ToDo() : super();

  ToDo.fromDb(int key, { required String label, DateTime? dueDate, required bool done }) : super.fromDb(key) {
    this.label = label;
    this.dueDate = dueDate;
    this.done = done;
  }

  static late final ToDoModel model;

  String? label;
  DateTime? dueDate;
  bool done = false;

  @override
  dynamic getValue(IDormField column) {
    if (column.isColumn(model.key)) return key;
    if (column.isColumn(model.label)) return label;
    if (column.isColumn(model.dueDate)) return dueDate;
    if (column.isColumn(model.done)) return done;
    throw Exception('Unknown column $column');
  }

  @override
  IDormEntityLink getLink(IDormField column) {
    throw Exception('Unknown ref for $column');
  }

  @override
  List<IDormEntityLink> getLinks() => [ ];

  @override
  String toString() {
    return '#${key?.toString() ?? 'NEW'} ${label == null ? '(no label)' : '"$label"'}, due date=${dueDate == null ? '(none)' : dueDate!.toIso8601String()}';
  }
}

class ToDoModel implements IDormModel<int, ToDo> {
  ToDoModel(IDormDatabase db) {
    key = DormField<ToDo>(db.defaultKeyName, type: 'int', unique: true);
  }

  @override
  final String entityName = 'todo';

  @override
  late final DormField<ToDo> key;

  final label = DormField<ToDo>('label', type: 'string');
  final dueDate = DormField<ToDo>('due_date', type: 'datetime?');
  final done = DormField<ToDo>('done', type: 'bool');

  @override
  late final List<DormField<ToDo>> columns = List.unmodifiable([ label, dueDate, done ]);

  @override
  late final List<DormIndex<ToDo>> indexes = List.unmodifiable([ ]);

  static void configure(IDormDatabase db) {
    ToDo.model = ToDoModel(db);
    db.registerModel<int, ToDo>(ToDo.model);
  }

  @override
  void check(ToDo entity) {
    if (entity.label == null) throw Exception('missing label');
  }

  @override
  ToDo unmap(IDormDatabase db, DormRecord item) =>
    ToDo.fromDb(
      db.castFromDb<int>(item[key.name])!,
      label: db.castFromDb<String>(item[label.name])!,
      dueDate: db.castFromDb<DateTime>(item[dueDate.name]),
      done: db.castFromDb<bool>(item[done.name])!,
    );

  @override
  DormRecord map(IDormDatabase db, ToDo entity) => {
    key.name: db.castToDb(entity.key),
    label.name: db.castToDb(entity.label),
    dueDate.name: db.castToDb(entity.dueDate),
    done.name: db.castToDb(entity.done),
  };
}

class ToDoRepository extends DormRepository<int, ToDo> {
  ToDoRepository(IDormDataContext dataContext) : super(dataContext);

  @override
  ToDoRepository create() => ToDoRepository(dataContext);

  static void configure(IDormRepositoryFactory factory, IDormDatabase db) {
    factory.register<int, ToDo>((dataContext) => ToDoRepository(dataContext));
    ToDoModel.configure(db);
  }
}
