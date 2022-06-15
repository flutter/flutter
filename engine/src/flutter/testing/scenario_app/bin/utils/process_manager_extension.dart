// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';

/// Pipes the [process] streams and writes them to [out] sink.
/// If [out] is null, then the current [Process.stdout] is used as the sink.
Future<int> pipeProcessStreams(
  Process process, {
  StringSink? out,
}) async {
  out ??= stdout;
  final Completer<void> stdoutCompleter = Completer<void>();
  final StreamSubscription<String> stdoutSub = process.stdout
    .transform(utf8.decoder)
    .transform<String>(const LineSplitter())
    .listen((String line) {
      out!.writeln('[stdout] $line');
    }, onDone: stdoutCompleter.complete);

  final Completer<void> stderrCompleter = Completer<void>();
  final StreamSubscription<String> stderrSub = process.stderr
    .transform(utf8.decoder)
    .transform<String>(const LineSplitter())
    .listen((String line) {
      out!.writeln('[stderr] $line');
    }, onDone: stderrCompleter.complete);

  final int exitCode = await process.exitCode;
  await stderrSub.cancel();
  await stdoutSub.cancel();

  await stdoutCompleter.future;
  await stderrCompleter.future;
  return exitCode;
}

extension RunAndForward on ProcessManager {
  /// Runs [cmd], and forwards the stdout and stderr pipes to the current process stdout pipe.
  Future<int> runAndForward(List<String> cmd) async {
    return pipeProcessStreams(await start(cmd), out: stdout);
  }
}
