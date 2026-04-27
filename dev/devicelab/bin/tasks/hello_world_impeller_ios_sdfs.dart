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

      // Modify Info.plist to enable SDFS
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

      await inDirectory(appDir, () async {
        await flutter('packages', options: <String>['get']);

        final Process process = await startFlutter(
          'run',
          options: <String>['--enable-impeller', '-d', deviceId],
        );

        final completer = Completer<void>();
        var sawSdfsMessage = false;

        final StreamSubscription<String> subscription = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              print('[STDOUT]: $line');
              if (line.contains('Using the Impeller rendering backend (MetalSDF).')) {
                sawSdfsMessage = true;
                if (!completer.isCompleted) {
                  completer.complete();
                }
              }
            });

        // Wait for the message or timeout
        await Future.any(<Future<void>>[
          completer.future,
          Future<void>.delayed(const Duration(minutes: 2)),
        ]);

        // Stop the app
        process.stdin.writeln('q');
        await process.exitCode;
        await subscription.cancel();

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
