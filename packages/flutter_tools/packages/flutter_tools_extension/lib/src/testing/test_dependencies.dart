// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../dependencies.dart';

/// Creates a hermetic [ExtensionDependencies] container for unit testing
/// extension services without touching host disk, spawning real processes, or
/// making unexpected network requests.
ExtensionDependencies createTestDependencies({
  Map<String, String> environment = const <String, String>{},
  ExtensionFileSystem? fileSystem,
  HttpClient Function()? httpClientFactory,
  ExtensionLogger? logger,
  String operatingSystem = 'linux',
  ExtensionProcessManager? processManager,
}) {
  return ExtensionDependencies(
    environment: Map<String, String>.unmodifiable(environment),
    fileSystem: fileSystem ?? MemoryExtensionFileSystem(),
    httpClientFactory: httpClientFactory ?? _unconfiguredHttpClient,
    logger: logger ?? BufferExtensionLogger(),
    operatingSystem: operatingSystem,
    processManager: processManager ?? FakeExtensionProcessManager(),
  );
}

HttpClient _unconfiguredHttpClient() {
  throw StateError(
    'Unexpected HTTP request in hermetic test. '
    'Pass an explicit httpClientFactory to createTestDependencies().',
  );
}

/// Hermetic in-memory implementation of [ExtensionFileSystem] for unit testing.
final class MemoryExtensionFileSystem implements ExtensionFileSystem {
  MemoryExtensionFileSystem() {
    _directories.add('/');
  }

  final _directories = <String>{};
  final _files = <String, Uint8List>{};

  @override
  ExtensionDirectory directory(Uri uri) => _MemoryExtensionDirectory(this, _normalizeDirPath(uri));

  @override
  ExtensionFile file(Uri uri) => _MemoryExtensionFile(this, _normalizeFilePath(uri));

  static String _normalizeDirPath(Uri uri) {
    final String rawPath = uri.isScheme('file') ? uri.toFilePath(windows: false) : uri.path;
    final String normalized = _collapseSegments(rawPath);
    return normalized.endsWith('/') ? normalized : '$normalized/';
  }

