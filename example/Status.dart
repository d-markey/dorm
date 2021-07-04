import 'package:dorm/dorm.dart';

class Status extends DormEntity<String> {
  Status() : super();

  Status.fromDb(String code, String label) : super.fromDb(code) {
    this.label = label;
  }

  static late final StatusModel model;

  String? get code => key;
  set code(String? value) {
    key = value;
  }

  String? label;

  @override
  dynamic getValue(IDormField column) {
    if (column.isColumn(model.code)) return code;
    if (column.isColumn(model.label)) return label;
    throw Exception('Unknown column $column');
  }

  @override
  IDormEntityLink getLink(IDormField column) {
    throw Exception('Unknown link for $column');
  }

  @override
  List<IDormEntityLink> getLinks() => [];

  @override
  String toString() {
    return '$code: $label';
  }
}

class StatusModel implements IDormModel<String, Status> {
  StatusModel(IDormDatabase db) {
    key = DormField<Status>('code', type: 'string', unique: true);
  }

  @override
  final String entityName = 'status';

  @override
  late final DormField<Status> key;

  DormField<Status> get code => key;

  final label = DormField<Status>('label', type: 'string');

  @override
  late final List<DormField<Status>> columns = List.unmodifiable([ code, label ]);

  @override
  late final List<DormIndex<Status>> indexes = List.unmodifiable([ ]);

  static void configure(IDormDatabase db) {
    Status.model = StatusModel(db);
    db.registerModel<String, Status>(Status.model);
  }

  @override
  void check(Status entity) {
    if (entity.code == null) throw Exception('missing code');
    if (entity.label == null) throw Exception('missing label');
  }

  @override
  Status unmap(IDormDatabase db, DormRecord item) =>
    Status.fromDb(
      db.castFromDb<String>(item[code.name])!,
      db.castFromDb<String>(item[label.name])!,
    );

  @override
  DormRecord map(IDormDatabase db, Status entity) => {
    code.name: db.castToDb(entity.code),
    label.name: db.castToDb(entity.label),
  };
}

class StatusRepository extends DormRepository<String, Status> {
  StatusRepository(IDormDataContext dataContext) : super(dataContext);

  @override
  StatusRepository create() => StatusRepository(dataContext);

  static void configure(IDormRepositoryFactory factory, IDormDatabase db) {
    factory.register<String, Status>((dataContext) => StatusRepository(dataContext));
    StatusModel.configure(db);
  }
}
