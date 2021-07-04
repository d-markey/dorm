class DormException implements Exception {
  DormException(this.message, { this.inner, this.data });

  final String message;
  final Exception? inner;
  final Map<String, dynamic>? data;

  @override
  String toString() => message;
}