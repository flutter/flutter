// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:node_preamble/preamble.dart' as preamble;
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/stream_channel.dart';
// ignore: deprecated_member_use
import 'package:test_api/backend.dart'
    show Runtime, StackTraceMapper, SuitePlatform;
import 'package:test_core/src/runner/application_exception.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/compiler_pool.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/configuration.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/load_exception.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/package_version.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/customizable_platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/environment.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/platform_helpers.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/runner_suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/errors.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/package_config.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/pair.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/stack_trace_mapper.dart'; // ignore: implementation_imports
import 'package:yaml/yaml.dart';

import '../../util/package_map.dart';
import '../executable_settings.dart';

/// A platform that loads tests in Node.js processes.
class NodePlatform extends PlatformPlugin
    implements CustomizablePlatform<ExecutableSettings> {
  /// The test runner configuration.
  final Configuration _config;

  /// The [CompilerPool] managing active instances of `dart2js`.
  final _compilers = CompilerPool(['-Dnode=true', '--server-mode']);

  /// The temporary directory in which compiled JS is emitted.
  final _compiledDir = createTempDir();

  /// The HTTP client to use when fetching JS files for `pub serve`.
  final HttpClient? _http;

  /// Executable settings for [Runtime.nodeJS] and runtimes that extend
  /// it.
  final _settings = {
    Runtime.nodeJS: ExecutableSettings(
        linuxExecutable: 'node',
        macOSExecutable: 'node',
        windowsExecutable: 'node.exe')
  };

  NodePlatform()
      : _config = Configuration.current,
        _http = Configuration.current.pubServeUrl == null ? null : HttpClient();

  @override
  ExecutableSettings parsePlatformSettings(YamlMap settings) =>
      ExecutableSettings.parse(settings);

  @override
  ExecutableSettings mergePlatformSettings(
          ExecutableSettings settings1, ExecutableSettings settings2) =>
      settings1.merge(settings2);

  @override
  void customizePlatform(Runtime runtime, ExecutableSettings settings) {
    var oldSettings = _settings[runtime] ?? _settings[runtime.root];
    if (oldSettings != null) settings = oldSettings.merge(settings);
    _settings[runtime] = settings;
  }

  @override
  Future<RunnerSuite> load(String path, SuitePlatform platform,
      SuiteConfiguration suiteConfig, Map<String, Object?> message) async {
    var pair = await _loadChannel(path, platform.runtime, suiteConfig);
    var controller = deserializeSuite(
        path, platform, suiteConfig, PluginEnvironment(), pair.first, message);

    controller.channel('test.node.mapper').sink.add(pair.last?.serialize());

    return await controller.suite;
  }

  /// Loads a [StreamChannel] communicating with the test suite at [path].
  ///
  /// Returns that channel along with a [StackTraceMapper] representing the
  /// source map for the compiled suite.
  Future<Pair<StreamChannel<Object?>, StackTraceMapper?>> _loadChannel(
      String path, Runtime runtime, SuiteConfiguration suiteConfig) async {
    final servers = await _loopback();

    try {
      var pair =
          await _spawnProcess(path, runtime, suiteConfig, servers.first.port);
      var process = pair.first;

      // Forward Node's standard IO to the print handler so it's associated with
      // the load test.
      //
      // TODO(nweiz): Associate this with the current test being run, if any.
      process.stdout.transform(lineSplitter).listen(print);
      process.stderr.transform(lineSplitter).listen(print);

      var socket = await StreamGroup.merge(servers).first;
      var channel = StreamChannel(socket.cast<List<int>>(), socket)
          .transform(StreamChannelTransformer.fromCodec(utf8))
          .transform(_chunksToLines)
          .transform(jsonDocument)
          .transformStream(StreamTransformer.fromHandlers(handleDone: (sink) {
        process.kill();
        sink.close();
      }));

      return Pair(channel, pair.last);
    } finally {
      unawaited(Future.wait<void>(servers.map((s) =>
          s.close().then<ServerSocket?>((v) => v).onError((_, __) => null))));
    }
  }

  /// Spawns a Node.js process that loads the Dart test suite at [path].
  ///
  /// Returns that channel along with a [StackTraceMapper] representing the
  /// source map for the compiled suite.
  Future<Pair<Process, StackTraceMapper?>> _spawnProcess(String path,
      Runtime runtime, SuiteConfiguration suiteConfig, int socketPort) async {
    if (_config.suiteDefaults.precompiledPath != null) {
      return _spawnPrecompiledProcess(path, runtime, suiteConfig, socketPort,
          _config.suiteDefaults.precompiledPath!);
    } else if (_config.pubServeUrl != null) {
      return _spawnPubServeProcess(path, runtime, suiteConfig, socketPort);
    } else {
      return _spawnNormalProcess(path, runtime, suiteConfig, socketPort);
    }
  }

  /// Compiles [testPath] with dart2js, adds the node preamble, and then spawns
  /// a Node.js process that loads that Dart test suite.
  Future<Pair<Process, StackTraceMapper?>> _spawnNormalProcess(String testPath,
      Runtime runtime, SuiteConfiguration suiteConfig, int socketPort) async {
    var dir = Directory(_compiledDir).createTempSync('test_').path;
    var jsPath = p.join(dir, '${p.basename(testPath)}.node_test.dart.js');
    await _compilers.compile('''
        ${suiteConfig.metadata.languageVersionComment ?? await rootPackageLanguageVersionComment}
        import "package:test/src/bootstrap/node.dart";

        import "${p.toUri(p.absolute(testPath))}" as test;

        void main() {
          internalBootstrapNodeTest(() => test.main);
        }
      ''', jsPath, suiteConfig);

    // Add the Node.js preamble to ensure that the dart2js output is
    // compatible. Use the minified version so the source map remains valid.
    var jsFile = File(jsPath);
    await jsFile.writeAsString(
        preamble.getPreamble(minified: true) + await jsFile.readAsString());

    StackTraceMapper? mapper;
    if (!suiteConfig.jsTrace) {
      var mapPath = '$jsPath.map';
      mapper = JSStackTraceMapper(await File(mapPath).readAsString(),
          mapUrl: p.toUri(mapPath),
          sdkRoot: Uri.parse('org-dartlang-sdk:///sdk'),
          packageMap: (await currentPackageConfig).toPackageMap());
    }

    return Pair(await _startProcess(runtime, jsPath, socketPort), mapper);
  }

  /// Spawns a Node.js process that loads the Dart test suite at [testPath]
  /// under [precompiledPath].
  Future<Pair<Process, StackTraceMapper?>> _spawnPrecompiledProcess(
      String testPath,
      Runtime runtime,
      SuiteConfiguration suiteConfig,
      int socketPort,
      String precompiledPath) async {
    StackTraceMapper? mapper;
    var jsPath = p.join(precompiledPath, '$testPath.node_test.dart.js');
    if (!suiteConfig.jsTrace) {
      var mapPath = '$jsPath.map';
      mapper = JSStackTraceMapper(await File(mapPath).readAsString(),
          mapUrl: p.toUri(mapPath),
          sdkRoot: Uri.parse('org-dartlang-sdk:///sdk'),
          packageMap: (await findPackageConfig(Directory(precompiledPath)))!
              .toPackageMap());
    }

    return Pair(await _startProcess(runtime, jsPath, socketPort), mapper);
  }

  /// Requests the compiled js for [testPath] from the pub serve url, prepends
  /// the node preamble, and then spawns a Node.js process that loads that Dart
  /// test suite.
  Future<Pair<Process, StackTraceMapper?>> _spawnPubServeProcess(
      String testPath,
      Runtime runtime,
      SuiteConfiguration suiteConfig,
      int socketPort) async {
    var dir = Directory(_compiledDir).createTempSync('test_').path;
    var jsPath = p.join(dir, '${p.basename(testPath)}.node_test.dart.js');
    var url = _config.pubServeUrl!.resolveUri(
        p.toUri('${p.relative(testPath, from: 'test')}.node_test.dart.js'));

    var js = await _get(url, testPath);
    await File(jsPath).writeAsString(preamble.getPreamble(minified: true) + js);

    StackTraceMapper? mapper;
    if (!suiteConfig.jsTrace) {
      var mapUrl = url.replace(path: '${url.path}.map');
      mapper = JSStackTraceMapper(await _get(mapUrl, testPath),
          mapUrl: mapUrl,
          sdkRoot: p.toUri('packages/\$sdk'),
          packageMap: (await currentPackageConfig).toPackagesDirPackageMap());
    }

    return Pair(await _startProcess(runtime, jsPath, socketPort), mapper);
  }

  /// Starts the Node.js process for [runtime] with [jsPath].
  Future<Process> _startProcess(
      Runtime runtime, String jsPath, int socketPort) async {
    var settings = _settings[runtime]!;

    var nodeModules = p.absolute('node_modules');
    var nodePath = Platform.environment['NODE_PATH'];
    nodePath = nodePath == null ? nodeModules : '$nodePath:$nodeModules';

    try {
      return await Process.start(
          settings.executable,
          settings.arguments.toList()
            ..add(jsPath)
            ..add(socketPort.toString()),
          environment: {'NODE_PATH': nodePath});
    } catch (error, stackTrace) {
      await Future<Never>.error(
          ApplicationException(
              'Failed to run ${runtime.name}: ${getErrorMessage(error)}'),
          stackTrace);
    }
  }

  /// Runs an HTTP GET on [url].
  ///
  /// If this fails, throws a [LoadException] for [suitePath].
  Future<String> _get(Uri url, String suitePath) async {
    try {
      var response = await (await _http!.getUrl(url)).close();

      if (response.statusCode != 200) {
        // We don't care about the response body, but we have to drain it or
        // else the process can't exit.
        response.listen(null);

        throw LoadException(
            suitePath,
            'Error getting $url: ${response.statusCode} '
            '${response.reasonPhrase}\n'
            'Make sure "pub serve" is serving the test/ directory.');
      }

      return await utf8.decodeStream(response);
    } on IOException catch (error) {
      var message = getErrorMessage(error);
      if (error is SocketException) {
        message = '${error.osError?.message} '
            '(errno ${error.osError?.errorCode})';
      }

      throw LoadException(
          suitePath,
          'Error getting $url: $message\n'
          'Make sure "pub serve" is running.');
    }
  }

  @override
  Future<void> close() => _closeMemo.runOnce(() async {
        await _compilers.close();

        if (_config.pubServeUrl == null) {
          Directory(_compiledDir).deleteSync(recursive: true);
        } else {
          _http!.close();
        }
      });
  final _closeMemo = AsyncMemoizer<void>();
}

