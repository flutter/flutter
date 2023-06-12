// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Exit code constants.
///
/// [Source](https://www.freebsd.org/cgi/man.cgi?query=sysexits).
class ExitCode {
  /// Command completed successfully.
  static const success = ExitCode._(0, 'success');

  /// Command was used incorrectly.
  ///
  /// This may occur if the wrong number of arguments was used, a bad flag, or
  /// bad syntax in a parameter.
  static const usage = ExitCode._(64, 'usage');

  /// Input data was used incorrectly.
  ///
  /// This should occur only for user data (not system files).
  static const data = ExitCode._(65, 'data');

  /// An input file (not a system file) did not exist or was not readable.
  static const noInput = ExitCode._(66, 'noInput');

  /// User specified did not exist.
  static const noUser = ExitCode._(67, 'noUser');

  /// Host specified did not exist.
  static const noHost = ExitCode._(68, 'noHost');

  /// A service is unavailable.
  ///
  /// This may occur if a support program or file does not exist. This may also
  /// be used as a catch-all error when something you wanted to do does not
  /// work, but you do not know why.
  static const unavailable = ExitCode._(69, 'unavailable');

  /// An internal software error has been detected.
  ///
  /// This should be limited to non-operating system related errors as possible.
  static const software = ExitCode._(70, 'software');

  /// An operating system error has been detected.
  ///
  /// This intended to be used for such thing as `cannot fork` or `cannot pipe`.
  static const osError = ExitCode._(71, 'osError');

  /// Some system file (e.g. `/etc/passwd`) does not exist or could not be read.
  static const osFile = ExitCode._(72, 'osFile');

  /// A (user specified) output file cannot be created.
  static const cantCreate = ExitCode._(73, 'cantCreate');

  /// An error occurred doing I/O on some file.
  static const ioError = ExitCode._(74, 'ioError');

  /// Temporary failure, indicating something is not really an error.
  ///
  /// In some cases, this can be re-attempted and will succeed later.
  static const tempFail = ExitCode._(75, 'tempFail');

  /// You did not have sufficient permissions to perform the operation.
  ///
  /// This is not intended for file system problems, which should use [noInput]
  /// or [cantCreate], but rather for higher-level permissions.
  static const noPerm = ExitCode._(77, 'noPerm');

  /// Something was found in an unconfigured or misconfigured state.
  static const config = ExitCode._(78, 'config');

  /// Exit code value.
  final int code;

  /// Name of the exit code.
  final String _name;

  const ExitCode._(this.code, this._name);

  @override
  String toString() => '$_name: $code';
}
