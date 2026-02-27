// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Completer, FutureOr;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show Process;

import 'package:dart_mcp/server.dart';
import 'package:process_runner/process_runner.dart';

/// An [MCPServer] that provides tools an agent would need to develop the
/// Flutter engine.
final class EngineServer extends MCPServer with ToolsSupport {
  /// Create an [EngineServer] that is communicating over [stream].
  /// [processRunner] can be supplied for testing, to mock out subprocesses.
  EngineServer.fromStreamChannel(super.stream, {ProcessRunner? processRunner})
    : _processRunner = processRunner ?? ProcessRunner(),
      super.fromStreamChannel(
        implementation: Implementation(name: 'engine mcp', version: '0.0.1'),
        instructions: '',
      );

  final ProcessRunner _processRunner;

  final _engineBuildHelp = Tool(
    name: 'engine_build_help',
    description: 'Get help for the building tool and a list of configs.',
    inputSchema: Schema.object(),
    annotations: ToolAnnotations(readOnlyHint: true),
  );

  final _engineBuild = Tool(
    name: 'engine_build',
    description: 'Build an engine target. This is potentially a long running process.',
    inputSchema: Schema.object(
      properties: {
        'config': Schema.string(description: 'The config to build.'),
        'target': Schema.string(description: 'The specific target to build (optional).'),
      },
    ),
    annotations: ToolAnnotations(readOnlyHint: true),
  );

  final _engineListTargets = Tool(
    name: 'engine_list_targets',
    description: 'Lists build targets for a given config.',
    inputSchema: Schema.object(
      properties: {'config': Schema.string(description: 'The build config to query.')},
    ),
    annotations: ToolAnnotations(readOnlyHint: true),
  );

  Future<CallToolResult> _doEngineListTargets(CallToolRequest request) async {
    try {
      final config = request.arguments!['config'] as String?;
      final arguments = <String>['./third_party/gn/gn', 'ls', '../out/$config'];

      final ProcessRunnerResult result = await _processRunner.runProcess(arguments);
      final String output = result.stdout;

      return CallToolResult(content: [TextContent(text: output)]);
    } catch (err) {
      return CallToolResult(isError: true, content: [TextContent(text: err.toString())]);
    }
  }

  Future<CallToolResult> _doEngineBuildHelp(CallToolRequest request) async {
    try {
      final arguments = <String>['./bin/et', 'build', '--help'];
      final ProcessRunnerResult result = await _processRunner.runProcess(arguments);
      final String output = result.stdout;

      return CallToolResult(content: [TextContent(text: output)]);
    } catch (ex) {
      return CallToolResult(isError: true, content: [TextContent(text: ex.toString())]);
    }
  }

  Future<CallToolResult> _doEngineBuild(CallToolRequest request) async {
    try {
      final config = request.arguments!['config'] as String?;
      final target = request.arguments!['target'] as String?;
      final List<String> arguments = ['./bin/et', 'build', '-c', config!];
      if (target != null) {
        arguments.add(target);
      }

      final completer = Completer<void>();
      void streamDone() {
        completer.complete();
      }

      final Process process = await _processRunner.processManager.start(arguments);

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (String line) {
              // TODO(gaaclarke): We should be sending progress notifications
              // here. See https://modelcontextprotocol.io/specification/2025-03-26/basic/utilities/progress.
            },
            onDone: streamDone,
            onError: (error) {
              streamDone();
            },
          );

      final int exitCode = await process.exitCode;
      await completer.future;

      if (exitCode == 0) {
        return CallToolResult(content: [TextContent(text: 'Build succeeded.')]);
      } else {
        return CallToolResult(content: [TextContent(text: 'Build failed.')]);
      }
    } catch (ex) {
      return CallToolResult(isError: true, content: [TextContent(text: ex.toString())]);
    }
  }

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) {
    registerTool(_engineBuildHelp, _doEngineBuildHelp);
    registerTool(_engineBuild, _doEngineBuild);
    registerTool(_engineListTargets, _doEngineListTargets);
    return super.initialize(request);
  }
}
