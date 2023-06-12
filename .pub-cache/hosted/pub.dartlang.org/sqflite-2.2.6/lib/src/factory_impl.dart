import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/exception_impl.dart' as impl;
import 'package:sqflite/src/sqflite_impl.dart' as impl;
import 'package:sqflite/src/sqflite_import.dart';

import 'dev_utils.dart'; // ignore: unused_import

SqfliteDatabaseFactory? _databaseFactory;

/// sqflite Default factory
DatabaseFactory get databaseFactory => sqfliteDatabaseFactory;

/// Change the default factory.
///
/// Be aware of the potential side effect. Any library using sqflite
/// will have this factory as the default for all operations.
///
/// This setter must be call only once, before any other calls to sqflite.
set databaseFactory(DatabaseFactory? databaseFactory) {
  // Warn when changing. might throw in the future
  if (databaseFactory != null) {
    if (databaseFactory is! SqfliteDatabaseFactory) {
      throw ArgumentError.value(
          databaseFactory, 'databaseFactory', 'Unsupported sqflite factory');
    }
    if (_databaseFactory != null) {
      stderr.writeln('''
*** sqflite warning ***

You are changing sqflite default factory.
Be aware of the potential side effects. Any library using sqflite
will have this factory as the default for all operations.

*** sqflite warning ***
''');
    }
    sqfliteDatabaseFactory = databaseFactory;
  } else {
    /// Will use the plugin sqflite factory
    sqfliteDatabaseFactory = null;
  }
}

/// sqflite Default factory
///
/// Definition with a typo error.
/// - Will be soon deprecated
/// - Will be removed in 2.0.0
@Deprecated('Use databaseFactory instead (typo error)')
SqfliteDatabaseFactory get sqlfliteDatabaseFactory => sqfliteDatabaseFactory;

/// Change the default factory. test only.
///
/// Definition with a typo error.
///
/// Will be removed in 2.0.0
@Deprecated('Use databaseFactory')
set sqlfliteDatabaseFactory(SqfliteDatabaseFactory? databaseFactory) =>
    _databaseFactory = databaseFactory;

/// sqflite Default factory
@visibleForTesting
SqfliteDatabaseFactory get sqfliteDatabaseFactory =>
    _databaseFactory ??= sqfliteDatabaseFactoryDefault;

/// Default factory that uses the plugin.
SqfliteDatabaseFactory sqfliteDatabaseFactoryDefault =
    SqfliteDatabaseFactoryImpl();

/// Change the default factory. test only.
@visibleForTesting
set sqfliteDatabaseFactory(SqfliteDatabaseFactory? databaseFactory) =>
    _databaseFactory = databaseFactory;

/// Factory implementation
class SqfliteDatabaseFactoryImpl with SqfliteDatabaseFactoryMixin {
  /// Only to set for extra debugging
  //static var _debugInternals = devWarning(true);
  static const _debugInternals = false;

  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) =>
      impl.wrapDatabaseException(action);

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) =>
      !_debugInternals
          ? impl.invokeMethod(method, arguments)
          : _invokeMethodWithLog(method, arguments);

  Future<T> _invokeMethodWithLog<T>(String method, [Object? arguments]) async {
    // ignore: avoid_print
    print('-> $method $arguments');
    final result = await impl.invokeMethod<T>(method, arguments);
    // ignore: avoid_print
    print('<- $result');
    return result;
  }
}
