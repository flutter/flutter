import 'dart:async';

import 'package:sqflite_common/src/sqflite_database_factory.dart';

import 'sqlite_api.dart';

export 'package:sqflite_common/src/sqflite_database_factory.dart'
    show databaseFactory, databaseFactoryOrNull;

export 'sqlite_api.dart';

///
/// Open the database at a given path
///
/// [version] (optional) specifies the schema version of the database being
/// opened. This is used to decide whether to call [onCreate], [onUpgrade],
/// and [onDowngrade]
///
/// The optional callbacks are called in the following order:
///
/// 1. [onConfigure]
/// 2. [onCreate] or [onUpgrade] or [onDowngrade]
/// 5. [onOpen]
///
/// [onConfigure] is the first callback invoked when opening the database. It
/// allows you to perform database initialization such as enabling foreign keys
/// or write-ahead logging
///
/// If [version] is specified, [onCreate], [onUpgrade], and [onDowngrade] can
/// be called. These functions are mutually exclusive — only one of them can be
/// called depending on the context, although they can all be specified to
/// cover multiple scenarios. If specified, it must be a 32-bits integer greater
/// than 0.
///
/// [onCreate] is called if the database did not exist prior to calling
/// [openDatabase]. You can use the opportunity to create the required tables
/// in the database according to your schema
///
/// [onUpgrade] is called if either of the following conditions are met:
///
/// 1. [onCreate] is not specified
/// 2. The database already exists and [version] is higher than the last
/// database version
///
/// In the first case where [onCreate] is not specified, [onUpgrade] is called
/// with its [oldVersion] parameter as `0`. In the second case, you can perform
/// the necessary migration procedures to handle the differing schema
///
/// [onDowngrade] is called only when [version] is lower than the last database
/// version. This is a rare case and should only come up if a newer version of
/// your code has created a database that is then interacted with by an older
/// version of your code. You should try to avoid this scenario
///
/// [onOpen] is the last optional callback to be invoked. It is called after
/// the database version has been set and before [openDatabase] returns
///
/// When [readOnly] (false by default) is true, all other parameters are
/// ignored and the database is opened as-is
///
/// When [singleInstance] is true (the default), a single database instance is
/// returned for a given path. Subsequent calls to [openDatabase] with the
/// same path will return the same instance, and will discard all other
/// parameters such as callbacks for that invocation.
///
Future<Database> openDatabase(String path,
    {int? version,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
    bool? readOnly = false,
    bool? singleInstance = true}) {
  final options = OpenDatabaseOptions(
      version: version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen,
      readOnly: readOnly,
      singleInstance: singleInstance);
  return databaseFactory.openDatabase(path, options: options);
}

///
/// Open the database at a given path in read only mode
///
Future<Database> openReadOnlyDatabase(String path,
        {bool? singleInstance = true}) =>
    openDatabase(path, readOnly: true, singleInstance: singleInstance);

///
/// Get the default databases location.
///
/// On Android, it is typically data/data/<package_name>/databases
///
/// On iOS and MacOS, it is the Documents directory.
///
/// Note for iOS and non-Android platforms: Using `path_provider` is recommended to get the
/// databases directory. The most appropriate location on iOS would be
/// the Library directory that you could get from the [`path_provider` package]
/// (https://pub.dev/documentation/path_provider/latest/path_provider/getLibraryDirectory.html).
///
Future<String> getDatabasesPath() => databaseFactory.getDatabasesPath();

///
/// Delete the database at the given path.
///
Future<void> deleteDatabase(String path) =>
    databaseFactory.deleteDatabase(path);

///
/// Check if a database exists at a given path.
///
Future<bool> databaseExists(String path) =>
    databaseFactory.databaseExists(path);
