#### 4.2.4

* Mark `stderrEncoding` and `stdoutEncoding` parameters as nullable again,
  now that the upstream SDK issue has been fixed.

#### 4.2.3

* Rollback to version 4.2.1 (https://github.com/google/process.dart/issues/64)

#### 4.2.2

* Mark `stderrEncoding` and `stdoutEncoding` parameters as nullable.

#### 4.2.1

* Added custom exception types `ProcessPackageException` and
  `ProcessPackageExecutableNotFoundException` to provide extra
  information from exception conditions.

#### 4.2.0

* Fix the signature of `ProcessManager.canRun` to be consistent with
  `LocalProcessManager`.

#### 4.1.1

* Fixed `getExecutablePath()` to only return path items that are
  executable and readable to the user.

#### 4.1.0

* Fix the signatures of `ProcessManager.run`, `.runSync`, and `.start` to be
  consistent with `LocalProcessManager`'s.
* Added more details to the `ArgumentError` thrown when a command cannot be resolved
  to an executable.

#### 4.0.0

* First stable null safe release.

#### 4.0.0-nullsafety.4

* Update supported SDK range.

#### 4.0.0-nullsafety.3

* Update supported SDK range.

#### 4.0.0-nullsafety.2

* Update supported SDK range.

#### 4.0.0-nullsafety.1

* Migrate to null-safety.
* Remove record/replay functionality.
* Remove implicit casts in preparation for null-safety.
* Remove dependency on `package:intl` and `package:meta`.

#### 3.0.13

* Handle `currentDirectory` throwing an exception in `getExecutablePath()`.

#### 3.0.12

* Updated version constraint on intl.

#### 3.0.11

* Fix bug: don't add quotes if the file name already has quotes.

#### 3.0.10

* Added quoted strings to indicate where the command name ends and the arguments
begin otherwise, the file name is ambiguous on Windows.

#### 3.0.9

* Fixed bug in `ProcessWrapper`

#### 3.0.8

* Fixed bug in `ProcessWrapper`

#### 3.0.7

* Renamed `Process` to `ProcessWrapper`

#### 3.0.6

* Added class `Process`, a simple wrapper around dart:io's `Process` class.

#### 3.0.5

* Fixes for missing_return analysis errors with 2.10.0-dev.1.0.

#### 3.0.4

* Fix unit tests
* Update SDK constraint to 3.

#### 3.0.3

* Update dependency on `package:file`

#### 3.0.2

* Remove upper case constants.
* Update SDK constraint to 2.0.0-dev.54.0.
* Fix tests for Dart 2.

#### 3.0.1

* General cleanup

#### 3.0.0

* Cleanup getExecutablePath() to better respect the platform

#### 2.0.9

* Bumped `package:file` dependency

### 2.0.8

* Fixed method getArguments to qualify the map method with the specific
  String type

### 2.0.7

* Remove `set exitCode` instances

### 2.0.6

* Fix SDK constraint.
* rename .analysis_options file to analaysis_options.yaml.
* Use covariant in place of @checked.
* Update comment style generics.

### 2.0.5

* Bumped maximum Dart SDK version to 2.0.0-dev.infinity

### 2.0.4

* relax dependency requirement for `intl`

### 2.0.3

* relax dependency requirement for `platform`

#### 2.0.2

* Fix a strong mode function expression return type inference bug with Dart
  1.23.0-dev.10.0.

#### 2.0.1

* Fixed bug in `ReplayProcessManager` whereby it could try to write to `stdout`
  or `stderr` after the streams were closed.

#### 2.0.0

* Bumped `package:file` dependency to 2.0.1

#### 1.1.0

* Added support to transparently find the right executable under Windows.

#### 1.0.1

* The `executable` and `arguments` parameters have been merged into one
  `command` parameter in the `run`, `runSync`, and `start` methods of
  `ProcessManager`.
* Added support for sanitization of command elements in
  `RecordingProcessManager` and `ReplayProcessManager` via the `CommandElement`
  class.

#### 1.0.0

* Initial version
