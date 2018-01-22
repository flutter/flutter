// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process/process.dart';

class FakeProcessManager implements ProcessManager {
  FakeProcessManager(this.results);

  final Map<String, List<ProcessResult>> results;
  List<int> lastStdin = <int>[];

  @override
  Future<Process> start(List<dynamic> command,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      ProcessStartMode mode: ProcessStartMode.NORMAL}) {
    final ProcessResult nextResult = results[command.join(' ')]?.removeAt(0);
    return new Future<Process>.value(new FakeProcess(
      nextResult.stdout,
      desiredStderr: nextResult.stderr,
      stdinResults: lastStdin,
      shouldError: nextResult.exitCode != 0,
    ));
  }

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    return true;
  }

  @override
  bool canRun(dynamic executable, {String workingDirectory}) {
    return true;
  }

  @override
  ProcessResult runSync(List<dynamic> command,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: SYSTEM_ENCODING,
      Encoding stderrEncoding: SYSTEM_ENCODING}) {
    return results[command.join(' ')]?.removeAt(0);
  }

  @override
  Future<ProcessResult> run(List<dynamic> command,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: SYSTEM_ENCODING,
      Encoding stderrEncoding: SYSTEM_ENCODING}) {
    return new Future<ProcessResult>.value(results[command.join(' ')]?.removeAt(0));
  }
}

class FakeProcess implements Process {
  FakeProcess(List<int> desiredStdout,
      {List<int> desiredStderr = const <int>[], List<int> stdinResults, this.shouldError = false})
      : stdoutStream = new FakeStringStream(desiredStdout, shouldError),
        stderrStream = new FakeStringStream(desiredStderr, shouldError),
        stdinSink = new IOSink(new StringStreamConsumer(stdinResults));

  final IOSink stdinSink;
  final Stream<List<int>> stdoutStream;
  final Stream<List<int>> stderrStream;
  final bool shouldError;

  @override
  Future<int> get exitCode {
    return new Future<int>.value(0);
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) {
    return true;
  }

  @override
  int get pid {
    return 0;
  }

  @override
  IOSink get stdin {
    return stdinSink;
  }

  @override
  Stream<List<int>> get stderr => stderrStream;

  @override
  Stream<List<int>> get stdout => stdoutStream;
}

typedef void FakeDataCallback(List<int> event);
typedef void VoidCallback();

class FakeStringStreamSubscription extends StreamSubscription<List<int>> {
  FakeStringStreamSubscription(this.data, this._onData, this._onError, this._onDone,
      [this.cancelOnError = true, this.shouldError = false]);

  FakeDataCallback _onData;
  Function _onError;
  VoidCallback _onDone;
  final bool cancelOnError;
  final bool shouldError;
  Completer<dynamic> completer;
  final List<int> data;
  bool paused = false;

  @override
  Future<dynamic> cancel() {
    return deliverData();
  }

  @override
  Future<E> asFuture<E>([E futureValue]) {
    return new Future<E>.value(futureValue);
  }

  @override
  bool get isPaused {
    return paused;
  }

  @override
  void resume() {
    paused = false;
    completer.complete(null);
    completer = null;
  }

  @override
  void pause([Future<dynamic> resumeSignal]) {
    paused = true;
    completer = new Completer<dynamic>();
  }

  @override
  void onDone(void handleDone()) => _onDone = handleDone;

  @override
  void onError(Function handleError) => _onError = handleError;

  @override
  void onData(void handleData(List<int> data)) => _onData = handleData;

  Future<dynamic> deliverData() async {
    if (completer != null) {
      await completer.future;
    }
    _onData(data);
    if (shouldError) {
      if (cancelOnError) {
        await cancel();
      }
      Function.apply(_onError, <dynamic>[]);
    }
    _onDone();
  }
}

class FakeStringStream extends Stream<List<int>> {
  FakeStringStream(this.data, this.shouldError);

  final List<int> data;
  final bool shouldError;

  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    final FakeStringStreamSubscription subscription =
        new FakeStringStreamSubscription(data, onData, onError, onDone, cancelOnError, shouldError);
    subscription.deliverData();
    return subscription;
  }
}

class StringStreamConsumer implements StreamConsumer<List<int>> {
  StringStreamConsumer(this.accumulatedData);

  List<Stream<List<int>>> streams = <Stream<List<int>>>[];
  List<StreamSubscription<List<int>>> subscriptions = <StreamSubscription<List<int>>>[];
  List<Completer<dynamic>> completers = <Completer<dynamic>>[];
  List<int> accumulatedData;

  @override
  Future<dynamic> addStream(Stream<List<int>> value) {
    streams.add(value);
    completers.add(new Completer<dynamic>());
    subscriptions.add(value.listen((List<int> data) {
      accumulatedData?.addAll(data);
    }));
    subscriptions.last.onDone(() => completers.last.complete(null));
    return new Future<dynamic>.value(null);
  }

  @override
  Future<dynamic> close() async {
    for (Completer<dynamic> completer in completers) {
      await completer.future;
    }
    completers.clear();
    streams.clear();
    subscriptions.clear();
    return new Future<dynamic>.value(null);
  }
}
