// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

final OperatingSystemUtils os = new OperatingSystemUtils._();

abstract class OperatingSystemUtils {
  factory OperatingSystemUtils._() {
    if (Platform.isWindows) {
      return new _WindowsUtils();
    } else {
      return new _PosixUtils();
    }
  }

  /// Make the given file executable. This may be a no-op on some platforms.
  ProcessResult makeExecutable(File file);

  /// Return the path (with symlinks resolved) to the given executable, or `null`
  /// if `which` was not able to locate the binary.
  File which(String execName);
}

class _PosixUtils implements OperatingSystemUtils {
  ProcessResult makeExecutable(File file) {
    return Process.runSync('chmod', ['u+x', file.path]);
  }

  /// Return the path (with symlinks resolved) to the given executable, or `null`
  /// if `which` was not able to locate the binary.
  File which(String execName) {
    ProcessResult result = Process.runSync('which', <String>[execName]);
    if (result.exitCode != 0)
      return null;
    String path = result.stdout.trim().split('\n').first.trim();
    return new File(new File(path).resolveSymbolicLinksSync());
  }
}

class _WindowsUtils implements OperatingSystemUtils {
  // This is a no-op.
  ProcessResult makeExecutable(File file) {
    return new ProcessResult(0, 0, null, null);
  }

  File which(String execName) {
    throw new UnimplementedError('_WindowsUtils.which');
  }
}

Future<int> findAvailablePort() async {
  ServerSocket socket = await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  int port = socket.port;
  await socket.close();
  return port;
}
