import 'package:dorm/dorm_interface.dart';

class InMemoryCollection<K, T extends IDormEntity<K>> {
  InMemoryCollection(this._name, this._keyName);

  final Type entityType = T;

  String _name;
  final String _keyName;

  String get name => _name;

  void rename(String name) {
    _name = name;
  }

  final _records = <K, DormRecord>{};

  Iterable<K> get keys => _records.keys;
  Iterable<DormRecord> get items => _records.values;

  void upsert(K key, DormRecord item) {
    item[_keyName] = key;
    _records[key] = item;
  }

  void delete(K key) {
    _records.remove(key);
  }
}
