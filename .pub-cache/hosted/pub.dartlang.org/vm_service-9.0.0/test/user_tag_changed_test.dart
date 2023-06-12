// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testMain() {
  final tag = UserTag('Foo');
  final origTag = tag.makeCurrent();
  origTag.makeCurrent();
}

late StreamQueue<Event> stream;

var tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolate) async {
    await service.streamListen(EventStreams.kProfiler);
    stream = StreamQueue(
      service.onProfilerEvent.transform(
        SingleSubscriptionTransformer<Event, Event>(),
      ),
    );
  },
  resumeIsolate,
  hasStoppedAtExit,
  (VmService service, IsolateRef isolate) async {
    await service.streamCancel(EventStreams.kProfiler);
    expect(await stream.hasNext, true);

    var event = await stream.next;
    expect(event.kind, EventKind.kUserTagChanged);
    expect(event.isolate, isNotNull);
    expect(event.updatedTag, 'Foo');
    expect(event.previousTag, 'Default');

    expect(await stream.hasNext, true);
    event = await stream.next;
    expect(event.kind, EventKind.kUserTagChanged);
    expect(event.isolate, isNotNull);
    expect(event.updatedTag, 'Default');
    expect(event.previousTag, 'Foo');
  },
  resumeIsolate,
  (VmService service, IsolateRef isolate) async {
    expect(await stream.hasNext, false);
  }
];

main([args = const <String>[]]) async => await runIsolateTests(
      args,
      tests,
      'user_tag_changed_test.dart',
      pause_on_start: true,
      pause_on_exit: true,
      testeeConcurrent: testMain,
    );
