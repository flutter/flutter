// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io' hide Directory;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

void main() {
  test('initialization - imgtestInit first', () async {
    final FileSystem fs = MemoryFileSystem();
    final Directory dir = fs.directory('/');
    final List<String> log = <String>[];
    final SkiaGoldClient client = SkiaGoldClient(dir,
      fs: fs,
      process: FakeProcessManager(),
      platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/'}, operatingSystem: Platform.fuchsia),
      abi: Abi.fuchsiaRiscv64,
      httpClient: FakeHttpClient(),
      log: log.add,
    );
    expect(identical(client.imgtestInit(), client.imgtestInit()), isTrue); // re-entrant calls return the same future
    try {
      // Don't await this (even indirectly using `throwsA`) because in the failure case, we'd hang the test
      // because the FakeProcessManager we use never returns.
      // Using a synchronous try/catch works because the assertion is not asynchronous.
      client.tryjobInit();
      fail('Missing assertion.');
    } on AssertionError catch (e) {
      expect('$e', contains('imgtestInit')); // can't call different initializers
    }
  });

  test('initialization - tryjobInit first', () async {
    final FileSystem fs = MemoryFileSystem();
    final Directory dir = fs.directory('/');
    final List<String> log = <String>[];
    final SkiaGoldClient client = SkiaGoldClient(dir,
      fs: fs,
      process: FakeProcessManager(),
      platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/'}, operatingSystem: Platform.fuchsia),
      abi: Abi.fuchsiaRiscv64,
      httpClient: FakeHttpClient(),
      log: log.add,
    );
    expect(identical(client.tryjobInit(), client.tryjobInit()), isTrue); // re-entrant calls return the same future
    try {
      // Don't await this (even indirectly using `throwsA`) because in the failure case, we'd hang the test
      // because the FakeProcessManager we use never returns.
      // Using a synchronous try/catch works because the assertion is not asynchronous.
      client.imgtestInit();
      fail('Missing assertion.');
    } on AssertionError catch (e) {
      expect('$e', contains('tryjobInit')); // can't call different initializers
    }
  });
}

// all calls just hang
class FakeProcessManager extends Fake implements ProcessManager {
  @override
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    return Completer<ProcessResult>().future;
  }
}

class FakeHttpClient extends Fake implements HttpClient { }
