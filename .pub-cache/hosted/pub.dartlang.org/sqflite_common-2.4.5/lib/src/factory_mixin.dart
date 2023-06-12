import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/database_mixin.dart';
import 'package:sqflite_common/src/exception.dart';
import 'package:sqflite_common/src/factory.dart';
import 'package:sqflite_common/src/mixin/factory.dart';
import 'package:sqflite_common/src/open_options.dart';
import 'package:synchronized/synchronized.dart';
import 'path_utils.dart' as pu;

/// Base factory implementation
abstract class SqfliteDatabaseFactoryBase with SqfliteDatabaseFactoryMixin {}

/// Named lock, unique by name and its private class
class _NamedLock {
  factory _NamedLock(String name) {
    // Add to cache, create if needed
    return cacheLocks[name] ??= _NamedLock._(name, Lock(reentrant: true));
  }

  _NamedLock._(this.name, this.lock);

  // Global cache per db name
  // Remain allocated forever but that is fine.
  static final cacheLocks = <String, _NamedLock>{};

  final String name;
  final Lock lock;
}

/// Common factory mixin
mixin SqfliteDatabaseFactoryMixin
    implements SqfliteDatabaseFactory, SqfliteInvokeHandler {
  /// To override to wrap wanted exception
  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) => action();

  /// Invoke native method and wrap exception.
  Future<T> safeInvokeMethod<T>(String method, [Object? arguments]) =>
      wrapDatabaseException<T>(() => invokeMethod(method, arguments));

  /// Open helpers for single instances only.
  Map<String, SqfliteDatabaseOpenHelper> databaseOpenHelpers =
      <String, SqfliteDatabaseOpenHelper>{};

  /// Avoid concurrent open operation on the same database
  Lock _getDatabaseOpenLock(String path) => _NamedLock(path).lock;

  /// Optional tag (read-only)
  String? tag;

  @override
  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    return SqfliteDatabaseBase(openHelper, path);
  }

  @override
  void removeDatabaseOpenHelper(String path) {
    databaseOpenHelpers.remove(path);
  }

  // Close an instance of the database
  @override
  Future<void> closeDatabase(SqfliteDatabase database) {
    // Lock per database name
    final lock = _getDatabaseOpenLock(database.path);
    return lock.synchronized(() async {
      await (database as SqfliteDatabaseMixin)
          .openHelper!
          .closeDatabase(database);
      if (database.options?.singleInstance != false) {
        removeDatabaseOpenHelper(database.path);
      }
    });
  }

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions? options}) async {
    path = await fixPath(path);
    // Lock per database name
    final lock = _getDatabaseOpenLock(path);
    return lock.synchronized(() async {
      options ??= SqfliteOpenDatabaseOptions();

      if (options?.singleInstance != false) {
        SqfliteDatabaseOpenHelper? getExistingDatabaseOpenHelper(String path) {
          return databaseOpenHelpers[path];
        }

        void setDatabaseOpenHelper(SqfliteDatabaseOpenHelper? helper) {
          if (helper == null) {
            databaseOpenHelpers.remove(path);
          } else {
            databaseOpenHelpers[path] = helper;
          }
        }

        var databaseOpenHelper = getExistingDatabaseOpenHelper(path);

        final firstOpen = databaseOpenHelper == null;
        if (firstOpen) {
          databaseOpenHelper = SqfliteDatabaseOpenHelper(this, path, options);
          setDatabaseOpenHelper(databaseOpenHelper);
        }
        try {
          return await databaseOpenHelper.openDatabase();
        } catch (e) {
          // If first open fail remove the reference
          if (firstOpen) {
            removeDatabaseOpenHelper(path);
          }
          rethrow;
        }
      } else {
        final databaseOpenHelper =
            SqfliteDatabaseOpenHelper(this, path, options);
        return await databaseOpenHelper.openDatabase();
      }
    });
  }

  @override
  Future<void> deleteDatabase(String path) async {
    path = await fixPath(path);
    // Lock per database name
    final lock = _getDatabaseOpenLock(path);
    return lock.synchronized(() async {
      // Handle already single instance open database
      removeDatabaseOpenHelper(path);
      return safeInvokeMethod<void>(
          methodDeleteDatabase, <String, Object?>{paramPath: path});
    });
  }

  @override
  Future<bool> databaseExists(String path) async {
    path = await fixPath(path);
    return safeInvokeMethod<bool>(
        methodDatabaseExists, <String, Object?>{paramPath: path});
  }

  String? _databasesPath;

  @override
  Future<String> getDatabasesPath() async {
    if (_databasesPath == null) {
      final path = await safeInvokeMethod<String?>(methodGetDatabasesPath);

      if (path == null) {
        throw SqfliteDatabaseException('getDatabasesPath is null', null);
      }
      _databasesPath = path;
    }
    return _databasesPath!;
  }

  /// Set the databases path.
  @override
  @Deprecated('Use setDatabasesPathOrNull')
  Future<void> setDatabasesPath(String? path) async {
    setDatabasesPathOrNull(path);
  }

  /// Set the databases path.
  void setDatabasesPathOrNull(String? path) {
    _databasesPath = path;
  }

  /// True if a database path is in memory
  // @Deprecated('use path_utils.isInMemoryDatabasePath')
  static bool isInMemoryDatabasePath(String path) =>
      pu.isInMemoryDatabasePath(path);

  final bool _kIsWeb = identical(0, 0.0);

  /// path must be non null
  Future<String> fixPath(String path) async {
    /// Transform file::memory: to :memory as current implementation
    /// relies on this feature.
    if (pu.isInMemoryDatabasePath(path)) {
      return inMemoryDatabasePath;
    } else if (_kIsWeb || pu.isFileUriDatabasePath(path)) {
      // nothing
    } else {
      if (isRelative(path)) {
        path = join(await getDatabasesPath(), path);
      }
      path = absolute(normalize(path));
    }
    return path;
  }

  /// Debug information.
  Future<SqfliteDebugInfo> getDebugInfo() async {
    final info = SqfliteDebugInfo();
    final map = await safeInvokeMethod<Map>(
        methodDebug, <String, Object?>{'cmd': 'get'});
    final databasesMap = map[paramDatabases];
    if (databasesMap is Map) {
      info.databases = databasesMap.map((dynamic id, dynamic info) {
        final dbInfo = SqfliteDatabaseDebugInfo();
        final databaseId = id.toString();

        if (info is Map) {
          dbInfo.fromMap(info);
        }
        return MapEntry<String, SqfliteDatabaseDebugInfo>(databaseId, dbInfo);
      });
    }
    info.logLevel = map[paramLogLevel] as int?;
    return info;
  }

  @override
  String toString() => 'SqfliteDatabaseFactory(${tag ?? 'sqflite'})';
}

