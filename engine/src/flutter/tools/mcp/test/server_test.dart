// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonDecode;

import 'package:dart_mcp/server.dart';
import 'package:engine_mcp/server.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';
import 'package:stream_channel/stream_channel.dart' show StreamChannel;
import 'package:test/test.dart';

const _initMessage =
    '{"jsonrpc": "2.0", "id": 1,"method": "initialize", "params": {"protocolVersion": "2025-03-26", "capabilities": { "roots": {"listChanged": true },"sampling": {} },"clientInfo": { "name": "ExampleClient", "version": "1.0.0"}}}';

void main() {
  test('list tools', () async {
    final inputController = StreamController<String>();
    final outputController = StreamController<String>();
    final MCPServer server = EngineServer.fromStreamChannel(
      StreamChannel.withCloseGuarantee(inputController.stream, outputController.sink),
    );

    final StreamIterator<String> streamIterator = StreamIterator(outputController.stream);

    inputController.add(_initMessage);
    expect(await streamIterator.moveNext(), isTrue);

    const requestJson = '{ "jsonrpc": "2.0", "id": 1, "method": "tools/list" }\n';
    inputController.add(requestJson);

    expect(await streamIterator.moveNext(), isTrue);
    final String outputString = streamIterator.current;
    final json = jsonDecode(outputString) as Map<String, dynamic>;

    expect(json['jsonrpc'], equals('2.0'), reason: outputString);
    expect(json['id'], equals(1), reason: outputString);
    expect(json.containsKey('result'), isTrue);
    // ignore: avoid_dynamic_calls
    expect(json['result']['tools'], isNotEmpty, reason: outputString);

    await inputController.close();
    server.shutdown();
  });

  test('build', () async {
    final inputController = StreamController<String>();
    final outputController = StreamController<String>();
    final MCPServer server = EngineServer.fromStreamChannel(
      StreamChannel.withCloseGuarantee(inputController.stream, outputController.sink),
      processRunner: ProcessRunner(
        processManager: FakeProcessManager(
          onStart: (FakeCommandLogEntry entry) {
            if (entry.command.length == 5 && //
                entry.command[0] == './bin/et' && //
                entry.command[1] == 'build' && //
                entry.command[2] == '-c' && //
                entry.command[3] == 'host_profile_arm64' && //
                entry.command[4] == '//flutter/tools/licenses_cpp') {
              return FakeProcess(stdout: 'Build succeeded');
            } else {
              return FakeProcess(exitCode: 1, stdout: 'Build failed');
            }
          },
        ),
      ),
    );

    final StreamIterator<String> streamIterator = StreamIterator(outputController.stream);

    inputController.add(_initMessage);
    expect(await streamIterator.moveNext(), isTrue);

    const requestJson =
        '{ "jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": { "name": "engine_build", "arguments": { "config": "host_profile_arm64", "target": "//flutter/tools/licenses_cpp"} } }\n';

    inputController.add(requestJson);

    expect(await streamIterator.moveNext(), isTrue);
    final String outputString = streamIterator.current;

    final json = jsonDecode(outputString) as Map<String, dynamic>;

    expect(json['jsonrpc'], equals('2.0'), reason: outputString);
    expect(json['id'], equals(2), reason: outputString);
    expect(json.containsKey('result'), isTrue);
    // ignore: avoid_dynamic_calls
    expect(json['result']['content'][0]['text'], equals('Build succeeded.'), reason: outputString);

    await inputController.close();
    server.shutdown();
  });

  test('list targets', () async {
    final inputController = StreamController<String>();
    final outputController = StreamController<String>();
    final MCPServer server = EngineServer.fromStreamChannel(
      StreamChannel.withCloseGuarantee(inputController.stream, outputController.sink),
      processRunner: ProcessRunner(
        processManager: FakeProcessManager(
          onStart: (FakeCommandLogEntry entry) {
            if (entry.command.length == 3 && //
                entry.command[0] == './third_party/gn/gn' && //
                entry.command[1] == 'ls' && //
                entry.command[2] == '../out/foobar') {
              return FakeProcess(stdout: '//foo\n//bar\n');
            } else {
              return FakeProcess(exitCode: 1, stdout: 'unknown');
            }
          },
        ),
      ),
    );

    final StreamIterator<String> streamIterator = StreamIterator(outputController.stream);

    inputController.add(_initMessage);
    expect(await streamIterator.moveNext(), isTrue);

    const requestJson =
        '{ "jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": { "name": "engine_list_targets", "arguments": { "config": "foobar"} } }\n';

    inputController.add(requestJson);

    expect(await streamIterator.moveNext(), isTrue);
    final String outputString = streamIterator.current;

    final json = jsonDecode(outputString) as Map<String, dynamic>;

    expect(json['jsonrpc'], equals('2.0'), reason: outputString);
    expect(json['id'], equals(2), reason: outputString);
    expect(json.containsKey('result'), isTrue);
    // ignore: avoid_dynamic_calls
    expect(json['result']['content'][0]['text'], equals('//foo\n//bar\n'), reason: outputString);

    await inputController.close();
    server.shutdown();
  });
}
