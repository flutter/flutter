import 'package:meta/meta.dart';

/// An command object representing the invocation of a named method.
@immutable
class SqfliteMethodCall {
  /// Creates a [MethodCall] representing the invocation of [method] with the
  /// specified [arguments].
  const SqfliteMethodCall(this.method, [this.arguments]);

  /// Build from a map.
  factory SqfliteMethodCall.fromMap(Map map) {
    return SqfliteMethodCall(map['method'] as String, map['arguments']);
  }

  /// The name of the method to be called.
  final String method;

  /// The arguments for the method.
  ///
  /// Must be a valid value for the [MethodCodec] used.
  final Object? arguments;

  /// To map
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'method': method,
      if (arguments != null) 'arguments': arguments
    };
  }

  @override
  String toString() => '$runtimeType($method, $arguments)';
}
