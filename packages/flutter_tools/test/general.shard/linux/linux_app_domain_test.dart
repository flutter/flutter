// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/extension/app.dart';
import 'package:flutter_tools/src/linux/linux_extension.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  LinuxAppDomain appDomain;
  MockProcessManager processManager;

  setUp(() {
    processManager = MockProcessManager();
    appDomain = LinuxToolExtension(
      processManager: processManager,
    ).appDomain;
  });

  // TODO(jonahwilliams): refactor to no longer need context info.
  testUsingContext('LinuxAppDomain.startApp invokes provided executable and returns vmservice Uri', () async {
    const ApplicationBundle applicationBundle = ApplicationBundle(
      executable: 'example.app',
    );
    when(processManager.start(<String>['example.app'])).thenAnswer((Invocation invocation) async {
      return FakeProcess(
        exitCode: Future<int>.value(0),
        pid: 1991,
        stdout: Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('  Observatory listening on http://127.0.0.1:8080/someid/ ')
        ],
      ));
    });

    final ApplicationInstance instance = await appDomain.startApp(applicationBundle, 'linux');
    expect(instance.context, containsPair('processId', 1991));
    expect(instance.vmserviceUri, Uri.parse('http://127.0.0.1:8080/someid/'));
  });

  testUsingContext('LinuxAppDomain.stopApp invokes kill on provided pid', () async {
    const ApplicationBundle applicationBundle = ApplicationBundle(
      executable: 'example.app',
      context: <String, Object>{
        'processId': 123,
      }
    );

    await appDomain.stopApp(applicationBundle);
    
    verify(processManager.killPid(123)).called(1);
  });

  testUsingContext('LinuxAppDomain.stopApp does not invoke kill on null pid', () async {
    const ApplicationBundle applicationBundle = ApplicationBundle(
        executable: 'example.app',
    );

    await appDomain.stopApp(applicationBundle);

    verifyNever(processManager.killPid(null));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
