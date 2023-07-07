// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/dds.dart';
import 'package:vm_service/vm_service_io.dart';

import '../test/common/test_helper.dart';

Future<void> main() async {
  final process = await spawnDartProcess('../test/smoke.dart');
  final dds = await DartDevelopmentService.startDartDevelopmentService(
    remoteVmServiceUri,
  );

  // Connect to the DDS instance and make a request using package:vm_service.
  final service = await vmServiceConnectUri(dds.wsUri.toString());
  final version = await service.getVersion();

  print('Service Version: $version');

  await dds.shutdown();
  process.kill();
}
