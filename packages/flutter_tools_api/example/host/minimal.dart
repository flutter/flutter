// TODO delete

import 'package:flutter_tools_api/flutter_tools_api.dart';

Future<void> main() async {
  final ExtensionsIsolateBootstrap bootstrap = bootstrapFactory(<Extension>[TemplateExtension()]);
  ExtensionClient? extensions;
  try {
    extensions = ExtensionClient(bootstrap);
    await extensions.initialized;
    print('Received: ${await extensions.query(const ListTemplatesRequest())}');
  } finally {
    await extensions?.dispose();
  }
}
