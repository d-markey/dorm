extension IterableNullableConsummer<T> on Iterable<T?> {
  Iterable<T> whereNotNull([ bool Function(T e)? predicate ]) {
    if (predicate == null) {
      return where((e) => e != null).cast<T>();
    } else {
      return where((e) => e != null && predicate(e)).cast<T>();
    }
  }
}

extension IterableConsummer<T> on Iterable<T> {
  List<T> asList() {
    if (this is List<T>) return this as List<T>;
    return toList();
  }

  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  T? get singleOrNull {
    if (isEmpty) return null;
    if (skip(1).isNotEmpty) throw StateError('sequence has more than one element');
    return first;
  }
}
