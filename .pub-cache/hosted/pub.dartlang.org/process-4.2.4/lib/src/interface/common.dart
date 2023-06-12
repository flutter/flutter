// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' show Context;
import 'package:platform/platform.dart';

import 'exceptions.dart';

const Map<String, String> _osToPathStyle = <String, String>{
  'linux': 'posix',
  'macos': 'posix',
  'android': 'posix',
  'ios': 'posix',
  'fuchsia': 'posix',
  'windows': 'windows',
};

/// Sanitizes the executable path on Windows.
/// https://github.com/dart-lang/sdk/issues/37751
String sanitizeExecutablePath(String executable,
    {Platform platform = const LocalPlatform()}) {
  if (executable.isEmpty) {
    return executable;
  }
  if (!platform.isWindows) {
    return executable;
  }
  if (executable.contains(' ') && !executable.contains('"')) {
    // Use quoted strings to indicate where the file name ends and the arguments begin;
    // otherwise, the file name is ambiguous.
    return '"$executable"';
  }
  return executable;
}

/// Searches the `PATH` for the executable that [executable] is supposed to launch.
///
/// This first builds a list of candidate paths where the executable may reside.
/// If [executable] is already an absolute path, then the `PATH` environment
/// variable will not be consulted, and the specified absolute path will be the
/// only candidate that is considered.
///
/// Once the list of candidate paths has been constructed, this will pick the
/// first such path that represents an existent file.
///
/// Return `null` if there were no viable candidates, meaning the executable
/// could not be found.
///
/// If [platform] is not specified, it will default to the current platform.
String? getExecutablePath(
  String executable,
  String? workingDirectory, {
  Platform platform = const LocalPlatform(),
  FileSystem fs = const LocalFileSystem(),
  bool throwOnFailure = false,
}) {
  assert(_osToPathStyle[platform.operatingSystem] == fs.path.style.name);
  try {
    workingDirectory ??= fs.currentDirectory.path;
  } on FileSystemException {
    // The `currentDirectory` getter can throw a FileSystemException for example
    // when the process doesn't have read/list permissions in each component of
    // the cwd path. In this case, fall back on '.'.
    workingDirectory ??= '.';
  }
  Context context = Context(style: fs.path.style, current: workingDirectory);

  // TODO(goderbauer): refactor when github.com/google/platform.dart/issues/2
  //     is available.
  String pathSeparator = platform.isWindows ? ';' : ':';

  List<String> extensions = <String>[];
  if (platform.isWindows && context.extension(executable).isEmpty) {
    extensions = platform.environment['PATHEXT']!.split(pathSeparator);
  }

  List<String> candidates = <String>[];
  List<String> searchPath;
  if (executable.contains(context.separator)) {
    // Deal with commands that specify a relative or absolute path differently.
    searchPath = <String>[workingDirectory];
  } else {
    searchPath = platform.environment['PATH']!.split(pathSeparator);
  }
  candidates = _getCandidatePaths(executable, searchPath, extensions, context);
  final List<String> foundCandidates = <String>[];
  for (String path in candidates) {
    final File candidate = fs.file(path);
    FileStat stat = candidate.statSync();
    // Only return files or links that exist.
    if (stat.type == FileSystemEntityType.notFound ||
        stat.type == FileSystemEntityType.directory) {
      continue;
    }

    // File exists, but we don't know if it's readable/executable yet.
    foundCandidates.add(candidate.path);

    const int isExecutable = 0x40;
    const int isReadable = 0x100;
    const int isExecutableAndReadable = isExecutable | isReadable;
    // Should only return files or links that are readable and executable by the
    // user.

    // On Windows it's not actually possible to only return files that are
    // readable, since Dart reports files that have had read permission removed
    // as being readable, but not checking for it is the same as checking for it
    // and finding it readable, so we use the same check here on all platforms,
    // so that if Dart ever gets fixed, it'll just work.
    if (stat.mode & isExecutableAndReadable == isExecutableAndReadable) {
      return path;
    }
  }
  if (throwOnFailure) {
    if (foundCandidates.isNotEmpty) {
      throw ProcessPackageExecutableNotFoundException(
        executable,
        message:
            'Found candidates, but lacked sufficient permissions to execute "$executable".',
        workingDirectory: workingDirectory,
        candidates: foundCandidates,
        searchPath: searchPath,
      );
    } else {
      throw ProcessPackageExecutableNotFoundException(
        executable,
        message: 'Failed to find "$executable" in the search path.',
        workingDirectory: workingDirectory,
        searchPath: searchPath,
      );
    }
  }
  return null;
}

/// Returns all possible combinations of `$searchPath\$command.$ext` for
/// `searchPath` in [searchPaths] and `ext` in [extensions].
///
/// If [extensions] is empty, it will just enumerate all
/// `$searchPath\$command`.
/// If [command] is an absolute path, it will just enumerate
/// `$command.$ext`.
List<String> _getCandidatePaths(
  String command,
  List<String> searchPaths,
  List<String> extensions,
  Context context,
) {
  List<String> withExtensions = extensions.isNotEmpty
      ? extensions.map((String ext) => '$command$ext').toList()
      : <String>[command];
  if (context.isAbsolute(command)) {
    return withExtensions;
  }
  return searchPaths
      .map((String path) =>
          withExtensions.map((String command) => context.join(path, command)))
      .expand((Iterable<String> e) => e)
      .toList()
      .cast<String>();
}
