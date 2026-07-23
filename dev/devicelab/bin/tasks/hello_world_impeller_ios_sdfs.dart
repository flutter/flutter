// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

Future<TaskResult> run() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;

  final Directory appDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));
  final String plistPath = path.join(appDir.path, 'ios', 'Runner', 'Info.plist');
  final plistFile = File(plistPath);

  if (!plistFile.existsSync()) {
    return TaskResult.failure('Info.plist not found at $plistPath');
  }

  String? simulatorDeviceId;
  var res = TaskResult.success(null);

  try {
    await testWithNewIOSSimulator('TestSDFsSim', (String deviceId) async {
      simulatorDeviceId = deviceId;

      await inDirectory(appDir, () async {
        await flutter('packages', options: <String>['get']);

        // Step 1: Test without flag
        final Process process1 = await startFlutter(
          'run',
          options: <String>['--enable-impeller', '-d', deviceId],
        );

        final completer1 = Completer<void>();
        var sawMetalMessage = false;

        final StreamSubscription<String> subscription1 = process1.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              print('[STDOUT 1]: $line');
              if (line.contains('Using the Impeller rendering backend (Metal).')) {
                sawMetalMessage = true;
                if (!completer1.isCompleted) {
                  completer1.complete();
                }
              }
            });

        await Future.any(<Future<void>>[
          completer1.future,
          Future<void>.delayed(const Duration(minutes: 2)),
        ]);

        process1.stdin.writeln('q');
        await process1.exitCode;
        await subscription1.cancel();

        if (!sawMetalMessage) {
          res = TaskResult.failure(
            'Did not see "Using the Impeller rendering backend (Metal)." in output',
          );
          return; // Exit early if first step fails
        }

        // Step 2: Modify Info.plist to enable SDFS
        final String xmlStr = plistFile.readAsStringSync();
        final xmlDoc = XmlDocument.parse(xmlStr);
        final XmlElement dictNode = xmlDoc.findAllElements('dict').first;

        dictNode.children.add(
          XmlElement(XmlName('key'), <XmlAttribute>[], <XmlNode>[
            XmlText('FLTEnableSDFs'),
          ], /*isSelfClosing=*/ false),
        );
        dictNode.children.add(XmlElement(XmlName('true')));

        plistFile.writeAsStringSync(xmlDoc.toXmlString(pretty: true, indent: '    '));

        // Run again with flag
        final Process process2 = await startFlutter(
          'run',
          options: <String>['--enable-impeller', '-d', deviceId],
        );

        final completer2 = Completer<void>();
        var sawSdfsMessage = false;

        final StreamSubscription<String> subscription2 = process2.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              print('[STDOUT 2]: $line');
              if (line.contains('Using the Impeller rendering backend (MetalSDF).')) {
                sawSdfsMessage = true;
                if (!completer2.isCompleted) {
                  completer2.complete();
                }
              }
            });

        await Future.any(<Future<void>>[
          completer2.future,
          Future<void>.delayed(const Duration(minutes: 2)),
        ]);

        process2.stdin.writeln('q');
        await process2.exitCode;
        await subscription2.cancel();

        if (!sawSdfsMessage) {
          res = TaskResult.failure(
            'Did not see "Using the Impeller rendering backend (MetalSDF)." in output',
          );
        }
      });
    });
  } catch (e) {
    res = TaskResult.failure('Test failed with exception: $e');
  } finally {
    // Restore Info.plist
    if (plistFile.existsSync()) {
      await exec('git', <String>['checkout', plistPath]);
    }
    if (simulatorDeviceId != null) {
      await removeIOSSimulator(simulatorDeviceId);
    }
  }

  return res;
}

Future<void> main() async {
  await task(run);
}
