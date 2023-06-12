// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  late Process process;
  DartDevelopmentService? dds;

  setUp(() async {
    process = await spawnDartProcess(
      'get_cached_cpu_samples_script.dart',
      disableServiceAuthCodes: true,
    );
  });

  tearDown(() async {
    await dds?.shutdown();
    process.kill();
  });

  test(
    'DDS returns local paths with a converter',
    () async {
      Uri serviceUri = remoteVmServiceUri;
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
        uriConverter: (uri) => uri == 'package:test/has_local.dart'
            ? 'file:///has_local.dart'
            : null,
      );
      serviceUri = dds!.wsUri!;
      expect(dds!.isRunning, true);
      final service = await vmServiceConnectUri(serviceUri.toString());

      IsolateRef isolate;
      while (true) {
        final vm = await service.getVM();
        if (vm.isolates!.isNotEmpty) {
          isolate = vm.isolates!.first;
          try {
            isolate = await service.getIsolate(isolate.id!);
            if ((isolate as Isolate).runnable!) {
              break;
            }
          } on SentinelException {
            // ignore
          }
        }
        await Future.delayed(const Duration(seconds: 1));
      }
      expect(isolate, isNotNull);

      final unresolvedUris = <String>[
        'dart:io', // dart:io -> org-dartlang-sdk:///sdk/lib/io/io.dart
        'package:test/has_local.dart', // package:test/test.dart -> file:///has_local.dart
        'package:does_not_exist/does_not_exist.dart', // invalid URI -> null
      ];
      var result = await service
          .lookupResolvedPackageUris(isolate.id!, unresolvedUris, local: true);

      expect(result.uris?[0], 'org-dartlang-sdk:///sdk/lib/io/io.dart');
      expect(result.uris?[1], 'file:///has_local.dart');
      expect(result.uris?[2], null);
    },
    timeout: Timeout.none,
  );
}
