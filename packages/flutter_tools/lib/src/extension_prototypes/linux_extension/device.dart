// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';

import '../../../flutter_tools_extension.dart';

/// Prototype implementation of Device to represent the Linux desktop target.
class LinuxDevice extends Device {
  LinuxDevice({
    required this.category,
    required this.fileSystem,
    required this.id,
    required this.name,
    required this.processManager,
  });

  final FileSystem fileSystem;
  final ProcessManager processManager;

  @override
  final String id;

  @override
  final String name;

  @override
  final String category;

  @override
  String get platform => 'linux-x64';

  @override
  String get buildTarget => 'assemble_linux_app';

  @override
  bool get isEmulator => false;

  final StreamController<String> _logController = StreamController<String>.broadcast();
  final Completer<Uri> _vmServiceUriCompleter = Completer<Uri>();
  Process? _process;

  @override
  Future<void> installApp(Uri appBundlePath) async {
    _logController.add('Installing app bundle ${appBundlePath.toFilePath()}...');
  }

  @override
  Future<void> launchApp(Uri appBundlePath, List<String> args) async {
    final String filePath = appBundlePath.toFilePath();

    _logController.add('Launching app bundle $filePath with args: $args...');

    try {
      final Process process = await processManager.start(<String>[filePath, ...args]);
      _process = process;

      unawaited(
        process.exitCode.then((int exitCode) {
          if (!_vmServiceUriCompleter.isCompleted) {
            _vmServiceUriCompleter.completeError(
              StateError(
                'The process exited early with exit code $exitCode before VM Service URI was printed.',
              ),
            );
          }
        }),
      );

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
        _logController.add(line);
        final vmServiceRegExp = RegExp(
          r'The Dart VM service is listening on (http://127.0.0.1:\d+/[^/]+/)',
        );
        final Match? match = vmServiceRegExp.firstMatch(line);
        if (match != null) {
          if (!_vmServiceUriCompleter.isCompleted) {
            _vmServiceUriCompleter.complete(Uri.parse(match.group(1)!));
          }
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
        _logController.add('ERROR: $line');
      });
    } on Object catch (e) {
      _logController.add('Failed to launch application process: $e');
      _vmServiceUriCompleter.completeError(e);
    }
  }

  @override
  Stream<String> getLogReader() => _logController.stream;

  @override
  Future<Uri> getVmServiceUri() async {
    return _vmServiceUriCompleter.future;
  }

  @override
  Future<void> stopApp() async {
    _logController.add('Stopping application...');
    _process?.kill();
    _process = null;
  }
}

/// Prototype implementation of a DeviceService for Linux support.
final class LinuxDeviceService extends DeviceService {
  LinuxDeviceService({
    required super.onNotification,
    this.fileSystem = const LocalFileSystem(),
    this.processManager = const LocalProcessManager(),
  });

  final FileSystem fileSystem;
  final ProcessManager processManager;

  @override
  Future<List<Device>> discoverDevices() async {
    return <Device>[
      LinuxDevice(
        id: 'linux-proto-1',
        name: 'Linux Desktop Target',
        category: 'desktop',
        fileSystem: fileSystem,
        processManager: processManager,
      ),
    ];
  }

  @override
  Future<void> launchEmulator(String emulatorId) async {}

  @override
  Future<void> shutdown() async {
    await super.shutdown();
  }
}
