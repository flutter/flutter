// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/src/utils/mutex.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'get_cached_cpu_samples_script.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test(
    'No UserTags to cache',
    () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);
      final service = await vmServiceConnectUri(dds.wsUri.toString());

      // We didn't provide `cachedUserTags` when starting DDS, so we shouldn't
      // be caching anything.
      final availableCaches = await service.getAvailableCachedCpuSamples();
      expect(availableCaches.cacheNames.length, 0);

      IsolateRef isolate;
      while (true) {
        final vm = await service.getVM();
        if (vm.isolates!.isNotEmpty) {
          isolate = vm.isolates!.first;
          break;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
      try {
        await service.getCachedCpuSamples(isolate.id!, 'Fake');
        fail('Invalid userTag did not cause an exception');
      } on RPCError catch (e) {
        expect(
          e.message,
          'CPU sample caching is not enabled for tag: "Fake"',
        );
      }
    },
    timeout: Timeout.none,
  );

  test(
    'Cache CPU samples for provided UserTag name',
    () async {
      const kUserTag = 'Testing';
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
        cachedUserTags: [kUserTag],
      );
      expect(dds.isRunning, true);
      final service = await vmServiceConnectUri(dds.wsUri.toString());
      final otherService = await vmServiceConnectUri(dds.wsUri.toString());

      // Ensure we're caching results for samples under the 'Testing' UserTag.
      final availableCaches = await service.getAvailableCachedCpuSamples();
      expect(availableCaches.cacheNames.length, 1);
      expect(availableCaches.cacheNames.first, kUserTag);

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

      final completer = Completer<void>();
      int i = 0;
      int count = 0;
      final mutex = Mutex();

      late StreamSubscription sub;
      sub = service.onProfilerEvent.listen(
        (event) async {
          // Process one event at a time to prevent racey updates to count.
          await mutex.runGuarded(
            () async {
              if (event.kind == EventKind.kCpuSamples &&
                  event.isolate!.id! == isolate.id!) {
                ++i;
                if (i > 3) {
                  if (!completer.isCompleted) {
                    await sub.cancel();
                    completer.complete();
                  }
                  return;
                }
                // Ensure the number of CPU samples in the CpuSample event is
                // is consistent with the number of samples in the cache.
                expect(event.cpuSamples, isNotNull);
                final sampleCount = event.cpuSamples!.samples!
                    .where((e) => e.userTag == kUserTag)
                    .length;
                expect(sampleCount, event.cpuSamples!.samples!.length);
                count += sampleCount;
                final cache = await service.getCachedCpuSamples(
                  isolate.id!,
                  availableCaches.cacheNames.first,
                );
                // DDS may have processed more sample blocks than we've had a chance
                // to, so just ensure we have at least as many samples in the cache
                // as we've seen.
                expect(cache.sampleCount! >= count, true);
              }
            },
          );
        },
      );
      await service.streamListen(EventStreams.kProfiler);
      await service.streamCpuSamplesWithUserTag(['Testing']);
      // Have another client register for samples from another UserTag. The
      // main client should not see any samples with the 'Baz' tag.
      await otherService.streamListen(EventStreams.kProfiler);
      await otherService.streamCpuSamplesWithUserTag(['Testing', 'Baz']);
      await service.resume(isolate.id!);
      await completer.future;
    },
    timeout: Timeout.none,
  );
}
