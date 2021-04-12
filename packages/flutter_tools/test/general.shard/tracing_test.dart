// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/tracing.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/fake_vm_services.dart';

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[
    vm_service.LibraryRef(
      id: '1',
      uri: 'file:///hello_world/main.dart',
      name: '',
    ),
  ],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
);

final FlutterView fakeFlutterView = FlutterView(
  id: 'a',
  uiIsolate: fakeUnpausedIsolate,
);

final FakeVmServiceRequest listViews = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[
      fakeFlutterView.toJson(),
    ],
  },
);

final List<FakeVmServiceRequest> vmServiceSetup = <FakeVmServiceRequest>[
  const FakeVmServiceRequest(
    method: 'streamListen',
    args: <String, Object>{
      'streamId': vm_service.EventKind.kExtension,
    }
  ),
  listViews,
  // Satisfies didAwaitFirstFrame
  const FakeVmServiceRequest(
    method: 'ext.flutter.didSendFirstFrameRasterizedEvent',
    args: <String, Object>{
      'isolateId': '1',
    },
    jsonResponse: <String, Object>{
      'enabled': 'true'
    },
  ),
];

void main() {
  testWithoutContext('Can trace application startup', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <FakeVmServiceRequest>[
      ...vmServiceSetup,
      FakeVmServiceRequest(
        method: 'getVMTimeline',
        jsonResponse: vm_service.Timeline(
          timeExtentMicros: 4,
          timeOriginMicros: 0,
          traceEvents: <vm_service.TimelineEvent>[
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFlutterEngineMainEnterEventName,
              'ts': 0,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFrameworkInitEventName,
              'ts': 1,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFirstFrameBuiltEventName,
              'ts': 2,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFirstFrameRasterizedEventName,
              'ts': 3,
            }),
          ],
        ).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'setVMTimelineFlags',
        args: <String, Object>{
          'recordedStreams': <Object>[],
        },
      ),
    ]);

    // Validate that old tracing data is deleted.
    final File outFile = fileSystem.currentDirectory.childFile('start_up_info.json')
      ..writeAsStringSync('stale');

    await downloadStartupTrace(fakeVmServiceHost.vmService,
      output: fileSystem.currentDirectory,
      logger: logger,
    );

    expect(outFile, exists);
    expect(json.decode(outFile.readAsStringSync()), <String, Object>{
      'engineEnterTimestampMicros': 0,
      'timeToFrameworkInitMicros': 1,
      'timeToFirstFrameRasterizedMicros': 3,
      'timeToFirstFrameMicros': 2,
      'timeAfterFrameworkInitMicros': 1,
    });
  });

  testWithoutContext('throws tool exit if the vmservice disconnects', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <FakeVmServiceRequest>[
      ...vmServiceSetup,
      const FakeVmServiceRequest(
        method: 'getVMTimeline',
        errorCode: RPCErrorCodes.kServiceDisappeared,
      ),
      const FakeVmServiceRequest(
        method: 'setVMTimelineFlags',
        args: <String, Object>{
          'recordedStreams': <Object>[],
        },
      ),
    ]);

    await expectLater(() async => downloadStartupTrace(fakeVmServiceHost.vmService,
      output: fileSystem.currentDirectory,
      logger: logger,
    ), throwsToolExit(message: 'The device disconnected before the timeline could be retrieved.'));
  });

  testWithoutContext('throws tool exit if timeline is missing the engine start event', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <FakeVmServiceRequest>[
      ...vmServiceSetup,
      FakeVmServiceRequest(
        method: 'getVMTimeline',
        jsonResponse: vm_service.Timeline(
          timeExtentMicros: 4,
          timeOriginMicros: 0,
          traceEvents: <vm_service.TimelineEvent>[],
        ).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'setVMTimelineFlags',
        args: <String, Object>{
          'recordedStreams': <Object>[],
        },
      ),
    ]);

    await expectLater(() async => downloadStartupTrace(fakeVmServiceHost.vmService,
      output: fileSystem.currentDirectory,
      logger: logger,
    ), throwsToolExit(message: 'Engine start event is missing in the timeline'));
  });

  testWithoutContext('throws tool exit if first frame events are missing', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <FakeVmServiceRequest>[
      ...vmServiceSetup,
      FakeVmServiceRequest(
        method: 'getVMTimeline',
        jsonResponse: vm_service.Timeline(
          timeExtentMicros: 4,
          timeOriginMicros: 0,
          traceEvents: <vm_service.TimelineEvent>[
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFlutterEngineMainEnterEventName,
              'ts': 0,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFrameworkInitEventName,
              'ts': 1,
            }),
          ],
        ).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'setVMTimelineFlags',
        args: <String, Object>{
          'recordedStreams': <Object>[],
        },
      ),
    ]);

    await expectLater(() async => downloadStartupTrace(fakeVmServiceHost.vmService,
      output: fileSystem.currentDirectory,
      logger: logger,
    ), throwsToolExit(message: 'First frame events are missing in the timeline'));
  });

  testWithoutContext('Can trace application startup without awaiting for first frame', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <FakeVmServiceRequest>[
      FakeVmServiceRequest(
        method: 'getVMTimeline',
        jsonResponse: vm_service.Timeline(
          timeExtentMicros: 4,
          timeOriginMicros: 0,
          traceEvents: <vm_service.TimelineEvent>[
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFlutterEngineMainEnterEventName,
              'ts': 0,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFrameworkInitEventName,
              'ts': 1,
            }),
          ],
        ).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'setVMTimelineFlags',
        args: <String, Object>{
          'recordedStreams': <Object>[],
        },
      ),
    ]);

    final File outFile = fileSystem.currentDirectory.childFile('start_up_info.json');

    await downloadStartupTrace(fakeVmServiceHost.vmService,
      output: fileSystem.currentDirectory,
      logger: logger,
      awaitFirstFrame: false,
    );

    expect(outFile, exists);
    expect(json.decode(outFile.readAsStringSync()), <String, Object>{
      'engineEnterTimestampMicros': 0,
      'timeToFrameworkInitMicros': 1,
    });
  });

  testWithoutContext('downloadStartupTrace also downloads the timeline', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <FakeVmServiceRequest>[
      ...vmServiceSetup,
      FakeVmServiceRequest(
        method: 'getVMTimeline',
        jsonResponse: vm_service.Timeline(
          timeExtentMicros: 4,
          timeOriginMicros: 0,
          traceEvents: <vm_service.TimelineEvent>[
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFlutterEngineMainEnterEventName,
              'ts': 0,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFrameworkInitEventName,
              'ts': 1,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFirstFrameBuiltEventName,
              'ts': 2,
            }),
            vm_service.TimelineEvent.parse(<String, Object>{
              'name': kFirstFrameRasterizedEventName,
              'ts': 3,
            }),
          ],
        ).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'setVMTimelineFlags',
        args: <String, Object>{
          'recordedStreams': <Object>[],
        },
      ),
    ]);

    // Validate that old tracing data is deleted.
    final File timelineFile = fileSystem.currentDirectory.childFile('start_up_timeline.json')
      ..writeAsStringSync('stale');

    await downloadStartupTrace(fakeVmServiceHost.vmService,
      output: fileSystem.currentDirectory,
      logger: logger,
    );

    final Map<String, dynamic> expectedTimeline = <String, dynamic>{
      'type': 'Timeline',
      'traceEvents': <dynamic>[
        <String, dynamic>{
          'name': 'FlutterEngineMainEnter',
          'ts': 0,
          'type': 'TimelineEvent',
        },
        <String, dynamic>{
          'name': 'Framework initialization',
          'ts': 1,
          'type': 'TimelineEvent',
        },
        <String, dynamic>{
          'name': 'Widgets built first useful frame',
          'ts': 2,
          'type': 'TimelineEvent',
        },
        <String, dynamic>{
          'name': 'Rasterized first useful frame',
          'ts': 3,
          'type': 'TimelineEvent',
        },
      ],
      'timeOriginMicros': 0,
      'timeExtentMicros': 4,
    };

    expect(timelineFile, exists);
    expect(json.decode(timelineFile.readAsStringSync()), expectedTimeline);
  });
}
