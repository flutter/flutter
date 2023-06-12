// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities to return the Dart SDK location.
library cli_util;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'src/utils.dart';

/// Return the path to the current Dart SDK.
///
/// This first checks for an explicit SDK listed on the command-line
/// (`--dart-sdk`). It then looks in any `DART_SDK` environment variable. Next,
/// it looks relative to the Dart VM executable. Last, it uses the
/// [Platform.resolvedExecutable] API.
///
/// Callers should generally prefer using the [getSdkPath] function.
@Deprecated('Clients should generally prefer getSdkPath()')
Directory getSdkDir([List<String>? cliArgs]) {
  // Look for --dart-sdk on the command line.
  if (cliArgs != null) {
    var index = cliArgs.indexOf('--dart-sdk');

    if (index != -1 && (index + 1 < cliArgs.length)) {
      return Directory(cliArgs[index + 1]);
    }

    for (var arg in cliArgs) {
      if (arg.startsWith('--dart-sdk=')) {
        return Directory(arg.substring('--dart-sdk='.length));
      }
    }
  }

  // Look in env['DART_SDK']
  var sdkLocation = Platform.environment['DART_SDK'];
  if (sdkLocation != null) {
    return Directory(sdkLocation);
  }

  // Look relative to the dart executable.
  var platformExecutable = File(Platform.executable);
  var sdkDirectory = platformExecutable.parent.parent;
  if (isSdkDir(sdkDirectory)) return sdkDirectory;

  // Handle the case where Platform.executable is a sibling of the SDK directory
  // (this happens during internal testing).
  sdkDirectory =
      Directory(path.join(platformExecutable.parent.path, 'dart-sdk'));
  if (isSdkDir(sdkDirectory)) return sdkDirectory;

  // Use `Platform.resolvedExecutable`.
  return Directory(getSdkPath());
}

/// Return the path to the current Dart SDK.
String getSdkPath() => path.dirname(path.dirname(Platform.resolvedExecutable));

/// Get the user-specific application configuration folder for the current
/// platform.
///
/// This is a location appropriate for storing application specific
/// configuration for the current user. The [productName] should be unique to
/// avoid clashes with other applications on the same machine. This method won't
/// actually create the folder, merely return the recommended location for
/// storing user-specific application configuration.
///
/// The folder location depends on the platform:
///  * `%APPDATA%\<productName>` on **Windows**,
///  * `$HOME/Library/Application Support/<productName>` on **Mac OS**,
///  * `$XDG_CONFIG_HOME/<productName>` on **Linux**
///     (if `$XDG_CONFIG_HOME` is defined), and,
///  * `$HOME/.config/<productName>` otherwise.
///
/// This aims follows best practices for each platform, honoring the
/// [XDG Base Directory Specification][1] on Linux and [File System Basics][2]
/// on Mac OS.
///
/// Throws an [EnvironmentNotFoundException] if `%APPDATA%` or `$HOME` is needed
/// but undefined.
///
/// [1]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
/// [2]: https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW1
String applicationConfigHome(String productName) =>
    path.join(_configHome, productName);

String get _configHome {
  if (Platform.isWindows) {
    final appdata = Platform.environment['APPDATA'];
    if (appdata == null) {
      throw EnvironmentNotFoundException(
          'Environment variable %APPDATA% is not defined!');
    }
    return appdata;
  }

  if (Platform.isMacOS) {
    return path.join(_home, 'Library', 'Application Support');
  }

  if (Platform.isLinux) {
    final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null) {
      return xdgConfigHome;
    }
    // XDG Base Directory Specification says to use $HOME/.config/ when
    // $XDG_CONFIG_HOME isn't defined.
    return path.join(_home, '.config');
  }

  // We have no guidelines, perhaps we should just do: $HOME/.config/
  // same as XDG specification would specify as fallback.
  return path.join(_home, '.config');
}

String get _home {
  final home = Platform.environment['HOME'];
  if (home == null) {
    throw EnvironmentNotFoundException(
        'Environment variable \$HOME is not defined!');
  }
  return home;
}

class EnvironmentNotFoundException implements Exception {
  final String message;
  EnvironmentNotFoundException(this.message);
  @override
  String toString() {
    return message;
  }
}
