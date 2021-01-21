// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

/// The current host machine running the tests.
HostAgent get hostAgent => HostAgent(platform: const LocalPlatform(), fileSystem: const LocalFileSystem());

/// Host machine running the tests.
abstract class HostAgent {
  factory HostAgent({@required Platform platform, @required FileSystem fileSystem}) {
    if (platform.isWindows) {
      return _WindowsHostAgent(platform: platform, fileSystem: fileSystem);
    } else if (platform.isMacOS) {
      return _MacOSHostAgent(platform: platform, fileSystem: fileSystem);
    } else {
      return _PosixHostAgent(platform: platform, fileSystem: fileSystem);
    }
  }

  HostAgent._({@required Platform platform, @required FileSystem fileSystem})
      : _platform = platform,
        _fileSystem = fileSystem;

  final Platform _platform;
  final FileSystem _fileSystem;

  /// Creates a directory to dump file artifacts.
  Directory get dumpDirectory {
    if (_dumpDirectory == null) {
      // Set in LUCI recipe.
      final String directoryPath = _platform.environment['FLUTTER_LOGS_DIR'];
      if (directoryPath == null) {
        _dumpDirectory = _fileSystem.systemTempDirectory.createTempSync('flutter_test_logs.');
        print('Created tmp dump directory ${_dumpDirectory.path}');
      } else {
        _dumpDirectory = _fileSystem.directory(directoryPath)..createSync(recursive: true);
        print('Found FLUTTER_LOGS_DIR dump directory ${_dumpDirectory.path}');
      }
    }
    return _dumpDirectory;
  }

  static Directory _dumpDirectory;

  @visibleForTesting
  void resetDumpDirectory() {
    _dumpDirectory = null;
  }

  Future<bool> dump();
}

class _WindowsHostAgent extends HostAgent {
  _WindowsHostAgent({@required Platform platform, @required FileSystem fileSystem})
      : super._(platform: platform, fileSystem: fileSystem);

  @override
  Future<bool> dump() async => true;
}

class _MacOSHostAgent extends HostAgent {
  _MacOSHostAgent({@required Platform platform, @required FileSystem fileSystem})
      : super._(platform: platform, fileSystem: fileSystem);

  @override
  Future<bool> dump() async {
    // Copy simulator logs and crash reports.
    final String home = _platform.environment['HOME'];
    if (home == null) {
      print(r'$HOME not found, skipping simulator log dump.');
      return false;
    }

    final Directory simulatorLogs = _fileSystem.directory(_fileSystem.path.join(home, 'Library', 'Logs', 'CoreSimulator'));
    if (simulatorLogs.existsSync()) {
      final Directory simulatorsDumpDestination = dumpDirectory.childDirectory('ios-simulators');

      // Directory names are simulator UDIDs.
      // ~/Library/Logs/CoreSimulator/06841A41-188A-4F33-B7A6-CDEBFC8D6DE8
      for (final Directory simulatorDirectory in simulatorLogs.listSync().whereType<Directory>()) {
        final List<File> filesToCopy = <File>[];

        // ~/Library/Logs/CoreSimulator/06841A41-188A-4F33-B7A6-CDEBFC8D6DE8/CrashReporter/DiagnosticLogs
        final Directory simDiagnosticLogs = simulatorDirectory
            .childDirectory('CrashReporter')
            .childDirectory('DiagnosticLogs');
        if (simDiagnosticLogs.existsSync()) {
          filesToCopy.addAll(simDiagnosticLogs.listSync().whereType<File>());
        }

        // ~/Library/Logs/CoreSimulator/06841A41-188A-4F33-B7A6-CDEBFC8D6DE8/system.log.0.gz
        filesToCopy.addAll(simulatorDirectory
            .listSync()
            .whereType<File>()
            .where((File simulatorContent) =>
                simulatorContent.basename.startsWith('system.log')));

        if (filesToCopy.isEmpty) {
          continue;
        }
        final Directory simulatorDumpDestination = simulatorsDumpDestination
            .childDirectory(simulatorDirectory.basename);
        if (simulatorDumpDestination.existsSync()) {
          simulatorDumpDestination.deleteSync();
        }
        simulatorDumpDestination.createSync(recursive: true);
        for (final File file in filesToCopy) {
          file.copySync(simulatorDumpDestination.childFile(file.basename).path);
        }
      }
    }
    return true;
  }
}

class _PosixHostAgent extends HostAgent {
  _PosixHostAgent({@required Platform platform, @required FileSystem fileSystem})
      : super._(platform: platform, fileSystem: fileSystem);

  @override
  Future<bool> dump() async => true;
}
