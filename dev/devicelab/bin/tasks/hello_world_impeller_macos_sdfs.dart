// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

Future<void> _runDefaultTest() async {
  // Test running by default. Since macOS always uses SDF rendering when Impeller is enabled,
  // we should see "Using the Impeller rendering backend (MetalSDF)." in the output by default.
  final Process process = await startFlutter('run', options: <String>['-d', 'macos']);

  final completer = Completer<void>();
  var sawMetalSdfsMessage = false;

  final StreamSubscription<String> subscription = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('[STDOUT]: $line');
        if (line.contains('Using the Impeller rendering backend (MetalSDF).')) {
          sawMetalSdfsMessage = true;
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });

  await Future.any(<Future<void>>[
    completer.future,
    Future<void>.delayed(const Duration(minutes: 2)),
  ]);

  process.stdin.writeln('q');
  await process.exitCode;
  await subscription.cancel();

  if (!sawMetalSdfsMessage) {
    throw StateError('Did not see "Using the Impeller rendering backend (MetalSDF)." in output');
  }
}

Future<void> _runNoEnableImpellerTest() async {
  // Test running with --no-enable-impeller. Since macOS uses Skia when Impeller is disabled,
  // we should see "Using the Skia rendering backend (Metal)." in the output.
  final Process process = await startFlutter(
    'run',
    options: <String>['--no-enable-impeller', '-d', 'macos'],
  );

  final completer = Completer<void>();
  var sawSkiaMessage = false;

  final StreamSubscription<String> subscription = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('[STDOUT 2]: $line');
        if (line.contains('Using the Skia rendering backend (Metal).')) {
          sawSkiaMessage = true;
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });

  await Future.any(<Future<void>>[
    completer.future,
    Future<void>.delayed(const Duration(minutes: 2)),
  ]);

  process.stdin.writeln('q');
  await process.exitCode;
  await subscription.cancel();

  if (!sawSkiaMessage) {
    throw StateError(
      'Did not see "Using the Skia rendering backend (Metal)." in output when --no-enable-impeller was passed',
    );
  }
}

Future<void> _runPlistDisabledTest(Directory appDir) async {
  final String plistPath = path.join(appDir.path, 'macos', 'Runner', 'Info.plist');
  final plistFile = File(plistPath);

  if (!plistFile.existsSync()) {
    throw StateError('Info.plist not found at $plistPath');
  }

  try {
    // Modify Info.plist to set FLTEnableImpeller to false
    final String xmlStr = plistFile.readAsStringSync();
    final xmlDoc = XmlDocument.parse(xmlStr);
    final XmlElement dictNode = xmlDoc.findAllElements('dict').first;

    dictNode.children.add(
      XmlElement(XmlName('key'), <XmlAttribute>[], <XmlNode>[
        XmlText('FLTEnableImpeller'),
      ], /*isSelfClosing=*/ false),
    );
    dictNode.children.add(XmlElement(XmlName('false')));

    plistFile.writeAsStringSync(xmlDoc.toXmlString(pretty: true, indent: '    '));

    // Test running with FLTEnableImpeller set to false in Info.plist.
    // Since macOS should respect the Info.plist setting and disable Impeller,
    // we should see "Using the Skia rendering backend (Metal)." in the output by default.
    final Process process = await startFlutter('run', options: <String>['-d', 'macos']);

    final completer = Completer<void>();
    var sawSkiaMessage = false;

    final StreamSubscription<String> subscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          print('[STDOUT 3]: $line');
          if (line.contains('Using the Skia rendering backend (Metal).')) {
            sawSkiaMessage = true;
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });

    await Future.any(<Future<void>>[
      completer.future,
      Future<void>.delayed(const Duration(minutes: 2)),
    ]);

    process.stdin.writeln('q');
    await process.exitCode;
    await subscription.cancel();

    if (!sawSkiaMessage) {
      throw StateError(
        'Did not see "Using the Skia rendering backend (Metal)." in output when FLTEnableImpeller was set to false in Info.plist',
      );
    }
  } finally {
    // Restore Info.plist
    if (plistFile.existsSync()) {
      await exec('git', <String>['checkout', plistPath]);
    }
  }
}

Future<TaskResult> run() async {
  deviceOperatingSystem = DeviceOperatingSystem.macos;

  final Directory appDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));

  try {
    await inDirectory(appDir, () async {
      await flutter('packages', options: <String>['get']);
      await _runDefaultTest();
      await _runNoEnableImpellerTest();
      await _runPlistDisabledTest(appDir);
    });
    return TaskResult.success(null);
  } catch (e) {
    return TaskResult.failure('Test failed with exception: $e');
  }
}

Future<void> main() async {
  await task(run);
}