  static String _normalizeFilePath(Uri uri) {
    final String rawPath = uri.isScheme('file') ? uri.toFilePath(windows: false) : uri.path;
    final String normalized = _collapseSegments(rawPath);
    if (normalized != '/' && normalized.endsWith('/')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _collapseSegments(String rawPath) {
    final List<String> parts = rawPath.replaceAll(r'\', '/').split('/');
    final stack = <String>[];
    for (final part in parts) {
      if (part.isEmpty || part == '.') {
        continue;
      }
      if (part == '..') {
        if (stack.isNotEmpty) {
          stack.removeLast();
        }
      } else {
        stack.add(part);
      }
    }
    return '/${stack.join('/')}';
  }

  static String _parentDirOf(String path) {
    final String trimmed = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    final int lastSlash = trimmed.lastIndexOf('/');
    if (lastSlash <= 0) {
      return '/';
    }
    return '${trimmed.substring(0, lastSlash)}/';
  }

  void _createDir(String dirPath, {required bool recursive}) {
    if (_directories.contains(dirPath)) {
      return;
    }
    final String parent = _parentDirOf(dirPath);
    if (!recursive && !_directories.contains(parent)) {
      throw FileSystemException('Creation failed, parent directory does not exist', dirPath);
    }
    final List<String> segments = dirPath.split('/').where((String s) => s.isNotEmpty).toList();
    var current = '/';
    _directories.add(current);
    for (final segment in segments) {
      current = '$current$segment/';
      _directories.add(current);
    }
  }

  void _deleteDir(String dirPath, {required bool recursive}) {
    if (!_directories.contains(dirPath)) {
      throw FileSystemException('Deletion failed, directory does not exist', dirPath);
    }
    final bool hasChildDirs = _directories.any((String d) => d != dirPath && d.startsWith(dirPath));
    final bool hasChildFiles = _files.keys.any((String f) => f.startsWith(dirPath));
    if (!recursive && (hasChildDirs || hasChildFiles)) {
      throw FileSystemException('Directory is not empty', dirPath);
    }
    _directories.removeWhere((String d) => d == dirPath || d.startsWith(dirPath));
    _files.removeWhere((String f, Uint8List _) => f.startsWith(dirPath));
  }
}

final class _MemoryExtensionDirectory implements ExtensionDirectory {
  const _MemoryExtensionDirectory(this._fs, this._dirPath);

  final MemoryExtensionFileSystem _fs;
  final String _dirPath;

  @override
  Uri get uri => Uri(scheme: 'file', path: _dirPath);

  @override
  String get path => _dirPath.length > 1 && _dirPath.endsWith('/')
      ? _dirPath.substring(0, _dirPath.length - 1)
      : _dirPath;

  @override
  bool existsSync() => _fs._directories.contains(_dirPath);

  @override
  void createSync({bool recursive = false}) => _fs._createDir(_dirPath, recursive: recursive);

  @override
  Future<void> delete({bool recursive = false}) async => deleteSync(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) => _fs._deleteDir(_dirPath, recursive: recursive);

  @override
  ExtensionDirectory childDirectory(String name) => _fs.directory(uri.resolve('$name/'));

  @override
  ExtensionFile childFile(String name) => _fs.file(uri.resolve(name));
}

final class _MemoryExtensionFile implements ExtensionFile {
  const _MemoryExtensionFile(this._fs, this._filePath);

  final MemoryExtensionFileSystem _fs;
  final String _filePath;

  @override
  Uri get uri => Uri(scheme: 'file', path: _filePath);

  @override
  String get path => _filePath;

  @override
  bool existsSync() => _fs._files.containsKey(_filePath);

  @override
  void createSync({bool recursive = false}) {
    if (existsSync()) {
      return;
    }
    final String parent = MemoryExtensionFileSystem._parentDirOf(_filePath);
    if (recursive) {
      _fs._createDir(parent, recursive: true);
    } else if (!_fs._directories.contains(parent)) {
      throw FileSystemException('Cannot create file, parent directory does not exist', _filePath);
    }
    _fs._files[_filePath] = Uint8List(0);
  }

  @override
  Future<void> delete({bool recursive = false}) async => deleteSync(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) {
    if (!_fs._files.containsKey(_filePath)) {
      throw FileSystemException('Cannot delete file, path does not exist', _filePath);
    }
    _fs._files.remove(_filePath);
  }

  @override
  String readAsStringSync() => utf8.decode(readAsBytesSync());

  @override
  void writeAsStringSync(String contents) => writeAsBytesSync(utf8.encode(contents));

  @override
  List<int> readAsBytesSync() {
    final Uint8List? bytes = _fs._files[_filePath];
    if (bytes == null) {
      throw FileSystemException('Cannot open file, path does not exist', _filePath);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  void writeAsBytesSync(List<int> bytes) {
    final String parent = MemoryExtensionFileSystem._parentDirOf(_filePath);
    if (!_fs._directories.contains(parent)) {
      throw FileSystemException('Cannot open file, parent directory does not exist', _filePath);
    }
    _fs._files[_filePath] = Uint8List.fromList(bytes);
  }
}

/// Canned process expectation consumed by [FakeExtensionProcessManager].
@immutable
final class FakeExtensionCommand {
  const FakeExtensionCommand({
    required this.command,
    this.environment,
    this.exitCode = 0,
    this.onRun,
    this.stderr = '',
    this.stdout = '',
    this.workingDirectory,
  });

  /// Expected command and argument list.
  final List<String> command;

  /// Optional expected working directory.
  final String? workingDirectory;

  /// Optional expected environment variables.
  final Map<String, String>? environment;

  /// Simulated exit code returned when the command runs.
  final int exitCode;

  /// Simulated standard output returned when the command runs.
  final String stdout;

  /// Simulated standard error returned when the command runs.
  final String stderr;

  /// Optional callback invoked when this command is matched and executed.
  final void Function()? onRun;
}

/// Hermetic queue-based implementation of [ExtensionProcessManager] for unit testing.
final class FakeExtensionProcessManager implements ExtensionProcessManager {
  FakeExtensionProcessManager([
    Iterable<FakeExtensionCommand> commands = const <FakeExtensionCommand>[],
  ]) {
    _commands.addAll(commands);
  }

  final _commands = Queue<FakeExtensionCommand>();

  /// Whether any queued [FakeExtensionCommand] expectations remain unconsumed.
  bool get hasRemainingCommands => _commands.isNotEmpty;

  /// Enqueues a single [FakeExtensionCommand] expectation.
  void addCommand(FakeExtensionCommand command) => _commands.add(command);

  /// Enqueues multiple [FakeExtensionCommand] expectations in order.
  void addCommands(Iterable<FakeExtensionCommand> commands) => _commands.addAll(commands);

  /// Throws a [StateError] if any queued commands were not executed.
  void assertNoRemainingCommands() {
    if (_commands.isNotEmpty) {
      final List<String> remaining = _commands
          .map((FakeExtensionCommand c) => c.command.join(' '))
          .toList();
      throw StateError('Unconsumed FakeExtensionCommand expectations remaining: $remaining');
    }
  }

  @override
  Future<ProcessResult> run(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    return runSync(command, workingDirectory: workingDirectory, environment: environment);
  }

  @override
  ProcessResult runSync(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    if (_commands.isEmpty) {
      throw StateError('Unexpected command executed: ${command.join(' ')}');
    }
    final FakeExtensionCommand expected = _commands.removeFirst();
    if (!_listEquals(expected.command, command)) {
      throw StateError(
        'Process command mismatch.\n'
        'Expected: ${expected.command}\n'
        'Actual:   $command',
      );
    }
    if (expected.workingDirectory != null && expected.workingDirectory != workingDirectory) {
      throw StateError(
        'Process workingDirectory mismatch for ${command.join(' ')}.\n'
        'Expected: ${expected.workingDirectory}\n'
        'Actual:   $workingDirectory',
      );
    }
    if (expected.environment != null) {
      if (environment == null) {
        throw StateError(
          'Expected environment ${expected.environment} for ${command.join(' ')}, got null.',
        );
      }
      for (final MapEntry(:String key, :String value) in expected.environment!.entries) {
        if (environment[key] != value) {
          throw StateError(
            'Process environment mismatch for key "$key" in ${command.join(' ')}.\n'
            'Expected: $value\n'
            'Actual:   ${environment[key]}',
          );
        }
      }
    }
    expected.onRun?.call();
    return ProcessResult(0, expected.exitCode, expected.stdout, expected.stderr);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Hermetic in-memory implementation of [ExtensionLogger] for unit testing.
final class BufferExtensionLogger implements ExtensionLogger {
  final _statusBuffer = StringBuffer();
  final _errorBuffer = StringBuffer();
  final _warningBuffer = StringBuffer();
  final _traceBuffer = StringBuffer();

  /// Accumulated status log output.
  String get statusText => _statusBuffer.toString();

  /// Accumulated error log output.
  String get errorText => _errorBuffer.toString();

  /// Accumulated warning log output.
  String get warningText => _warningBuffer.toString();

  /// Accumulated trace log output.
  String get traceText => _traceBuffer.toString();

  @override
  void printStatus(String message) => _statusBuffer.writeln(message);

  @override
  void printError(String message) => _errorBuffer.writeln(message);

  @override
  void printWarning(String message) => _warningBuffer.writeln(message);

  @override
  void printTrace(String message) => _traceBuffer.writeln(message);

  /// Clears all recorded log buffers.
  void clear() {
    _statusBuffer.clear();
    _errorBuffer.clear();
    _warningBuffer.clear();
    _traceBuffer.clear();
  }
}
