import 'package:sqflite_common/sqlite_api.dart';

///
/// Options to open a database
/// See [openDatabase] for details
///
class SqfliteOpenDatabaseOptions implements OpenDatabaseOptions {
  /// See [openDatabase] for details
  SqfliteOpenDatabaseOptions({
    this.version,
    this.onConfigure,
    this.onCreate,
    this.onUpgrade,
    this.onDowngrade,
    this.onOpen,
    bool? readOnly = false,
    bool? singleInstance = true,
  })  : readOnly = readOnly ?? false,
        singleInstance = singleInstance ?? true;

  @override
  int? version;
  @override
  OnDatabaseConfigureFn? onConfigure;
  @override
  OnDatabaseCreateFn? onCreate;
  @override
  OnDatabaseVersionChangeFn? onUpgrade;
  @override
  OnDatabaseVersionChangeFn? onDowngrade;
  @override
  OnDatabaseOpenFn? onOpen;
  @override
  bool readOnly;
  @override
  bool singleInstance;

  @override
  String toString() {
    final map = <String, Object?>{};
    if (version != null) {
      map['version'] = version;
    }
    map['readOnly'] = readOnly;
    map['singleInstance'] = singleInstance;
    return map.toString();
  }
}
