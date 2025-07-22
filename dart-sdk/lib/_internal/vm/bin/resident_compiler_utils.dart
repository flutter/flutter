// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

/// If [maybeUri] is a file uri, this function returns the result of converting
/// [maybeUri] to a file path. Otherwise, it returns [maybeUri] back unmodified.
String maybeUriToFilename(String maybeUri) {
  try {
    return Uri.parse(maybeUri).toFilePath();
  } catch (_) {
    return maybeUri;
  }
}

/// Joins [a] and [b] with a backslash if [Platform.isWindows] is true,
/// otherwise joins [a] and [b] with a slash.
String joinPathComponents(final String a, final String b) =>
    !Platform.isWindows ? '$a/$b' : '$a\\$b';

/// The user's home directory for the current platform, or [null] if it can't be
/// found.
Directory? get homeDir {
  final envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  final envValue = Platform.environment[envKey];

  if (envValue == null) {
    return null;
  }

  final dir = Directory(envValue);
  return dir.existsSync() ? dir : null;
}

/// The directory used to store the default resident compiler info file, which
/// is the `.dart` subdirectory of the user's home directory. This function will
/// return [null] the directory is inaccessible.
Directory? getDartStorageDirectory() {
  var dir = homeDir;
  if (dir == null) {
    return null;
  } else {
    return Directory(joinPathComponents(dir.path, '.dart'));
  }
}

/// The default resident frontend compiler information file.
///
/// Resident frontend compiler info files contain the contents:
/// `address:$address port:$port`.
File? get defaultResidentServerInfoFile {
  var dartConfigDir = getDartStorageDirectory();
  if (dartConfigDir == null) return null;

  return File(
    joinPathComponents(dartConfigDir.path, 'dartdev_compilation_server_info'),
  );
}

// Used in `pkg/dartdev/lib/src/resident_frontend_utils.dart` and in
// `sdk/lib/_internal/vm/bin/vmservice_io.dart`.
File? getResidentCompilerInfoFileConsideringArgsImpl(
  /// If either `--resident-compiler-info-file` or `--resident-server-info-file`
  /// was supplied on the command line, the CLI argument should be forwarded as
  /// the argument to this parameter. If neither option was supplied, the
  /// argument to this parameter should be [null].
  String? residentCompilerInfoFilePathArgumentFromCli,
) {
  if (residentCompilerInfoFilePathArgumentFromCli != null) {
    return File(
      maybeUriToFilename(residentCompilerInfoFilePathArgumentFromCli),
    );
  }
  return defaultResidentServerInfoFile!;
}
