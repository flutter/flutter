import 'package:sqflite_common/sqlite_api.dart';

import 'mixin/import_mixin.dart';

/// Debug extension
///
/// Access to dev options, deprecated for temp usage only
extension SqfliteDatabaseFactoryDebug on DatabaseFactory {
  /// Change the log level if you want to see the SQL query
  /// executed natively.
  ///
  /// Deprecated for temp usage only
  @Deprecated('Dev only')
  Future<void> debugSetLogLevel(int logLevel) async {
    await debugSetOptions(SqfliteOptions(logLevel: logLevel));
  }

  /// Testing only.
  ///
  /// deprecated on purpose to remove from code.
  @Deprecated('Dev only')
  Future<void> debugSetOptions(SqfliteOptions options) async {
    await (this as SqfliteInvokeHandler)
        .invokeMethod<dynamic>(methodOptions, options.toMap());
  }
}
