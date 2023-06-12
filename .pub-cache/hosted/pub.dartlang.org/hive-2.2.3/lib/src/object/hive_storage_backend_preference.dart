part of hive;

/// declares the preferred JS StorageBackend to be used
///
/// - [native] causes almost no startup delay while being slow with huge DB
/// transactions
/// - [webWorker] has got a small startup delay but is much quicker with huge DB
/// transactions
enum HiveStorageBackendPreference {
  /// runs the DB transaction the the main thread
  native,

  /// uses a web worker for DB transactions
  webWorker,
}