// When opening the database (bool)
/// Native parameter (int)
const String paramLogLevel = 'logLevel';

/// Native parameter
const String paramDatabases = 'databases';

/// Debug information
class SqfliteDatabaseDebugInfo {
  /// Database path
  String? path;

  /// Whether the database was open as a single instance
  bool? singleInstance;

  /// Log level
  int? logLevel;

  /// Deserializer
  void fromMap(Map<dynamic, dynamic> map) {
    path = map[paramPath]?.toString();
    singleInstance = map[paramSingleInstance] as bool?;
    logLevel = map[paramLogLevel] as int?;
  }

  /// Debug formatting helper
  Map<String, Object?> toDebugMap() {
    final map = <String, Object?>{
      paramPath: path,
      paramSingleInstance: singleInstance
    };
    if ((logLevel ?? sqfliteLogLevelNone) > sqfliteLogLevelNone) {
      map[paramLogLevel] = logLevel;
    }
    return map;
  }

  @override
  String toString() => toDebugMap().toString();
}

/// Internal debug info
class SqfliteDebugInfo {
  /// List of databases
  Map<String, SqfliteDatabaseDebugInfo>? databases;

  /// global log level (set for new opened databases)
  int? logLevel;

  /// Debug formatting helper
  Map<String, Object?> toDebugMap() {
    final map = <String, Object?>{};
    if (databases != null) {
      map[paramDatabases] = databases!.map(
          (String key, SqfliteDatabaseDebugInfo dbInfo) =>
              MapEntry<String, Map<String, Object?>>(key, dbInfo.toDebugMap()));
    }
    if ((logLevel ?? sqfliteLogLevelNone) > sqfliteLogLevelNone) {
      map[paramLogLevel] = logLevel;
    }
    return map;
  }

  @override
  String toString() => toDebugMap().toString();
}
