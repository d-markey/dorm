import 'IDormField.dart';
import 'IDormDataContext.dart';
import 'IDormEntity.dart';
import 'IDormRepository.dart';
import 'IDormTransaction.dart';

typedef DormLinkSelector<T extends IDormEntity> = Iterable<IDormEntityLink> Function(T entity);
typedef DormJoinKey = dynamic Function();

abstract class IDormEntityLink<K, T extends IDormEntity<K>> {
  IDormRepository<K, T> getRepository(IDormDataContext dataContext);
  Future load(IDormDataContext dataContext, IDormTransaction transaction);
  void unload();

  Type get entityType;
  IDormField get joinColumn;

  bool get isLoaded;
  bool get needsLoad;
  bool get needsSave;
}

abstract class IDormEntityRef<K, T extends IDormEntity<K>> extends IDormEntityLink<K, T> {  
  K? get key;
  set key(K? value);

  T? get entity;
  set entity(T? value);

  bool get nullable;

  void copyFrom(IDormEntityRef<K, T> other);
}

abstract class IDormEntitySet<K, T extends IDormEntity<K>> extends IDormEntityLink<K, T> {  
  Iterable<T?> get entities;
  Iterable<IDormEntityRef<K, T>> get entityRefs;

  int get length;
  bool get eager;

  void loadWithRefs(Iterable<IDormEntity> entities);

  void add(T entity);  
  void remove(T entity);  

  void addKey(K key);  
  void removeKey(K key);  

  bool containsKey(K key);

  void copyFrom(IDormEntitySet<K, T> other);
}
