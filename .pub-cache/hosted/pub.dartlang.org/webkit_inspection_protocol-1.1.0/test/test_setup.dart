library wip.test.setup;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:webdriver/io.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

Future<WipConnection>? _wipConnection;

/// Returns a (cached) debugger connection to the first regular tab of
/// the browser with remote debugger running at 'localhost:9222',
Future<WipConnection> get wipConnection {
  _wipConnection ??= () async {
    var debugPort = await _startWebDriver(await _startChromeDriver());
    var chrome = ChromeConnection('localhost', debugPort);
    var tab = (await chrome
        .getTab((tab) => !tab.isBackgroundPage && !tab.isChromeExtension))!;
    var connection = await tab.connect();
    connection.onClose.listen((_) => _wipConnection = null);
    return connection;
  }();
  return _wipConnection!;
}

Process? _chromeDriver;

/// Starts ChromeDriver and returns the listening port.
Future<int> _startChromeDriver() async {
  var chromeDriverPort = await findUnusedPort();

  // Delay a small amount to allow us to close the above port.
  await Future.delayed(const Duration(milliseconds: 25));

  try {
    var exeExt = Platform.isWindows ? '.exe' : '';
    _chromeDriver = await Process.start('chromedriver$exeExt',
        ['--port=$chromeDriverPort', '--url-base=wd/hub']);
    // On windows this takes a while to boot up, wait for the first line
    // of stdout as a signal that it is ready.
    await _chromeDriver!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first;
  } catch (e) {
    throw StateError(
        'Could not start ChromeDriver. Is it installed?\nError: $e');
  }
  return chromeDriverPort;
}

WebDriver? _webDriver;

/// Starts WebDriver and returns the listening debug port.
Future<int> _startWebDriver(int chromeDriverPort) async {
  var debugPort = await findUnusedPort();
  var capabilities = Capabilities.chrome
    ..addAll({
      Capabilities.chromeOptions: {
        'args': ['remote-debugging-port=$debugPort', '--headless']
      }
    });

  await createDriver(
      spec: WebDriverSpec.JsonWire,
      desired: capabilities,
      uri: Uri.parse('http://127.0.0.1:$chromeDriverPort/wd/hub/'));

  return debugPort;
}

/// Returns a port that is probably, but not definitely, not in use.
///
/// This has a built-in race condition: another process may bind this port at
/// any time after this call has returned.
Future<int> findUnusedPort() async {
  int port;
  ServerSocket socket;
  try {
    socket =
        await ServerSocket.bind(InternetAddress.loopbackIPv6, 0, v6Only: true);
  } on SocketException {
    socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  }
  port = socket.port;
  await socket.close();
  return port;
}

Future<Uri>? _testServerUri;

/// Ensures that an HTTP server serving files from 'test/data' has been
/// started and navigates to to [page] using [wipConnection].
/// Return [wipConnection].
Future<WipConnection> navigateToPage(String page) async {
  _testServerUri ??= () async {
    var receivePort = ReceivePort();
    await Isolate.spawn(_startHttpServer, receivePort.sendPort);
    var port = await receivePort.first;
    return Uri.http('localhost:$port', '');
  }();
  await (await wipConnection)
      .page
      .navigate((await _testServerUri)!.resolve(page).toString());
  await Future.delayed(const Duration(seconds: 1));
  return wipConnection;
}

Future _startHttpServer(SendPort sendPort) async {
  var handler = createStaticHandler('test/data');
  var server = await io.serve(handler, InternetAddress.anyIPv4, 0);
  sendPort.send(server.port);
}

Future closeConnection() async {
  if (_wipConnection != null) {
    await _webDriver?.quit(closeSession: true);
    _webDriver = null;
    _chromeDriver?.kill();
    _chromeDriver = null;
    _wipConnection = null;
  }
}
