part of hive;

/// The main API interface of Hive. Available through the `Hive` constant.
abstract class HiveInterface implements TypeRegistry {
  /// Initialize Hive by giving it a home directory.
  ///
  /// (Not necessary in the browser)
  void init(
    String? path, {
    HiveStorageBackendPreference backendPreference =
        HiveStorageBackendPreference.native,
  });

  /// Opens a box.
  ///
  /// If the box is already open, the instance is returned and all provided
  /// parameters are being ignored.
  Future<Box<E>> openBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    Uint8List? bytes,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  });

  /// Opens a lazy box.
  ///
  /// If the box is already open, the instance is returned and all provided
  /// parameters are being ignored.
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  });

  /// Returns a previously opened box.
  Box<E> box<E>(String name);

  /// Returns a previously opened lazy box.
  LazyBox<E> lazyBox<E>(String name);

  /// Checks if a specific box is currently open.
  bool isBoxOpen(String name);

  /// Closes all open boxes.
  Future<void> close();

  /// Removes the file which contains the box and closes the box.
  ///
  /// In the browser, the IndexedDB database is being removed.
  Future<void> deleteBoxFromDisk(String name, {String? path});

  /// Deletes all currently open boxes from disk.
  ///
  /// The home directory will not be deleted.
  Future<void> deleteFromDisk();

  /// Generates a secure encryption key using the fortuna random algorithm.
  List<int> generateSecureKey();

  /// Checks if a box exists
  Future<bool> boxExists(String name, {String? path});

  /// Clears all registered adapters.
  ///
  /// To register an adapter use [registerAdapter].
  ///
  /// NOTE: [resetAdapters] also clears the default adapters registered
  /// by Hive.
  ///
  /// WARNING: This method is only intended to be used for integration and unit tests
  /// and SHOULD not be used in production code.
  @visibleForTesting
  void resetAdapters();
}

///
typedef KeyComparator = int Function(dynamic key1, dynamic key2);

/// A function which decides when to compact a box.
typedef CompactionStrategy = bool Function(int entries, int deletedEntries);
