import 'package:dorm/dorm_interface.dart';

import 'DormEntity.dart';
import 'DormField.dart';
import 'DormException.dart';
import 'DormIndex.dart';

class DormPropertyModel extends IDormModel<String, DormProperty> {
  @override
  final String entityName = 'dorm_properties';

  @override
  late final DormField<DormProperty> key = name;

  final name = DormField<DormProperty>('name', type: 'string', unique: true);
  final value = DormField<DormProperty>('value', type: 'string');

  @override
  late final List<DormField<DormProperty>> columns = List.unmodifiable([ name, value ]);

  @override
  final List<DormIndex<DormProperty>> indexes = List.unmodifiable([ ]);

  static void configure(IDormDatabase db) {
    DormProperty.model = DormPropertyModel();
    db.registerModel<String, DormProperty>(DormProperty.model);
  }

  @override
  void check(DormProperty entity) {
    if (entity.key == null) throw DormException('Key cannot be null');
  }

  @override
  DormProperty unmap(IDormDatabase db, DormRecord item) => 
    DormProperty(
      db.castFromDb<String>(item[name.name])!,
      db.castFromDb<String>(item[value.name])!,
    );

  @override
  DormRecord map(IDormDatabase db, DormProperty item) => { 
    name.name: db.castToDb(item.name),
    value.name: db.castToDb(item.value)
  };
}

class DormProperty extends DormEntity<String> {
  DormProperty(this.name, this.value);

  static late final DormPropertyModel model;

  final String name;
  String value;

  @override
  String? get key => name;

  @override
  set key(String? value) => throw DormException('Cannot set a property key');

  @override
  dynamic getValue(IDormField column) {
    if (column.isColumn(model.name)) return name;
    if (column.isColumn(model.value)) return value;
    throw DormException('Unknown column $column');
  }

  @override
  IDormEntityLink getLink(IDormField column) {
    throw DormException('Unknown ref for $column');
  }

  @override
  List<IDormEntityLink> getLinks() {
    return [];    
  }
}