Future<List<ServerSocket>> _loopback({int remainingRetries = 5}) async {
  if (!await _supportsIPv4) {
    return [await ServerSocket.bind(InternetAddress.loopbackIPv6, 0)];
  }

  var v4Server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  if (!await _supportsIPv6) return [v4Server];

  try {
    // Reuse the IPv4 server's port so that if [port] is 0, both servers use
    // the same ephemeral port.
    var v6Server =
        await ServerSocket.bind(InternetAddress.loopbackIPv6, v4Server.port);
    return [v4Server, v6Server];
  } on SocketException catch (error) {
    if (error.osError?.errorCode != _addressInUseErrno) rethrow;
    if (remainingRetries == 0) rethrow;

    // A port being available on IPv4 doesn't necessarily mean that the same
    // port is available on IPv6. If it's not (which is rare in practice),
    // we try again until we find one that's available on both.
    unawaited(v4Server.close());
    return await _loopback(remainingRetries: remainingRetries - 1);
  }
}

/// Whether this computer supports binding to IPv6 addresses.
final Future<bool> _supportsIPv6 = () async {
  try {
    var socket = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
    unawaited(socket.close());
    return true;
  } on SocketException catch (_) {
    return false;
  }
}();

/// Whether this computer supports binding to IPv4 addresses.
final Future<bool> _supportsIPv4 = () async {
  try {
    var socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(socket.close());
    return true;
  } on SocketException catch (_) {
    return false;
  }
}();

/// The error code for an error caused by a port already being in use.
final int _addressInUseErrno = () {
  if (Platform.isWindows) return 10048;
  if (Platform.isMacOS) return 48;
  assert(Platform.isLinux);
  return 98;
}();

/// A [StreamChannelTransformer] that converts a chunked string channel to a
/// line-by-line channel.
///
/// Note that this is only safe for channels whose messages are guaranteed not
/// to contain newlines.
final _chunksToLines = StreamChannelTransformer<String, String>(
    const LineSplitter(),
    StreamSinkTransformer.fromHandlers(
        handleData: (data, sink) => sink.add('$data\n')));
