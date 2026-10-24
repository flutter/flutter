// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

/// Dependency container injected into tool extension services and build targets
/// to isolate host operating system, file system, process execution, network,
/// and logging side effects.
@immutable
final class ExtensionDependencies {
  /// Creates an [ExtensionDependencies] container with explicit dependencies.
  const ExtensionDependencies({
    required this.environment,
    required this.fileSystem,
    required this.httpClientFactory,
    required this.logger,
    required this.operatingSystem,
    required this.processManager,
  });

  /// Creates an [ExtensionDependencies] container wired to the real host
  /// operating system, file system, process manager, HTTP client, and stdout/stderr.
  factory ExtensionDependencies.bootstrap({
    Map<String, String>? environment,
    ExtensionFileSystem? fileSystem,
    HttpClient Function()? httpClientFactory,
    ExtensionLogger? logger,
    String? operatingSystem,
    ExtensionProcessManager? processManager,
  }) {
    return ExtensionDependencies(
      environment: Map<String, String>.unmodifiable(environment ?? Platform.environment),
      fileSystem: fileSystem ?? const LocalExtensionFileSystem(),
      httpClientFactory: httpClientFactory ?? HttpClient.new,
      logger: logger ?? const StdoutExtensionLogger(),
      operatingSystem: operatingSystem ?? Platform.operatingSystem,
      processManager: processManager ?? const LocalExtensionProcessManager(),
    );
  }

  /// Host environment variables visible to the extension.
  final Map<String, String> environment;

  /// File system abstraction used for reading and writing files and directories.
  final ExtensionFileSystem fileSystem;

  /// Factory used to create [HttpClient] instances for network requests.
  final HttpClient Function() httpClientFactory;

  /// Logger abstraction used to record status, warning, error, and trace output.
  final ExtensionLogger logger;

  /// Identifier of the host operating system (e.g. `'linux'`, `'macos'`, `'windows'`).
  final String operatingSystem;

  /// Process execution abstraction used to invoke external tools.
  final ExtensionProcessManager processManager;

  /// Creates a new [HttpClient] using [httpClientFactory].
  HttpClient createHttpClient() => httpClientFactory();
}

/// Abstract file system interface for tool extensions.
abstract interface class ExtensionFileSystem {
  /// Returns an [ExtensionDirectory] handle for [uri].
  ExtensionDirectory directory(Uri uri);

  /// Returns an [ExtensionFile] handle for [uri].
  ExtensionFile file(Uri uri);
}

/// Abstract directory handle for tool extensions.
abstract interface class ExtensionDirectory {
  /// The normalized `file://` URI of this directory (always ending with `/`).
  Uri get uri;

  /// The file system path of this directory.
  String get path;

  /// Whether this directory exists on the file system.
  bool existsSync();

  /// Creates this directory synchronously.
  void createSync({bool recursive = false});

  /// Deletes this directory asynchronously.
  Future<void> delete({bool recursive = false});

  /// Deletes this directory synchronously.
  void deleteSync({bool recursive = false});

  /// Returns a child [ExtensionDirectory] with relative [name].
  ExtensionDirectory childDirectory(String name);

  /// Returns a child [ExtensionFile] with relative [name].
  ExtensionFile childFile(String name);
}

/// Abstract file handle for tool extensions.
abstract interface class ExtensionFile {
  /// The `file://` URI of this file.
  Uri get uri;

  /// The file system path of this file.
  String get path;

  /// Whether this file exists on the file system.
  bool existsSync();

  /// Creates this file synchronously.
  void createSync({bool recursive = false});

  /// Deletes this file asynchronously.
  Future<void> delete({bool recursive = false});

  /// Deletes this file synchronously.
  void deleteSync({bool recursive = false});

  /// Reads the entire file contents as a UTF-8 string.
  String readAsStringSync();

  /// Writes [contents] to this file as a UTF-8 string.
  void writeAsStringSync(String contents);

