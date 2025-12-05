class Failure {
  final String message;
  final String code;

  Failure({required this.message, this.code = 'unknown'});

  @override
  String toString() => message;
}
