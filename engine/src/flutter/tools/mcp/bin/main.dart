import 'dart:async' show Completer;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show Process, ProcessResult;

import 'package:mcp_dart/mcp_dart.dart';

void main() async {
  final McpServer server = McpServer(
    const Implementation(name: 'engine_mcp', version: '1.0.0'),
    options: const ServerOptions(
      capabilities: ServerCapabilities(
        resources: ServerCapabilitiesResources(),
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  server.tool('build_help', description: 'Get help for the building tool and a list of configs.',
      callback: ({Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
    try {
      const String executable = './bin/et';
      final List<String> arguments = ['build', '--help'];
      final ProcessResult result = await Process.run(executable, arguments);
      final String output = result.stdout as String;

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

  server.tool('build',
      description: 'Build an engine target.', //
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
      const String executable = './bin/et';
      final List<String> arguments = ['build', '-c', config];
      if (target != null) {
        arguments.add(target);
      }

      final completer = Completer<void>();
      void streamDone() {
        completer.complete();
      }

      final Process process = await Process.start(executable, arguments);

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
            (String line) {
              // TODO(gaaclarke): We should be sending progress notifications
              // here.  See https://modelcontextprotocol.io/specification/2025-03-26/basic/utilities/progress.
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

  server.connect(StdioServerTransport());
}
