// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'utils.dart';

class MacOSInfo {
  /// Print information collected from the operating system.
  ///
  /// Built in tools such as `system_profiler` and `defaults` are utilized.
  Future<void> printInformation() async {
    await _printSafariApplications();
    await _printSafariDefaults();
    await _printUserLimits();
  }

  /// Print information on applications in the system that contains string
  /// `Safari`.
  Future<void> _printSafariApplications() async {
    final ProcessManager systemProfiler = await startProcess(
      'system_profiler',
      ['SPApplicationsDataType', '-json'],
      evalOutput: true,
    );
    final String systemProfileJson = await systemProfiler.evalStdout();

    final Map<String, dynamic> json =
        jsonDecode(systemProfileJson) as Map<String, dynamic>;
    final List<dynamic> systemProfile = json.values.first as List<dynamic>;
    for (int i = 0; i < systemProfile.length; i++) {
      final Map<String, dynamic> application =
          systemProfile[i] as Map<String, dynamic>;
      final String applicationName = application['_name'] as String;
      if (applicationName.contains('Safari')) {
        print('application: $applicationName '
            'fullInfo: ${application.toString()}');
      }
    }
  }

  /// Print all the defaults in the system related to Safari.
  Future<void> _printSafariDefaults() async {
    final ProcessManager defaults = await startProcess(
      '/usr/bin/defaults',
      ['find', 'Safari'],
      evalOutput: true,
    );
    print('Safari related defaults:\n ${await defaults.evalStdout()}');
  }

  /// Print user limits (file and process).
  Future<void> _printUserLimits() async {
    ProcessManager ulimit = await startProcess('ulimit', ['-n'], evalOutput: true);
    final String fileLimit = await ulimit.evalStdout();
    print('MacOS file limit: $fileLimit');

    ulimit = await startProcess('ulimit', ['-u'], evalOutput: true);
    final String processLimit = await ulimit.evalStdout();
    print('MacOS process limit: $processLimit');
  }
}
