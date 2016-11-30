// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'context.dart';

ProcessManager get processManager => context[ProcessManager];

class ProcessManager {
  Future<Process> start(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       ProcessStartMode mode: ProcessStartMode.NORMAL}) {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
    );
  }

  Future<ProcessResult> run(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  ProcessResult runSync(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
    return Process.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    return Process.killPid(pid, signal);
  }
}
