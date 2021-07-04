import 'package:dorm/dorm_interface.dart';

import 'DormException.dart';

abstract class DormEntity<K> extends IDormEntity<K> {
  DormEntity();

  DormEntity.fromDb(K key) {
    this.key = key;
  }

  K? _key;

  @override
  K? get key => _key;

  @override
  set key(K? k) {
    if (k == null) throw DormException('Key cannot be null');
    if (_key != null) {
      if (_key != k) throw DormException('Key cannot be modified');
    } else {
      _key = k;
    }
  }
}
