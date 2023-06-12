import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';

import 'native/backend_manager.dart' as native;

/// Opens IndexedDB databases
abstract class BackendManager {
  BackendManager._();

  // dummy implementation as the WebWorker branch is not stable yet
  static BackendManagerInterface select(
      [HiveStorageBackendPreference? backendPreference]) {
    switch (backendPreference) {
      default:
        return native.BackendManager();
    }
  }
}
