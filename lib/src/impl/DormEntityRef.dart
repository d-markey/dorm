import 'package:dorm/dorm_interface.dart';

class DormEntityRef<K, T extends IDormEntity<K>> extends IDormEntityRef<K, T> {  
  DormEntityRef(this.joinColumn);

  @override
  final entityType = T;

  @override
  final IDormField joinColumn;

  @override
  Future load(IDormDataContext dataContext, IDormTransaction transaction) async {
    if (needsLoad) {
      final repo = getRepository(dataContext);
      _entity = await repo.findByKey(transaction, _key!);
    }
  }

  @override
  IDormRepository<K, T> getRepository(IDormDataContext dataContext) => dataContext.repository<K, T>();

  @override
  void copyFrom(IDormEntityRef<K, T> other) {
    if (this == other) return;
    _key = other.key;
    _entity = other.entity;
  }

  @override
  void unload() {
    if (_entity != null) {
      _key = _entity!.key;
      _entity = null;
    }
  }

  bool get hasRef => (key != null);

  @override
  bool get isLoaded => (key == null) || (entity != null);

  @override
  bool get needsLoad => (key != null) && (entity == null);

  @override
  bool get needsSave => (key == null) && (entity != null);

  @override
  bool get nullable => joinColumn.nullable;

  K? _key;

  @override
  K? get key => entity?.key ?? _key;

  @override
  set key(K? key) {
    if (this.key != key) {
      _key = key;
      _entity = null;
    }
  }

  T? _entity;

  @override
  T? get entity => _entity;

  @override
  set entity(T? entity) {
    if (this.entity != entity) {
      _key = null;
      _entity = entity;
    }
  }

  @override
  String toString() {
    if (_entity != null) return '<$_key(loaded)>';
    if (_key != null) return '<$_key>';
    return 'NULL';
  }
}
