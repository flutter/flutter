// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/devices.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

const kDyLdLibEntry = <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libs'};

void main() {
  // By default, the .forward() method will try every port between 1024
  // and 65535; this test verifies we are killing iproxy processes when
  // we timeout on a port
  testWithoutContext(
    'IOSDevicePortForwarder.forward will kill iproxy processes before invoking a second',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        // iproxy does not exit with 0 when it cannot forward;
        // the FakeCommands below expect an exitCode of 0.
        const FakeCommand(
          command: <String>['iproxy', '12345:456', '--udid', '1234'],
          environment: kDyLdLibEntry,
          // Empty stdout indicates failure.
        ),
        const FakeCommand(
          command: <String>['iproxy', '12346:456', '--udid', '1234'],
          stdout: 'not empty',
          environment: kDyLdLibEntry,
        ),
      ]);
      final operatingSystemUtils = FakeOperatingSystemUtils();

      final portForwarder = IOSDevicePortForwarder.test(
        processManager: processManager,
        logger: BufferLogger.test(),
        operatingSystemUtils: operatingSystemUtils,
      );
      final int hostPort = await portForwarder.forward(456);

      // First port tried (12345) should fail, then succeed on the next
      expect(hostPort, 12345 + 1);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'IOSDevicePortForwarder.forward returns existing forwarded port when devicePort is already forwarded',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['iproxy', '12345:456', '--udid', '1234'],
          stdout: 'not empty',
          environment: kDyLdLibEntry,
        ),
      ]);
      final operatingSystemUtils = FakeOperatingSystemUtils();

      final portForwarder = IOSDevicePortForwarder.test(
        processManager: processManager,
        logger: BufferLogger.test(),
        operatingSystemUtils: operatingSystemUtils,
      );

      final int hostPort1 = await portForwarder.forward(456);
      expect(hostPort1, 12345);

      // Second call for the same device port should reuse the existing forward.
      final int hostPort2 = await portForwarder.forward(456);
      expect(hostPort2, 12345);

      expect(portForwarder.forwardedPorts.length, 1);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'IOSDevicePortForwarder.forward deduplicates in-flight forward requests for the same devicePort',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['iproxy', '12345:456', '--udid', '1234'],
          stdout: 'not empty',
          environment: kDyLdLibEntry,
        ),
      ]);
      final operatingSystemUtils = FakeOperatingSystemUtils();

      final portForwarder = IOSDevicePortForwarder.test(
        processManager: processManager,
        logger: BufferLogger.test(),
        operatingSystemUtils: operatingSystemUtils,
      );

      // Trigger two concurrent forward requests for the same device port.
      final Future<int> future1 = portForwarder.forward(456);
      final Future<int> future2 = portForwarder.forward(456);

      final List<int> hostPorts = await Future.wait(<Future<int>>[future1, future2]);
      expect(hostPorts[0], 12345);
      expect(hostPorts[1], 12345);

      expect(portForwarder.forwardedPorts.length, 1);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'IOSDevicePortForwarder.forward allows retry after a failed forward attempt',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['iproxy', '12345:456', '--udid', '1234'],
          environment: kDyLdLibEntry,
          // Empty stdout indicates failure.
        ),
        const FakeCommand(
          command: <String>['iproxy', '12345:456', '--udid', '1234'],
          stdout: 'not empty',
          environment: kDyLdLibEntry,
        ),
      ]);
      final operatingSystemUtils = FakeOperatingSystemUtils();

      final portForwarder = IOSDevicePortForwarder.test(
        processManager: processManager,
        logger: BufferLogger.test(),
        operatingSystemUtils: operatingSystemUtils,
      );

      // First attempt fails.
      await expectLater(portForwarder.forward(456, hostPort: 12345), throwsA(isA<Exception>()));

      // Subsequent attempt after error can retry and succeed.
      final int hostPort = await portForwarder.forward(456, hostPort: 12345);
      expect(hostPort, 12345);
      expect(portForwarder.forwardedPorts.length, 1);
      expect(processManager, hasNoRemainingExpectations);
    },
  );
}
