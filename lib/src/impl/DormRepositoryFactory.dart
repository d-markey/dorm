import 'package:dorm/dorm_interface.dart';

class DormRepositoryFactory implements IDormRepositoryFactory {
  
  final _builders = <Type, DormRepositoryBuilder>{};

  @override
  void register<K, T extends IDormEntity<K>>(DormRepositoryBuilder<K, T> builder) {
    _builders[T] = builder;
  }

  @override
  IDormRepository<K, T> build<K, T extends IDormEntity<K>>(IDormDataContext dataContext) {
    final builder = _builders[T] as DormRepositoryBuilder<K, T>;
    return builder(dataContext);
  }

  @override
  IDormRepository buildFor<T extends IDormEntity>(IDormDataContext dataContext, T entity) {
    final builder = _builders[T] as DormRepositoryBuilder;
    return builder(dataContext);
  }
}
