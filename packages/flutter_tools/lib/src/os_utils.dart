// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';

import 'process.dart';

final OperatingSystemUtils osUtils = new OperatingSystemUtils._();

final Logger _logging = new Logger('sky_tools.os');

abstract class OperatingSystemUtils {
  factory OperatingSystemUtils._() {
    if (Platform.isWindows) {
      return new _WindowsUtils();
    } else if (Platform.isMacOS) {
      return new _MacUtils();
    } else {
      return new _LinuxUtils();
    }
  }

  /// Make the given file executable. This may be a no-op on some platforms.
  ProcessResult makeExecutable(File file);

  /// A best-effort attempt to kill all listeners on the given TCP port.
  void killTcpPortListeners(int tcpPort);
}

abstract class _PosixUtils implements OperatingSystemUtils {
  ProcessResult makeExecutable(File file) {
    return Process.runSync('chmod', ['u+x', file.path]);
  }
}

class _WindowsUtils implements OperatingSystemUtils {
  // This is a no-op.
  ProcessResult makeExecutable(File file) {
    return new ProcessResult(0, 0, null, null);
  }

  void killTcpPortListeners(int tcpPort) {
    // Get list of network processes and split on newline
    List<String> processes = runSync(['netstat.exe','-ano']).split("\r");

    // List entries from netstat is formatted like so:
    //   TCP    192.168.2.11:50945     192.30.252.90:443      LISTENING     1304
    // This regexp is to find process where the the port exactly matches
    RegExp pattern = new RegExp(':$tcpPort[ ]+');

    // Split the columns by 1 or more spaces
    RegExp columnPattern = new RegExp('[ ]+');
    processes.forEach((String process) {
      if (process.contains(pattern)) {
        // The last column is the Process ID
        String processId = process.split(columnPattern).last;
        // Force and Tree kill the process
        _logging.info('kill $processId');
        runSync(['TaskKill.exe', '/F', '/T', '/PID', processId]);
      }
    });
  }
}

class _MacUtils extends _PosixUtils {
  void killTcpPortListeners(int tcpPort) {
    String pids = runSync(['lsof', '-i', ':$tcpPort', '-t']).trim();
    if (pids.isNotEmpty) {
      // Handle multiple returned pids.
      for (String pidString in pids.split('\n')) {
        // Killing a pid with a shell command from within dart is hard, so use a
        // library command, but it's still nice to give the equivalent command
        // when doing verbose logging.
        _logging.info('kill $pidString');

        int pid = int.parse(pidString, onError: (_) => null);
        if (pid != null)
          Process.killPid(pid);
      }
    }
  }
}

class _LinuxUtils extends _PosixUtils {
  void killTcpPortListeners(int tcpPort) {
    runSync(['fuser', '-k', '$tcpPort/tcp']);
  }
}
