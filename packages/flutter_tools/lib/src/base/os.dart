// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive.dart';

import '../globals.dart';
import 'context.dart';
import 'file_system.dart';
import 'io.dart';
import 'platform.dart';
import 'process.dart';
import 'process_manager.dart';

/// Returns [OperatingSystemUtils] active in the current app context (i.e. zone).
OperatingSystemUtils get os => context.get<OperatingSystemUtils>();

abstract class OperatingSystemUtils {
  factory OperatingSystemUtils() {
    if (platform.isWindows) {
      return _WindowsUtils();
    } else {
      return _PosixUtils();
    }
  }

  OperatingSystemUtils._private();

  /// Make the given file executable. This may be a no-op on some platforms.
  void makeExecutable(File file);

  /// Updates the specified file system [entity] to have the file mode
  /// bits set to the value defined by [mode], which can be specified in octal
  /// (e.g. `644`) or symbolically (e.g. `u+x`).
  ///
  /// On operating systems that do not support file mode bits, this will be a
  /// no-op.
  void chmod(FileSystemEntity entity, String mode);

  /// Return the path (with symlinks resolved) to the given executable, or null
  /// if `which` was not able to locate the binary.
  File which(String execName) {
    final List<File> result = _which(execName);
    if (result == null || result.isEmpty)
      return null;
    return result.first;
  }

  /// Return a list of all paths to `execName` found on the system. Uses the
  /// PATH environment variable.
  List<File> whichAll(String execName) => _which(execName, all: true);

  /// Return the File representing a new pipe.
  File makePipe(String path);

  void zip(Directory data, File zipFile);

  void unzip(File file, Directory targetDirectory);

  /// Returns true if the ZIP is not corrupt.
  bool verifyZip(File file);

  void unpack(File gzippedTarFile, Directory targetDirectory);

  /// Returns true if the gzip is not corrupt (does not check tar).
  bool verifyGzip(File gzippedFile);

  /// Returns a pretty name string for the current operating system.
  ///
  /// If available, the detailed version of the OS is included.
  String get name {
    const Map<String, String> osNames = <String, String>{
      'macos': 'Mac OS',
      'linux': 'Linux',
      'windows': 'Windows',
    };
    final String osName = platform.operatingSystem;
    return osNames.containsKey(osName) ? osNames[osName] : osName;
  }

  List<File> _which(String execName, { bool all = false });

  /// Returns the separator between items in the PATH environment variable.
  String get pathVarSeparator;

  /// Returns an unused network port.
  ///
  /// Returns 0 if an unused port cannot be found.
  ///
  /// The port returned by this function may become used before it is bound by
  /// its intended user.
  Future<int> findFreePort({bool ipv6 = false}) async {
    int port = 0;
    ServerSocket serverSocket;
    final InternetAddress loopback =
        ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4;
    try {
      serverSocket = await ServerSocket.bind(loopback, 0);
      port = serverSocket.port;
    } on SocketException catch (e) {
      // If ipv4 loopback bind fails, try ipv6.
      if (!ipv6) {
        return findFreePort(ipv6: true);
      }
      printTrace('findFreePort failed: $e');
    } catch (e) {
      // Failures are signaled by a return value of 0 from this function.
      printTrace('findFreePort failed: $e');
    } finally {
      if (serverSocket != null) {
        await serverSocket.close();
      }
    }
    return port;
  }
}

class _PosixUtils extends OperatingSystemUtils {
  _PosixUtils() : super._private();

  @override
  void makeExecutable(File file) {
    chmod(file, 'a+x');
  }

  @override
  void chmod(FileSystemEntity entity, String mode) {
    try {
      final ProcessResult result = processManager.runSync(<String>['chmod', mode, entity.path]);
      if (result.exitCode != 0) {
        printTrace(
          'Error trying to run chmod on ${entity.absolute.path}'
          '\nstdout: ${result.stdout}'
          '\nstderr: ${result.stderr}',
        );
      }
    } on ProcessException catch (error) {
      printTrace('Error trying to run chmod on ${entity.absolute.path}: $error');
    }
  }

  @override
  List<File> _which(String execName, { bool all = false }) {
    final List<String> command = <String>['which'];
    if (all)
      command.add('-a');
    command.add(execName);
    final ProcessResult result = processManager.runSync(command);
    if (result.exitCode != 0)
      return const <File>[];
    final String stdout = result.stdout;
    return stdout.trim().split('\n').map<File>((String path) => fs.file(path.trim())).toList();
  }

  @override
  void zip(Directory data, File zipFile) {
    processUtils.runSync(
      <String>['zip', '-r', '-q', zipFile.path, '.'],
      workingDirectory: data.path,
      throwOnError: true,
    );
  }

  // unzip -o -q zipfile -d dest
  @override
  void unzip(File file, Directory targetDirectory) {
    processUtils.runSync(
      <String>['unzip', '-o', '-q', file.path, '-d', targetDirectory.path],
      throwOnError: true,
    );
  }

