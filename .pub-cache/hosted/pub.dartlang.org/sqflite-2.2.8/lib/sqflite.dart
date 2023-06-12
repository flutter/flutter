import 'dart:async';

import 'package:sqflite/src/compat.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/sqflite_android.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/utils.dart' as impl;
import 'package:sqflite/utils/utils.dart' as utils;

import 'sqlite_api.dart';

export 'package:sqflite/sql.dart' show ConflictAlgorithm;
export 'package:sqflite/src/compat.dart';
export 'package:sqflite_common/sqflite.dart';

export 'sqlite_api.dart';
export 'src/factory_impl.dart' show databaseFactorySqflitePlugin;
export 'src/sqflite_plugin.dart' show SqflitePlugin;

///
/// sqflite plugin
///
class Sqflite {
  /// Turns on debug mode if you want to see the SQL query
  /// executed natively.
  @Deprecated('Removed in next major release')
  static Future<void> setDebugModeOn([bool on = true]) async {
    await invokeMethod<dynamic>(methodSetDebugModeOn, on);
  }

  /// Planned Deprecated for 1.1.7
  @Deprecated('Removed in next major release')
  static Future<bool> getDebugModeOn() async {
    return impl.debugModeOn;
  }

  /// deprecated on purpose to remove from code.
  ///
  /// To use during developpment/debugging
  /// Set extra dart and nativate debug logs
  @Deprecated('Dev only')
  static Future<void> devSetDebugModeOn([bool on = true]) {
    impl.debugModeOn = on;
    return setDebugModeOn(on);
  }

  /// Testing only.
  ///
  /// deprecated on purpose to remove from code.
  @Deprecated('Dev only')
  static Future<void> devSetOptions(SqfliteOptions options) async {
    await invokeMethod<dynamic>(methodOptions, options.toMap());
  }

  /// Testing only
  @Deprecated('Dev only')
  static Future<void> devInvokeMethod(String method,
      [Object? arguments]) async {
    await invokeMethod<dynamic>(method, arguments);
  }

  /// helper to get the first int value in a query
  /// Useful for COUNT(*) queries
  static int? firstIntValue(List<Map<String, Object?>> list) =>
      utils.firstIntValue(list);

  /// Utility to encode a blob to allow blob query using
  /// 'hex(blob_field) = ?', Sqlite.hex([1,2,3])
  static String hex(List<int> bytes) => utils.hex(bytes);

  /// Sqlite has a dead lock warning feature that will print some text
  /// after 10s, you can override the default behavior
  static void setLockWarningInfo(
      {Duration? duration, void Function()? callback}) {
    utils.setLockWarningInfo(duration: duration!, callback: callback!);
  }
}

/// Android only API
extension SqfliteDatabaseAndroidExt on Database {
  /// Sets the locale for this database. The specified IETF BCP 47 language tag
  /// string (en-US, zh-CN, fr-FR, zh-Hant-TW, ...) must be as defined in
  /// `Locale.forLanguageTag` in Android/Java documentation.
  ///
  /// Only on Android.
  Future<void> androidSetLocale(String languageTag) =>
      SqfliteDatabaseAndroidExtImpl(this).androidSetLocale(languageTag);
}
