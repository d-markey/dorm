import 'IDormDataContext.dart';
import 'IDormEntity.dart';
import 'IDormRepository.dart';

typedef DormRepositoryBuilder<K, T extends IDormEntity<K>> = IDormRepository<K, T> Function(IDormDataContext dataContext);

abstract class IDormRepositoryFactory {
  void register<K, T extends IDormEntity<K>>(DormRepositoryBuilder<K, T> builder);
  IDormRepository<K, T> build<K, T extends IDormEntity<K>>(IDormDataContext dataContext);
  IDormRepository buildFor<T extends IDormEntity>(IDormDataContext dataContext, T entity);
}
