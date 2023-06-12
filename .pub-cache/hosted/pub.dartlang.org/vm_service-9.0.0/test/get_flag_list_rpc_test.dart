// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

Future getFlagValue(VmService service, String flagName) async {
  final result = await service.getFlagList();
  final flags = result.flags!;
  for (final flag in flags) {
    if (flag.name == flagName) {
      return flag.valueAsString;
    }
  }
}

var tests = <VMTest>[
  // Modify a flag which does not exist.
  (VmService service) async {
    final Error result =
        (await service.setFlag('does_not_exist', 'true')) as Error;
    expect(result.message, 'Cannot set flag: flag not found');
  },

  // Modify a flag with the wrong value type.
  (VmService service) async {
    final Error result = (await service.setFlag(
        'pause_isolates_on_start', 'not-boolean')) as Error;
    expect(result.message, equals('Cannot set flag: invalid value'));
  },

  // Modify a flag with the right value type.
  (VmService service) async {
    final result = await service.setFlag('pause_isolates_on_start', 'false');
    expect(result, TypeMatcher<Success>());
  },

  // Modify a flag which cannot be set at runtime.
  (VmService service) async {
    final Error result = (await service.setFlag('random_seed', '42')) as Error;
    expect(result.message, 'Cannot set flag: cannot change at runtime');
  },

  // Modify the profile_period at runtime.
  (VmService service) async {
    final kProfilePeriod = 'profile_period';
    final kValue = 100;
    expect(await getFlagValue(service, kProfilePeriod), '1000');
    final completer = Completer();
    final stream = await service.onVMEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      print(event);
      if (event.kind == EventKind.kVMFlagUpdate) {
        expect(event.flag, kProfilePeriod);
        expect(event.newValue, kValue.toString());
        subscription.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kVM);
    final result = await service.setFlag(kProfilePeriod, kValue.toString());
    expect(result, TypeMatcher<Success>());
    await completer.future;
    expect(await getFlagValue(service, kProfilePeriod), kValue.toString());
    await service.streamCancel(EventStreams.kVM);
  }
];

main([args = const <String>[]]) async => runVMTests(
      args,
      tests,
      'get_flag_list_rpc_test.dart',
    );
