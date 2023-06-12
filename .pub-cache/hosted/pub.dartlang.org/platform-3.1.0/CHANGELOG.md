### 3.1.0

* Removed `Platform.packageRoot`, which was already marked deprecated, and which
  didn't work in Dart 2.

### 3.0.2

* Added `FakePlatform.copyWith` function.

### 3.0.1

* Added string constants for each of the supported platforms for use in switch
  statements.

### 3.0.0

* First stable null safe release.

### 3.0.0-nullsafety.4

* Update supported SDK range.

### 3.0.0-nullsafety.3

* Update supported SDK range.

### 3.0.0-nullsafety.2

* Update supported SDK range.

### 3.0.0-nullsafety.1

* Migrate package to null-safe dart.

### 2.2.1

* Add `operatingSystemVersion`

### 2.2.0

* Declare compatibility with Dart 2 stable
* Update dependency on `package:test` to 1.0

### 2.1.2

* Relax sdk upper bound constraint to  '<2.0.0' to allow 'edge' dart sdk use.

### 2.1.1

* Bumped maximum Dart SDK version to 2.0.0-dev.infinity

### 2.1.0

* Added `localeName`
* Bumped minimum Dart SDK version to 1.24.0-dev.0.0

### 2.0.0

* Added `stdinSupportsAnsi` and `stdinSupportsAnsi`
* Removed `ansiSupported`

### 1.1.1

* Updated `LocalPlatform` to use new `dart.io` API for ansi color support queries
* Bumped minimum Dart SDK version to 1.23.0-dev.10.0

### 1.1.0

* Added `ansiSupported`
* Bumped minimum Dart SDK version to 1.23.0-dev.9.0

#### 1.0.2

* Minor doc updates

#### 1.0.1

* Added const constructors for `Platform` and `LocalPlatform`

#### 1.0.0

* Initial version
