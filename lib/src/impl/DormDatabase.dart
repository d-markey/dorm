import 'package:dorm/dorm_interface.dart';

abstract class DormDatabase implements IDormDatabase {
  final Map<Type, IDormModel> _mappings = <Type, IDormModel>{};

  @override
  void registerModel<K, T extends IDormEntity<K>>(IDormModel<K, T> model) => _mappings[T] = model;

  @override
  IDormModel<K, T> getModel<K, T extends IDormEntity<K>>() => _mappings[T] as IDormModel<K, T>;

  @override
  IDormModel getModelFor(Type entityType) => _mappings[entityType] as IDormModel;
}
