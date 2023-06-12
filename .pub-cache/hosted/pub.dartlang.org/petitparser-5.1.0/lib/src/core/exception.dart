import '../context/failure.dart';

/// An exception raised in case of a parse error.
class ParserException implements FormatException {
  ParserException(this.failure);

  final Failure failure;

  @override
  String get message => failure.message;

  @override
  int get offset => failure.position;

  @override
  String get source => failure.buffer;

  @override
  String toString() => '${failure.message} at ${failure.toPositionString()}';
}
