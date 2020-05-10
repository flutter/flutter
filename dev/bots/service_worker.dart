import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/browser.dart';
import 'package:meta/meta.dart';

/// This server runs a release web application and verifies that the service worker
/// caches files correctly, by checking the request resources over HTTP.
///
/// When it receives a request for `CLOSE` the server will be torn down.
///
/// Expects a path to the `build/web` directory produced from `flutter build web`.
Future<void> runRecordingServer({
  @required String appUrl,
  @required String appDirectory,
  @required List<Uri> requests,
  @required List<Map<String, String>> headers,
  int serverPort = 8080,
  int browserDebugPort = 8081,
}) async {
  Chrome chrome;
  HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
    final Completer<void> completer = Completer<void>();
    server.listen((HttpRequest request) async {
      if (request.uri.toString().contains('CLOSE')) {
        await server.close(force: true);
      }
      final Uri recordedUri = Directory(appDirectory).uri.resolveUri(request.uri);
      request.response.write(File(recordedUri.toFilePath()).readAsBytesSync());
      requests.add(request.uri);
      headers.add(headersToMap(request.headers));
      await request.response.close();
    });
    final Directory userDataDirectory = Directory.systemTemp.createTempSync('chrome_user_data_');
    chrome = await Chrome.launch(ChromeOptions(
      headless: true,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
      windowHeight: 500,
      windowWidth: 500,
    ), onError: completer.completeError);
    return completer.future;
  } finally {
    chrome?.stop();
    await server?.close();
  }
}

Map<String, String> headersToMap(HttpHeaders httpHeaders) {
  final Map<String, String> headers = <String, String>{};
  httpHeaders.forEach((String key, List<String> value) {
    headers[key] = value.join(',');
  });
  return headers;
}
