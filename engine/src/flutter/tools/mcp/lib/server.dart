// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Completer;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show Process;

import 'package:mcp_dart/mcp_dart.dart';
import 'package:process_runner/process_runner.dart';

McpServer makeServer({ProcessRunner? processRunner}) {
  processRunner ??= ProcessRunner();
  final McpServer server = McpServer(
    const Implementation(name: 'engine_mcp', version: '1.0.0'),
    options: const ServerOptions(
      capabilities: ServerCapabilities(
        resources: ServerCapabilitiesResources(),
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  server.tool('engine_build_help',
      description: 'Get help for the building tool and a list of configs.',
      callback: ({Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
    try {
      final List<String> arguments = ['./bin/et', 'build', '--help'];
      final ProcessRunnerResult result = await processRunner!.runProcess(arguments);
      final String output = result.stdout;

      return CallToolResult(
        content: [
          TextContent(
            text: output,
          ),
        ],
      );
    } catch (ex) {
      return CallToolResult.fromContent(content: [TextContent(text: ex.toString())], isError: true);
    }
  });

  server.tool(
    'engine_list_targets',
    description: 'Lists build targets for a given config.', //
    inputSchemaProperties: {
      'config': {
        'type': 'string',
        'enum': ['host_debug_unopt', 'host_debug_unopt_arm64'],
      },
    }, //
    callback: ({Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
      try {
        final String config = args!['config'] as String;
        final List<String> arguments = ['./third_party/gn/gn', 'ls', '../out/$config'];

        final ProcessRunnerResult result = await processRunner!.runProcess(arguments);
        final String output = result.stdout;

        return CallToolResult(
          content: [
            TextContent(
              text: output,
            ),
          ],
        );
      } catch (err) {
        return CallToolResult(
          isError: true,
          content: [
            TextContent(
              text: err.toString(),
            ),
          ],
        );
      }
    },
  );

  server.tool('engine_build',
      description: 'Build an engine target. This is potentially a long running process.', //
      inputSchemaProperties: {
        'config': {'type': 'string'},
        'target': {
          'type': 'string',
          'description': 'The specific target to build (optional).',
        },
      }, //
      callback: ({Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
    try {
      final String config = args!['config'] as String;
      final String? target = args['target'] as String?;
      final List<String> arguments = ['./bin/et', 'build', '-c', config];
      if (target != null) {
        arguments.add(target);
      }

      final completer = Completer<void>();
      void streamDone() {
        completer.complete();
      }

      final Process process = await processRunner!.processManager.start(arguments);

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
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
        return CallToolResult(
          content: [
            const TextContent(
              text: 'Build succeeded.',
            ),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            const TextContent(
              text: 'Build failed.',
            ),
          ],
        );
      }
    } catch (ex) {
      return CallToolResult.fromContent(content: [TextContent(text: ex.toString())], isError: true);
    }
  });

  return server;
}
