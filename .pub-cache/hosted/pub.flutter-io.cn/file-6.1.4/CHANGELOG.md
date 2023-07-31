#### 6.1.4

* Populate the pubspec `repository` field.

#### 6.1.3

* In classes that implement `File` methods `create`, `createSync` now take `bool exclusive = true` parameter. No functional changes.

#### 6.1.2

* `MemoryFileSystem` now provides `opHandle`s for exists operations.

#### 6.1.1

* `MemoryFile` now provides `opHandle`s for copy and open operations.

#### 6.1.0

* Reading invalid UTF8 with the `MemoryFileSystem` now correctly throws a `FileSystemException` instead of a `FormatError`.
* `MemoryFileSystem` now provides an `opHandle` to inspect read/write operations.
* `MemoryFileSystem` now creates the temporary directory before returning in `createTemp`/`createTempSync`.

#### 6.0.1

* Fix sound type error in memory backend when reading non-existent `MemoryDirectory`.

#### 6.0.0

* First stable null safe release.

#### 6.0.0-nullsafety.4

* Update upper bound of SDK constraint.

#### 6.0.0-nullsafety.3

* Update upper bound of SDK constraint.

#### 6.0.0-nullsafety.2

* Make `ForwardingFile.openRead`'s return type again match the return type from
  `dart:io`.
* Remove some unnecessary `Uint8List` conversions in `ForwardingFile`.

#### 6.0.0-nullsafety.1

* Update to null safety.
* Remove record/replay functionality.
* Made `MemoryRandomAccessFile` and `MemoryFile.openWrite` handle the file
  being removed or renamed while open.
* Fixed incorrect formatting in `NoMatchingInvocationError.toString()`.
* Fixed more test flakiness.
* Enabled more tests.
* Internal cleanup.
* Remove implicit dynamic in preparation for null safety.
* Remove dependency on Intl.

#### 5.2.1

* systemTemp directories created by `MemoryFileSystem` will allot names
  based on the file system instance instead of globally.
* `MemoryFile.readAsLines()`/`readAsLinesSync()` no longer treat a final newline
  in the file as the start of a new, empty line.
* `RecordingFile.readAsLine()`/`readAsLinesSync()` now always record a final
  newline.
* `MemoryFile.flush()` now returns `Future<void>` instead of `Future<dynamic>`.
* Fixed some test flakiness.
* Enabled more tests.
* Internal cleanup.

#### 5.2.0

* Added a `MemoryRandomAccessFile` class and implemented
  `MemoryFile.open()`/`openSync()`.

#### 5.1.0

* Added a new `MemoryFileSystem` constructor to use a test clock

#### 5.0.10

* Added example

#### 5.0.9

* Fix lints for project health

#### 5.0.8

* Return `Uint8List` rather than `List<int>`.

#### 5.0.7

* Dart 2 fixes for `RecordingProxyMixin` and `ReplayProxyMixin`.

#### 5.0.6

* Dart 2 fixes for `RecordingFile.open()`

#### 5.0.5

* Dart 2 fixes

#### 5.0.4

* Update SDK constraint to 2.0.0-dev.67.0, remove workaround in
  recording_proxy_mixin.dart.
* Fix usage within Dart 2 runtime mode in Dart 2.0.0-dev.61.0 and later.
* Relax constraints on `package:test`

#### 5.0.3

* Update `package:test` dependency to 1.0

#### 5.0.2

* Declare compatibility with Dart 2 stable

#### 5.0.1

* Remove upper case constants
* Update SDK constraint to 2.0.0-dev.54.0.

#### 5.0.0

* Moved `testing` library into a dedicated `package:file_testing` so that
  libraries don't need to take on a transitive dependency on `package:test`
  in order to use `package:file`.

#### 4.0.1

* General library cleanup
* Add `style` support in `MemoryFileSystem`, so that callers can choose to
  have a memory file system with windows-like paths. [#68]
  (https://github.com/google/file.dart/issues/68)

#### 4.0.0

* Change method signature for `RecordingRandomAccessFile._close` to return a
  `Future<void>` instead of `Future<RandomAccessFile>`. This follows a change in
  dart:io, Dart SDK `2.0.0-dev.40`.

#### 3.0.0

* Import `dart:io` unconditionally. More recent Dart SDK revisions allow
  `dart:io` to be imported in a browser context, though if methods are actually
  invoked, they will fail. This matches well with `package:file`, where users
  can use the `memory` library and get in-memory implementations of the
  `dart:io` interfaces.
* Bump minimum Dart SDK to `1.24.0`

#### 2.3.7

* Fix Dart 2 error.

#### 2.3.6

* Relax sdk upper bound constraint to  '<2.0.0' to allow 'edge' dart sdk use.

#### 2.3.5

* Fix internal use of a cast which fails on Dart 2.0 .

#### 2.3.4

* Bumped maximum Dart SDK version to 2.0.0-dev.infinity

#### 2.3.3

* Relaxes version requirements on `package:intl`

#### 2.3.2

* Fixed `FileSystem.directory(Uri)`, `FileSystem.file(Uri)`, and
  `FileSystem.link(Uri)` to consult the file system's path context when
  converting the URI to a file path rather than using `Uri.toFilePath()`.

#### 2.3.1

* Fixed `MemoryFileSystem` to make `File.writeAs...()` update the last modified
  time of the file.

#### 2.3.0

* Added the following convenience methods in `Directory`:
  * `Directory.childDirectory(String basename)`
  * `Directory.childFile(String basename)`
  * `Directory.childLink(String basename)`

#### 2.2.0

* Added `ErrorCodes` class, which holds errno values.

#### 2.1.0

* Add support for new `dart:io` API methods added in Dart SDK 1.23

#### 2.0.1

* Minor doc updates

#### 2.0.0

* Improved `toString` implementations in file system entity classes
* Added `ForwardingFileSystem` and associated forwarding classes to the
  main `file` library
* Removed `FileSystem.pathSeparator`, and added a more comprehensive
  `FileSystem.path` property
* Added `FileSystemEntity.basename` and `FileSystemEntity.dirname`
* Added the `record_replay` library
* Added the `testing` library

#### 1.0.1

* Added `FileSystem.systemTempDirectory`
* Added the ability to pass `Uri` and `FileSystemEntity` types to
  `FileSystem.directory()`, `FileSystem.file()`, and `FileSystem.link()`
* Added `FileSystem.pathSeparator`

#### 1.0.0

* Unified interface to match dart:io API
* Local file system implementation
* In-memory file system implementation
* Chroot file system implementation

#### 0.1.0

* Initial version
