// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' as developer;
import 'dart:isolate' as isolate;

import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

export 'package:vm_service/vm_service.dart' show TimelineEvent;

late String isolateId;

late VmService _vmService;

void initTimelineTests() {
  setUpAll(() async {
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
    if (info.serverUri == null) {
      fail('This test _must_ be run with --enable-vmservice.');
    }
    _vmService = await vmServiceConnectUri('ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws');
    await _vmService.setVMTimelineFlags(<String>['Dart']);
    isolateId = developer.Service.getIsolateID(isolate.Isolate.current)!;
  });
}

Future<List<TimelineEvent>> fetchTimelineEvents() async {
  final Timeline timeline = await _vmService.getVMTimeline();
  await _vmService.clearVMTimeline();
  return timeline.traceEvents!;
}
