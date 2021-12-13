// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/running_processes.dart';
import 'common.dart';

void main() {
  test('Parse PowerShell result', () {
    const String powershellOutput = r'''

ProcessId CreationDate         CommandLine
--------- ------------         -----------
     6552 3/7/2019 5:00:27 PM  "C:\tools\dart-sdk\bin\dart.exe" .\bin\agent.dart ci
     6553 3/7/2019 10:00:27 PM "C:\tools\dart-sdk1\bin\dart.exe" .\bin\agent.dart ci
     6554 3/7/2019 11:00:27 AM "C:\tools\dart-sdk2\bin\dart.exe" .\bin\agent.dart ci


''';
    final List<RunningProcessInfo> results =
        processPowershellOutput(powershellOutput).toList();
    expect(results.length, 3);
    expect(
        results,
        equals(<RunningProcessInfo>[
          RunningProcessInfo(
            '6552',
            DateTime(2019, 7, 3, 17, 0, 27),
            r'"C:\tools\dart-sdk\bin\dart.exe" .\bin\agent.dart ci',
          ),
          RunningProcessInfo(
            '6553',
            DateTime(2019, 7, 3, 22, 0, 27),
            r'"C:\tools\dart-sdk1\bin\dart.exe" .\bin\agent.dart ci',
          ),
          RunningProcessInfo(
            '6554',
            DateTime(2019, 7, 3, 11, 0, 27),
            r'"C:\tools\dart-sdk2\bin\dart.exe" .\bin\agent.dart ci',
          ),
        ]));
  });

  test('Parse Posix output', () {
    const String psOutput = r'''
STARTED                        PID COMMAND
Sat Mar  9 20:12:47 2019         1 /sbin/launchd
Sat Mar  9 20:13:00 2019        49 /usr/sbin/syslogd
''';

    final List<RunningProcessInfo> results =
        processPsOutput(psOutput, null).toList();
    expect(results.length, 2);
    expect(
        results,
        equals(<RunningProcessInfo>[
          RunningProcessInfo(
            '1',
            DateTime(2019, 3, 9, 20, 12, 47),
            '/sbin/launchd',
          ),
          RunningProcessInfo(
            '49',
            DateTime(2019, 3, 9, 20, 13),
            '/usr/sbin/syslogd',
          ),
        ]));
  });
}
