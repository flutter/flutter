// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  testWithoutContext('IProxy resolves iproxyPath lazily from Artifacts', () async {
    final artifacts = Artifacts.test();
    final processManager = FakeProcessManager.empty();
    final logger = BufferLogger.test();

    final iproxy = IProxy(
      artifacts: artifacts,
      logger: logger,
      processManager: processManager,
      dyLdLibEntry: const MapEntry<String, String>('DYLD_LIBRARY_PATH', '/path/to/libs'),
    );

    expect(iproxy.iproxyPath, artifacts.getHostArtifact(HostArtifact.iproxy).path);
  });

  testWithoutContext('IProxy.fromPath uses specified path', () async {
    final processManager = FakeProcessManager.empty();
    final logger = BufferLogger.test();

    final iproxy = IProxy.fromPath(
      iproxyPath: '/custom/path/to/iproxy',
      logger: logger,
      processManager: processManager,
      dyLdLibEntry: const MapEntry<String, String>('DYLD_LIBRARY_PATH', '/path/to/libs'),
    );

    expect(iproxy.iproxyPath, '/custom/path/to/iproxy');
  });

  testWithoutContext('IProxy.test uses default test configuration', () async {
    final processManager = FakeProcessManager.empty();
    final logger = BufferLogger.test();

    final iproxy = IProxy.test(logger: logger, processManager: processManager);

    expect(iproxy.iproxyPath, 'iproxy');
  });

  testWithoutContext('IProxy.forward invokes iproxy process with expected arguments', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['iproxy', '4200:4200', '--udid', '12345'],
        environment: <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libs'},
      ),
    ]);
    final logger = BufferLogger.test();

    final iproxy = IProxy.test(logger: logger, processManager: processManager);
    await iproxy.forward(4200, 4200, '12345');

    expect(processManager, hasNoRemainingExpectations);
  });
}