  @override
  bool verifyZip(File zipFile) =>
      processUtils.exitsHappySync(<String>['zip', '-T', zipFile.path]);

  // tar -xzf tarball -C dest
  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {
    processUtils.runSync(
      <String>['tar', '-xzf', gzippedTarFile.path, '-C', targetDirectory.path],
      throwOnError: true,
    );
  }

  @override
  bool verifyGzip(File gzippedFile) =>
      processUtils.exitsHappySync(<String>['gzip', '-t', gzippedFile.path]);

  @override
  File makePipe(String path) {
    processUtils.runSync(
      <String>['mkfifo', path],
      throwOnError: true,
    );
    return fs.file(path);
  }

  String _name;

  @override
  String get name {
    if (_name == null) {
      if (platform.isMacOS) {
        final List<RunResult> results = <RunResult>[
          processUtils.runSync(<String>['sw_vers', '-productName']),
          processUtils.runSync(<String>['sw_vers', '-productVersion']),
          processUtils.runSync(<String>['sw_vers', '-buildVersion']),
        ];
        if (results.every((RunResult result) => result.exitCode == 0)) {
          _name = '${results[0].stdout.trim()} ${results[1].stdout
              .trim()} ${results[2].stdout.trim()}';
        }
      }
      _name ??= super.name;
    }
    return _name;
  }

  @override
  String get pathVarSeparator => ':';
}

class _WindowsUtils extends OperatingSystemUtils {
  _WindowsUtils() : super._private();

  @override
  void makeExecutable(File file) {}

  @override
  void chmod(FileSystemEntity entity, String mode) {}

  @override
  List<File> _which(String execName, { bool all = false }) {
    // `where` always returns all matches, not just the first one.
    final ProcessResult result = processManager.runSync(<String>['where', execName]);
    if (result.exitCode != 0)
      return const <File>[];
    final List<String> lines = result.stdout.trim().split('\n');
    if (all)
      return lines.map<File>((String path) => fs.file(path.trim())).toList();
    return <File>[fs.file(lines.first.trim())];
  }

  @override
  void zip(Directory data, File zipFile) {
    final Archive archive = Archive();
    for (FileSystemEntity entity in data.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final File file = entity;
      final String path = file.fileSystem.path.relative(file.path, from: data.path);
      final List<int> bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    zipFile.writeAsBytesSync(ZipEncoder().encode(archive), flush: true);
  }

  @override
  void unzip(File file, Directory targetDirectory) {
    final Archive archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    _unpackArchive(archive, targetDirectory);
  }

  @override
  bool verifyZip(File zipFile) {
    try {
      ZipDecoder().decodeBytes(zipFile.readAsBytesSync(), verify: true);
    } on FileSystemException catch (_) {
      return false;
    } on ArchiveException catch (_) {
      return false;
    }
    return true;
  }

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {
    final Archive archive = TarDecoder().decodeBytes(
      GZipDecoder().decodeBytes(gzippedTarFile.readAsBytesSync()),
    );
    _unpackArchive(archive, targetDirectory);
  }

  @override
  bool verifyGzip(File gzipFile) {
    try {
      GZipDecoder().decodeBytes(gzipFile.readAsBytesSync(), verify: true);
    } on FileSystemException catch (_) {
      return false;
    } on ArchiveException catch (_) {
      return false;
    }
    return true;
  }

  void _unpackArchive(Archive archive, Directory targetDirectory) {
    for (ArchiveFile archiveFile in archive.files) {
      // The archive package doesn't correctly set isFile.
      if (!archiveFile.isFile || archiveFile.name.endsWith('/'))
        continue;

      final File destFile = fs.file(fs.path.join(targetDirectory.path, archiveFile.name));
      if (!destFile.parent.existsSync())
        destFile.parent.createSync(recursive: true);
      destFile.writeAsBytesSync(archiveFile.content);
    }
  }

  @override
  File makePipe(String path) {
    throw UnsupportedError('makePipe is not implemented on Windows.');
  }

  String _name;

  @override
  String get name {
    if (_name == null) {
      final ProcessResult result = processManager.runSync(
          <String>['ver'], runInShell: true);
      if (result.exitCode == 0)
        _name = result.stdout.trim();
      else
        _name = super.name;
    }
    return _name;
  }

  @override
  String get pathVarSeparator => ';';
}

/// Find and return the project root directory relative to the specified
/// directory or the current working directory if none specified.
/// Return null if the project root could not be found
/// or if the project root is the flutter repository root.
String findProjectRoot([ String directory ]) {
  const String kProjectRootSentinel = 'pubspec.yaml';
  directory ??= fs.currentDirectory.path;
  while (true) {
    if (fs.isFileSync(fs.path.join(directory, kProjectRootSentinel)))
      return directory;
    final String parent = fs.path.dirname(directory);
    if (directory == parent)
      return null;
    directory = parent;
  }
}