  /// Reads the entire file contents as bytes.
  List<int> readAsBytesSync();

  /// Writes [bytes] to this file.
  void writeAsBytesSync(List<int> bytes);
}

/// Host `dart:io`-backed implementation of [ExtensionFileSystem].
final class LocalExtensionFileSystem implements ExtensionFileSystem {
  const LocalExtensionFileSystem();

  @override
  ExtensionDirectory directory(Uri uri) => _LocalExtensionDirectory(Directory.fromUri(uri));

  @override
  ExtensionFile file(Uri uri) => _LocalExtensionFile(File.fromUri(uri));
}

final class _LocalExtensionDirectory implements ExtensionDirectory {
  const _LocalExtensionDirectory(this._delegate);

  final Directory _delegate;

  @override
  Uri get uri => _delegate.uri;

  @override
  String get path => _delegate.path;

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  void createSync({bool recursive = false}) => _delegate.createSync(recursive: recursive);

  @override
  Future<void> delete({bool recursive = false}) async {
    await _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) => _delegate.deleteSync(recursive: recursive);

  @override
  ExtensionDirectory childDirectory(String name) =>
      _LocalExtensionDirectory(Directory.fromUri(_delegate.uri.resolve('$name/')));

  @override
  ExtensionFile childFile(String name) =>
      _LocalExtensionFile(File.fromUri(_delegate.uri.resolve(name)));
}

final class _LocalExtensionFile implements ExtensionFile {
  const _LocalExtensionFile(this._delegate);

  final File _delegate;

  @override
  Uri get uri => _delegate.uri;

  @override
  String get path => _delegate.path;

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  void createSync({bool recursive = false}) => _delegate.createSync(recursive: recursive);

  @override
  Future<void> delete({bool recursive = false}) async {
    await _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) => _delegate.deleteSync(recursive: recursive);

  @override
  String readAsStringSync() => _delegate.readAsStringSync();

  @override
  void writeAsStringSync(String contents) => _delegate.writeAsStringSync(contents);

  @override
  List<int> readAsBytesSync() => _delegate.readAsBytesSync();

  @override
  void writeAsBytesSync(List<int> bytes) => _delegate.writeAsBytesSync(bytes);
}

/// Abstract process execution interface for tool extensions.
abstract interface class ExtensionProcessManager {
  /// Runs [command] asynchronously and returns the [ProcessResult].
  Future<ProcessResult> run(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  });

  /// Runs [command] synchronously and returns the [ProcessResult].
  ProcessResult runSync(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

/// Host `dart:io` [Process]-backed implementation of [ExtensionProcessManager].
final class LocalExtensionProcessManager implements ExtensionProcessManager {
  const LocalExtensionProcessManager();

  @override
  Future<ProcessResult> run(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    if (command.isEmpty) {
      throw ArgumentError.value(command, 'command', 'Command list must not be empty.');
    }
    return Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  @override
  ProcessResult runSync(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    if (command.isEmpty) {
      throw ArgumentError.value(command, 'command', 'Command list must not be empty.');
    }
    return Process.runSync(
      command.first,
      command.sublist(1),
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }
}

/// Abstract logger interface for tool extensions.
abstract interface class ExtensionLogger {
  /// Logs a standard status message.
  void printStatus(String message);

  /// Logs an error message.
  void printError(String message);

  /// Logs a warning message.
  void printWarning(String message);

  /// Logs a verbose trace message.
  void printTrace(String message);
}

/// Host `stdout`/`stderr`-backed implementation of [ExtensionLogger].
final class StdoutExtensionLogger implements ExtensionLogger {
  const StdoutExtensionLogger();

  @override
  void printStatus(String message) => stdout.writeln(message);

  @override
  void printError(String message) => stderr.writeln(message);

  @override
  void printWarning(String message) => stderr.writeln(message);

  @override
  void printTrace(String message) => stdout.writeln(message);
}
