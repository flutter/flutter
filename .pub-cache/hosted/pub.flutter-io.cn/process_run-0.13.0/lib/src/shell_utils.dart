import 'dart:convert';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/io/shell_words.dart' as io show shellSplit;
import 'package:process_run/src/shell_environment.dart';

import 'bin/shell/import.dart';
import 'env_utils.dart';
import 'shell_utils_common.dart';

// Compat
export 'shell_utils_common.dart'
    show
        argumentToString,
        argumentsToString,
        shellArguments,
        shellArgument,
        streamSinkWrite,
        streamSinkWriteln,
        envPathKey,
        envPathSeparator;

/// True if the line is a comment.
///
/// line must have been trimmed before
bool isLineComment(String line) {
  return line.startsWith('#') ||
      line.startsWith('// ') ||
      line.startsWith('/// ') ||
      (line == '//') ||
      (line == '///');
}

/// True if the line is to be continue.
///
/// line must have been trimmed before
bool isLineToBeContinued(String line) {
  return line.endsWith(' ^') ||
      line.endsWith(r' \') ||
      (line == '^') ||
      (line == '\\');
}

/// Convert a script to multiple commands
List<String?> scriptToCommands(String script) {
  var commands = <String?>[];
  // non null when previous line ended with ^ or \
  String? currentCommand;
  for (var line in LineSplitter.split(script)) {
    line = line.trim();

    void addAndClearCurrent(String? command) {
      commands.add(command);
      currentCommand = null;
    }

    if (line.isNotEmpty) {
      if (isLineComment(line)) {
        commands.add(line);
      } else {
        // append to previous
        if (currentCommand != null) {
          line = '$currentCommand $line';
        }
        if (isLineToBeContinued(line)) {
          // remove ending character
          currentCommand = line.substring(0, line.length - 1).trim();
        } else {
          addAndClearCurrent(line);
        }
      }
    } else {
      // terminate current
      if (currentCommand != null) {
        addAndClearCurrent(currentCommand);
      }
    }
  }
  return commands;
}

String? _userAppDataPath;

/// Returns the user data path
///
/// On windows, it is read from the `APPDATA` environment variable. Otherwise
/// it is the `~/.config` folder
String get userAppDataPath => _userAppDataPath ??= () {
      var override = platformEnvironment[userAppDataPathEnvKey];
      if (override != null) {
        return override;
      }
      if (Platform.isWindows) {
        return platformEnvironment['APPDATA'];
      }
      return null;
    }() ??
    join(userHomePath, '.config');

String? _userHomePath;

/// Return the user home path.
///
/// Usually read from the `HOME` environment variable or `USERPROFILE` on
/// Windows.
String get userHomePath =>
    _userHomePath ??= platformEnvironment[userHomePathEnvKey] ??
        platformEnvironment['HOME'] ??
        platformEnvironment['USERPROFILE'] ??
        '~';

/// Expand home if needed
String expandPath(String path) {
  if (path == '~') {
    return userHomePath;
  }
  if (path.startsWith('~/') || path.startsWith(r'~\')) {
    return '$userHomePath${path.substring(1)}';
  }
  return path;
}

/// Convert executable + arguments to a single script line
String shellExecutableArguments(String executable, List<String> arguments) =>
    executableArgumentsToString(executable, arguments);

/// Cached shell environment with user config
// Map<String, String> get platformEnvironment => rawShellEnvironment

/// Same as userEnvironment
Map<String, String> get shellEnvironment =>
    _shellEnvironment ?? userEnvironment;

/// Set only when overriden.
Map<String, String>? _shellEnvironment;

/// Cached raw shell environment
Map<String, String>? _platformEnvironment;

/// Environment without debug VM_OPTIONS and without any user overrides
///
/// Instead replace with an optional TEKARTIK_DART_VM_OPTIONS
Map<String, String> get platformEnvironment => _platformEnvironment ??=
    environmentFilterOutVmOptions(Platform.environment);

/// Warning, change the platform environment and reset.
set platformEnvironment(Map<String, String>? environment) {
  _userAppDataPath = null;
  _userHomePath = null;
  _platformEnvironment = environment;
  shellEnvironment = null;
}

/// Warning, change the shell environment for the next run commands.
set shellEnvironment(Map<String, String>? environment) {
  if (environment == null) {
    _shellEnvironment = null;
  } else {
    _shellEnvironment = asShellEnvironment(environment);
  }
}

/// Raw overriden environment
Map<String, String> environmentFilterOutVmOptions(
    Map<String, String> platformEnvironment) {
  Map<String, String>? environment;
  var vmOptions = platformEnvironment['DART_VM_OPTIONS'];
  if (vmOptions != null) {
    environment = Map<String, String>.from(platformEnvironment);
    environment.remove('DART_VM_OPTIONS');
  }
  var tekartikVmOptions = platformEnvironment['TEKARTIK_DART_VM_OPTIONS'];
  if (tekartikVmOptions != null) {
    environment ??= Map<String, String>.from(platformEnvironment);
    environment['DART_VM_OPTIONS'] = tekartikVmOptions;
  }
  return environment ?? platformEnvironment;
}

List<String>? _windowsPathExts;

/// Default extension for PATHEXT on Windows
List<String> get windowsPathExts => _windowsPathExts ??=
    environmentGetWindowsPathExt(platformEnvironment) ?? windowsDefaultPathExt;

List<String>? environmentGetWindowsPathExt(
        Map<String, String> platformEnvironment) =>
    platformEnvironment['PATHEXT']
        ?.split(windowsEnvPathSeparator)
        .map((ext) => ext.toLowerCase())
        .toList(growable: false);

/// fix runInShell for Windows
bool fixRunInShell(bool? runInShell, String executable) {
  if (Platform.isWindows) {
    if (runInShell != false) {
      if (runInShell == null) {
        if (extension(executable).toLowerCase() != '.exe') {
          return true;
        }
      }
    }
  }
  return runInShell ?? false;
}

/// Use io package shellSplit implementation
List<String> shellSplit(String command) =>
    io.shellSplit(command.replaceAll(r'\', r'\\'));

/// Inverse of shell split
String shellJoin(List<String> parts) =>
    parts.map((part) => shellArgument(part)).join(' ');

/// Find command in path
String? findExecutableSync(String command, List<String?> paths) {
  for (var path in paths) {
    var commandPath = absolute(normalize(join(path!, command)));

    if (Platform.isWindows) {
      for (var ext in windowsPathExts) {
        var commandPathWithExt = '$commandPath$ext';
        if (File(commandPathWithExt).existsSync()) {
          return normalize(commandPathWithExt);
        }
      }
      // Try without extension
      if (File(commandPath).existsSync()) {
        return commandPath;
      }
    } else {
      var stats = File(commandPath).statSync();
      if (stats.type == FileSystemEntityType.file ||
          stats.type == FileSystemEntityType.link) {
        // Check executable permission
        if (stats.mode & 0x49 != 0) {
          // binary 001001001
          // executable
          return commandPath;
        }
      }
    }
  }

  return null;
}

List<String>? _platformEnvironmentPaths;

/// Get platform environment path
List<String> get platformEnvironmentPaths =>
    _platformEnvironmentPaths ??= _getEnvironmentPaths(platformEnvironment);

List<String> getEnvironmentPaths([Map<String, String>? environment]) {
  if (environment == null) {
    return platformEnvironmentPaths;
  }
  return _getEnvironmentPaths(environment);
}

/// No io dependency here.
///
/// Never null
List<String> _getEnvironmentPaths(Map<String, String> environment) =>
    environment[envPathKey]?.split(envPathSeparator) ?? <String>[];

/// IOSink extension
extension IOSinkExt on IOSink {
  /// Catch exception
  Future<void> safeFlush() async {
    try {
      if (Platform.isWindows && isRelease) {
        // Don't flush on release on windows as calling twice hangs in compiled mode
      } else {
        await flush();
      }
    } catch (_) {}
  }
}
