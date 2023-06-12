import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/factory_mixin.dart';

/// Mixin handler
abstract class SqfliteInvokeHandler {
  /// Invoke method
  Future<T> invokeMethod<T>(String method, [Object? arguments]);
}

class _SqfliteDatabaseFactoryImpl
    with SqfliteDatabaseFactoryMixin
    implements SqfliteInvokeHandler {
  _SqfliteDatabaseFactoryImpl(this._invokeMethod, {String? tag}) {
    this.tag = tag;
  }

  final Future<dynamic> Function(String method, [Object? arguments])
      _invokeMethod;

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async =>
      (await _invokeMethod(method, arguments)) as T;
}

/// Build a database factory invoking the invoke method instead of going through
/// flutter services.
///
/// To use to enable running without flutter plugins (unit test)
///
/// [tag] is an optional debug
DatabaseFactory buildDatabaseFactory(
    {String? tag,
    required Future<dynamic> Function(String method, [Object? arguments])
        invokeMethod}) {
  final DatabaseFactory impl =
      _SqfliteDatabaseFactoryImpl(invokeMethod, tag: tag);
  return impl;
}
