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

  server.tool(
    'calculate',
    description: 'Perform basic arithmetic operations',
    inputSchemaProperties: {
      'operation': {
        'type': 'string',
        'enum': ['add', 'subtract', 'multiply', 'divide'],
      },
      'a': {'type': 'number'},
      'b': {'type': 'number'},
    },
    callback: ({args, extra}) async {
      final operation = args!['operation'];
      final a = args['a'];
      final b = args['b'];
      return CallToolResult(
        content: [
          TextContent(
            text: switch (operation) {
              'add' => 'Result: ${a + b}',
              'subtract' => 'Result: ${a - b}',
              'multiply' => 'Result: ${a * b}',
              'divide' => 'Result: ${a / b}',
              _ => throw Exception('Invalid operation'),
            },
          ),
        ],
      );
    },
  );

  server.connect(StdioServerTransport());
}
