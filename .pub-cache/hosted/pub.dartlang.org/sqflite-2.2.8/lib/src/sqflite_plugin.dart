import 'package:sqflite/sqflite.dart';

import 'factory_impl.dart';

/// sqflite Plugin registration.
class SqflitePlugin {
  /// Registers this plugin as the default database factory.
  static void registerWith() {
    databaseFactory = sqfliteDatabaseFactoryDefault;
  }
}
