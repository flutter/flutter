import 'package:sqflite/src/sqflite_import.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'constant.dart';

/// Native Android setLocale call.
const String methodAndroidSetLocale = 'androidSetLocale';

/// Locale param.
const String paramLocale = 'locale';

/// Private implementation in an extension for Android only
extension SqfliteDatabaseAndroidExtImpl on Database {
  SqfliteDatabaseMixin get _mixin => this as SqfliteDatabaseMixin;

  /// Set the locale.
  Future<void> androidSetLocale(String languageTag) async {
    await _mixin.safeInvokeMethod<void>(methodAndroidSetLocale,
        <String, Object?>{paramId: _mixin.id, paramLocale: languageTag});
  }
}
