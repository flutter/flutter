// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show HashMap;
import 'dart:convert' show base64Decode;
import 'dart:developer' as developer;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vms;
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service_protos/vm_service_protos.dart';

void main() {
  test('microtask profiling is enabled by the --profile-microtasks CLI '
      'flag', () async {
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();

    if (info.serverUri == null) {
      fail('This test must not be run with --disable-vm-service.');
    }

    final vms.VmService vmService = await vmServiceConnectUri(
      'ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws',
    );
    await vmService.clearVMTimeline();

    final vms.PerfettoTimeline response = await vmService.getPerfettoVMTimeline();
    final List<TracePacket> packets = Trace.fromBuffer(base64Decode(response.trace!)).packet;
    final Iterable<TrackEvent> microtaskEvents = packets
        .where((TracePacket packet) => packet.hasTrackEvent())
        .map((TracePacket packet) => packet.trackEvent)
        .where(
          (TrackEvent event) =>
              event.type == TrackEvent_Type.TYPE_SLICE_BEGIN && event.name == 'Microtask',
        );

    expect(microtaskEvents.length, isPositive);

    for (final event in microtaskEvents) {
      final Map<String, String> debugAnnotations = HashMap.fromEntries(
        event.debugAnnotations.map((a) => MapEntry(a.name, a.stringValue)),
      );

      expect(debugAnnotations['microtaskId'], isNotNull);
      expect(debugAnnotations['stack trace captured when microtask was enqueued'], isNotNull);
    }

    await vmService.dispose();
  });
}
