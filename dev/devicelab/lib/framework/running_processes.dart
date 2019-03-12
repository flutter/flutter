// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

@immutable
class RunningProcessInfo {
  const RunningProcessInfo(this.pid, this.creationDate, this.commandLine)
      : assert(pid != null),
        assert(commandLine != null);

  final String commandLine;
  final int pid;
  final DateTime creationDate;

  @override
  bool operator ==(Object other) {
    return other is RunningProcessInfo && other.pid == pid;
  }

  @override
  int get hashCode => pid.hashCode;

  @override
  String toString() {
    return 'RunningProcesses{pid: $pid, commandLine: $commandLine, creationDate: $creationDate}';
  }
}

Future<bool> killProcess(int pid, {ProcessManager processManager}) async {
  assert(pid != null, 'Must specify a pid to kill');
  processManager ??= const LocalProcessManager();
  ProcessResult result;
  if (Platform.isWindows) {
    result = await processManager.run(<String>[
      'taskkill',
      '/pid', pid.toString(),
      '/f',
    ]);
  } else {
    result = await processManager.run(<String>[
      'kill',
      '-9',
      pid.toString(),
    ]);
  }
  return result.exitCode == 0;
}

Stream<RunningProcessInfo> getRunningProcesses({
  String processName,
  ProcessManager processManager,
}) {
  processManager ??= const LocalProcessManager();
  if (Platform.isWindows) {
    return windowsRunningProcesses(processName, processManager);
  }
  return posixRunningProcesses(processName, processManager);
}

@visibleForTesting
Stream<RunningProcessInfo> windowsRunningProcesses(
    String processName, ProcessManager processManager) async* {
  final String script = processName != null
      ? '''"Get-CimInstance Win32_Process -Filter \\"name='$processName'\\" | Select-Object ProcessId,CreationDate,CommandLine | Format-Table -AutoSize | Out-String -Width 4096"'''
      : '"Get-CimInstance Win32_Process | Select-Object ProcessId,CreationDate,CommandLine | Format-Table -AutoSize | Out-String -Width 4096"';
  final ProcessResult result = await processManager.run(<String>[
    'powershell',
    '-c',
    script,
  ]);
  if (result.exitCode != 0) {
    print('Could not list processes!');
    print(result.stderr);
    print(result.stdout);
    exit(result.exitCode);
  }
  for (RunningProcessInfo info in processPowershellOutput(result.stdout)) {
    yield info;
  }
}

@visibleForTesting
Iterable<RunningProcessInfo> processPowershellOutput(String output) sync* {
  // e.g.:
  //
  // ProcessId CreationDate          CommandLine
  // --------- ------------          -----------
  //      2904 3/11/2019 11:01:54 AM "C:\Program Files\Android\Android Studio\jre\bin\java.exe" -Xmx1536M -Dfile.encoding=windows-1252 -Duser.country=US -Duser.language=en -Duser.variant -cp C:\Users\win1\.gradle\wrapper\dists\gradle-4.10.2-all\9fahxiiecdb76a5g3aw9oi8rv\gradle-4.10.2\lib\gradle-launcher-4.10.2.jar org.gradle.launcher.daemon.bootstrap.GradleDaemon 4.10.2
  if (output == null) {
    return;
  }

  const int processIdHeaderSize = 'ProcessId'.length;
  const int creationDateHeaderStart = processIdHeaderSize + 1;
  int creationDateHeaderEnd;
  int commandLineHeaderStart;
  bool inTableBody = false;
  for (String line in output.split('\n')) {
    if (line.startsWith('ProcessId')) {
      commandLineHeaderStart = line.indexOf('CommandLine');
      creationDateHeaderEnd = commandLineHeaderStart - 1;
    }
    if (line.startsWith('--------- ------------')) {
      inTableBody = true;
      continue;
    }
    if (!inTableBody || line.isEmpty) {
      continue;
    }

    DateTime getDateTime() {
      // 3/11/2019 11:01:54 AM
      // 12/11/2019 11:01:54 AM
      String raw = line.substring(
        creationDateHeaderStart,
        creationDateHeaderEnd,
      );

      if (raw[1] == '/') {
        raw = '0$raw';
      }
      if (raw[4] == '/') {
        raw = raw.substring(0, 3) + '0' + raw.substring(3);
      }
      final String year = raw.substring(6, 10);
      final String month = raw.substring(3, 5);
      final String day = raw.substring(0, 2);
      String time = raw.substring(11, 19);
      if (time[7] == ' ') {
        time = '0$time'.trim();
      }
      if (raw.endsWith('PM')) {
        final int hours = int.parse(time.substring(0, 2));
        time = '${hours + 12}${time.substring(2)}';
      }
      return DateTime.parse('$year-$month-${day}T$time');
    }

    final int pid = int.parse(line.substring(0, processIdHeaderSize).trim());
    final DateTime creationDate = getDateTime();
    final String commandLine = line.substring(commandLineHeaderStart).trim();
    yield RunningProcessInfo(pid, creationDate, commandLine);
  }
}

@visibleForTesting
Stream<RunningProcessInfo> posixRunningProcesses(
    String processName, ProcessManager processManager) async* {
  final ProcessResult result = await processManager.run(<String>[
    'ps',
    '-Ao',
    'lstart,pid,command',
  ]);
  if (result.exitCode != 0) {
    print('Could not list processes!');
    print(result.stderr);
    print(result.stdout);
    exit(result.exitCode);
  }
  for (RunningProcessInfo info in processPsOutput(result.stdout, processName)) {
    yield info;
  }
}

@visibleForTesting
Iterable<RunningProcessInfo> processPsOutput(String output, String processName) sync* {
  // e.g.:
  //
  // STARTED                        PID COMMAND
  // Sat Mar  9 20:12:47 2019         1 /sbin/launchd
  // Sat Mar  9 20:13:00 2019        49 /usr/sbin/syslogd

  if (output == null) {
    return;
  }
  bool inTableBody = false;
  for (String line in output.split('\n')) {
    if (line.trim().startsWith('STARTED')) {
      inTableBody = true;
      continue;
    }
    if (!inTableBody || line.isEmpty) {
      continue;
    }

    if (processName != null && !line.contains(processName)) {
      continue;
    }

    DateTime getDateTime() {
      // 'Sat Feb 16 02:29:55 2019'
      // 'Sat Mar  9 20:12:47 2019'
      const Map<String, String> months = <String, String>{
        'Jan': '01',
        'Feb': '02',
        'Mar': '03',
        'Apr': '04',
        'May': '05',
        'Jun': '06',
        'Jul': '07',
        'Aug': '08',
        'Sep': '09',
        'Oct': '10',
        'Nov': '11',
        'Dec': '12',
      };
      final String raw = line.substring(0, 24);

      final String year = raw.substring(20, 24);
      final String month = months[raw.substring(4, 7)];
      final String day = raw.substring(8, 10).replaceFirst(' ', '0');
      final String time = raw.substring(11, 19);
      return DateTime.parse('$year-$month-${day}T$time');
    }

    final DateTime creationDate = getDateTime();
    line = line.substring(24).trim();
    final int nextSpace = line.indexOf(' ');
    final int pid = int.parse(line.substring(0, nextSpace));
    final String commandLine = line.substring(nextSpace + 1);
    yield RunningProcessInfo(pid, creationDate, commandLine);
  }
}
