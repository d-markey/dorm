import 'package:dorm/dorm.dart';

import 'Status.dart';

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

class TaskRepository extends DormRepository<int, Task> {
  TaskRepository(IDormDataContext dataContext) : super(dataContext);

  @override
  TaskRepository create() => TaskRepository(dataContext);

  static void configure(IDormRepositoryFactory factory, IDormDatabase db) {
    factory.register<int, Task>((dataContext) => TaskRepository(dataContext));
    TaskModel.configure(db);
  }
}

