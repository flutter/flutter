// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';
import 'package:path/path.dart' as path;
import 'package:standard_message_codec/standard_message_codec.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.linux;
  await task(() async {
    await createFlavorsTest().call();
    await createIntegrationTestFlavorsTest().call();

    final projectDir = '${flutterDirectory.path}/dev/integration_tests/flavors';
    final arch = Abi.current() == Abi.linuxArm64 ? 'arm64' : 'x64';
    return inDirectory(projectDir, () async {
      await flutter('build', options: <String>['linux', '--debug', '--flavor', 'paid']);

      final Uint8List assetManifestFileData = File(
        path.join(
          projectDir,
          'build',
          'linux',
          arch,
          'paid',
          'debug',
          'bundle',
          'data',
          'flutter_assets',
          'AssetManifest.bin',
        ),
      ).readAsBytesSync();

      final assetManifest =
          const StandardMessageCodec().decodeMessage(ByteData.sublistView(assetManifestFileData))
              as Map<Object?, Object?>;

      if (assetManifest.containsKey('assets/free/free.txt')) {
        return TaskResult.failure(
          'Expected the asset "assets/free/free.txt", which '
          'was declared with a flavor of "free" to not be included in the asset '
          'bundle because the --flavor was set to "paid".',
        );
      }

      if (!assetManifest.containsKey('assets/paid/paid.txt')) {
        return TaskResult.failure(
          'Expected the asset "assets/paid/paid.txt", which '
          'was declared with a flavor of "paid" to be included in the asset '
          'bundle because the --flavor was set to "paid".',
        );
      }

      return TaskResult.success(null);
    });
  });
}
