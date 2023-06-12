// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../utilities/dart_uri.dart';
import '../utilities/sdk_configuration.dart';
import 'expression_compiler.dart';

class _Compiler {
  static final _logger = Logger('ExpressionCompilerService');
  final StreamQueue<dynamic> _responseQueue;
  final ReceivePort _receivePort;
  final SendPort _sendPort;

  Future<void>? _dependencyUpdate;

  _Compiler._(
    this._responseQueue,
    this._receivePort,
    this._sendPort,
  );

  /// Sends [request] on [_sendPort] and returns the next event from the
  /// response stream.
  Future<Map<String, Object>> _send(Map<String, Object> request) async {
    _sendPort.send(request);
    return await _responseQueue.hasNext
        ? await _responseQueue.next as Map<String, Object>
        : {
            'succeeded': false,
            'errors': ['compilation service response stream closed'],
          };
  }

  /// Starts expression compilation service.
  ///
  /// Starts expression compiler worker in an isolate and creates the
  /// expression compilation service that communicates to the worker.
  ///
  /// [sdkConfiguration] describes the locations of SDK files used in
  /// expression compilation (summaries, libraries spec, compiler worker
  /// snapshot).
  ///
  /// [soundNullSafety] indiciates if the compioler should support sound null
  /// safety.
  ///
  /// Performs handshake with the isolate running expression compiler
  /// worker to estabish communication via send/receive ports, returns
  /// the service after the communication is established.
  ///
  /// Users need to stop the service by calling [stop].
  static Future<_Compiler> start(
    String address,
    int port,
    String moduleFormat,
    bool soundNullSafety,
    SdkConfiguration sdkConfiguration,
    bool verbose,
  ) async {
    sdkConfiguration.validate();

    final librariesUri = sdkConfiguration.librariesUri!;
    final workerUri = sdkConfiguration.compilerWorkerUri!;
    final sdkSummaryUri = soundNullSafety
        ? sdkConfiguration.soundSdkSummaryUri!
        : sdkConfiguration.unsoundSdkSummaryUri!;

    final args = [
      '--experimental-expression-compiler',
      '--libraries-file',
      '$librariesUri',
      '--dart-sdk-summary',
      '$sdkSummaryUri',
      '--asset-server-address',
      address,
      '--asset-server-port',
      '$port',
      '--module-format',
      moduleFormat,
      if (verbose) '--verbose',
      soundNullSafety ? '--sound-null-safety' : '--no-sound-null-safety',
    ];

    _logger.info('Starting...');
    _logger.finest('$workerUri ${args.join(' ')}');

    final receivePort = ReceivePort();
    await Isolate.spawnUri(
      workerUri,
      args,
      receivePort.sendPort,
      // Note(annagrin): ddc snapshot is generated with no asserts, so we have
      // to run it unchecked in case the calling isolate is checked, as it
      // happens, for example, when debugging webdev in VSCode or running tests
      // using 'dart run'
      checked: false,
    );

    final responseQueue = StreamQueue(receivePort);
    final sendPort = await responseQueue.next as SendPort;

    final service = _Compiler._(responseQueue, receivePort, sendPort);

    return service;
  }

  Future<bool> updateDependencies(Map<String, ModuleInfo> modules) async {
    final updateCompleter = Completer();
    _dependencyUpdate = updateCompleter.future;

    _logger.info('Updating dependencies...');
    _logger.finest('Dependencies: $modules');

    final response = await _send({
      'command': 'UpdateDeps',
      'inputs': [
        for (var moduleName in modules.keys)
          {
            'path': modules[moduleName]!.fullDillPath,
            'summaryPath': modules[moduleName]!.summaryPath,
            'moduleName': moduleName
          },
      ]
    });
    final result = (response['succeeded'] as bool?) ?? false;
    if (result) {
      _logger.info('Updated dependencies.');
    } else {
      final e = response['exception'];
      final s = response['stackTrace'];
      _logger.severe('Failed to update dependencies: $e:$s');
    }
    updateCompleter.complete();
    return result;
  }

  Future<ExpressionCompilationResult> compileExpressionToJs(
    String isolateId,
    String libraryUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  ) async {
    _logger.finest('Waiting for dependencies to update');
    if (_dependencyUpdate == null) {
      _logger
          .warning('Dependencies are not updated before compiling expressions');
      return ExpressionCompilationResult('<compiler is not ready>', true);
    }

    await _dependencyUpdate;

    _logger.finest('Compiling "$expression" at $libraryUri:$line');

    final response = await _send({
      'command': 'CompileExpression',
      'expression': expression,
      'line': line,
      'column': column,
      'jsModules': jsModules,
      'jsScope': jsFrameValues,
      'libraryUri': libraryUri,
      'moduleName': moduleName,
    });

    final errors = response['errors'] as List<String>?;
    final e = response['exception'];
    final s = response['stackTrace'];
    final error = (errors != null && errors.isNotEmpty)
        ? errors.first
        : (e != null ? '$e:$s' : '<unknown error>');
    final procedure = response['compiledProcedure'] as String;
    final succeeded = (response['succeeded'] as bool?) ?? false;
    final result = succeeded ? procedure : error;

    if (succeeded) {
      _logger.finest('Compiled "$expression" to: $result');
    } else {
      _logger.finest('Failed to compile "$expression": $result');
    }
    return ExpressionCompilationResult(result, !succeeded);
  }

  /// Stops the service.
  ///
  /// Terminates the isolate running expression compiler worker
  /// and marks the service as stopped.
  Future<void> stop() async {
    _sendPort.send({'command': 'Shutdown'});
    _receivePort.close();
    _logger.info('Stopped.');
  }
}

/// Service that handles expression compilation requests.
///
/// Expression compiler service spawns a dartdevc in expression compilation
/// mode in an isolate and communicates with the isolate via send/receive
/// ports. It also handles full dill file read requests from the isolate
/// and redirects them to the asset server.
///
/// Uses [_address] and [_port] to communicate and [_assetHandler] to
/// redirect asset requests to the asset server.
///
/// Configuration created by [_sdkConfigurationProvider] describes the
/// locations of SDK files used in expression compilation (summaries,
/// libraries spec, compiler worker snapshot).
///
/// Users need to stop the service by calling [stop].
class ExpressionCompilerService implements ExpressionCompiler {
  final _logger = Logger('ExpressionCompilerService');
  final _compiler = Completer<_Compiler>();
  final String _address;
  final FutureOr<int> _port;
  final Handler _assetHandler;
  final bool _verbose;

  final SdkConfigurationProvider _sdkConfigurationProvider;

  ExpressionCompilerService(this._address, this._port, this._assetHandler,
      {bool verbose = false,
      SdkConfigurationProvider? sdkConfigurationProvider})
      : _verbose = verbose,
        _sdkConfigurationProvider =
            sdkConfigurationProvider ?? DefaultSdkConfigurationProvider();

  @override
  Future<ExpressionCompilationResult> compileExpressionToJs(
          String isolateId,
          String libraryUri,
          int line,
          int column,
          Map<String, String> jsModules,
          Map<String, String> jsFrameValues,
          String moduleName,
          String expression) async =>
      (await _compiler.future).compileExpressionToJs(isolateId, libraryUri,
          line, column, jsModules, jsFrameValues, moduleName, expression);

  @override
  Future<void> initialize(
      {required String moduleFormat, bool soundNullSafety = false}) async {
    if (_compiler.isCompleted) return;

    final compiler = await _Compiler.start(
      _address,
      await _port,
      moduleFormat,
      soundNullSafety,
      await _sdkConfigurationProvider.configuration,
      _verbose,
    );

    _compiler.complete(compiler);
  }

  @override
  Future<bool> updateDependencies(Map<String, ModuleInfo> modules) async =>
      (await _compiler.future).updateDependencies(modules);

  Future<void> stop() async {
    if (_compiler.isCompleted) return (await _compiler.future).stop();
  }

  /// Handles resource requests from expression compiler worker.
  ///
  /// Handles REST get requests of the form:
  /// http://host:port/getResource?uri=<resource uri>
  ///
  /// Where the resource uri can be a package Uri for a dart file
  /// or a server path for a full dill file.
  /// Translates given resource uri to a server path and redirects
  /// the request to the asset handler.
  FutureOr<Response> handler(Request request) async {
    final uri = request.requestedUri.queryParameters['uri'];
    try {
      final query = request.requestedUri.path;
      _logger.finest('request: ${request.method} ${request.requestedUri}');

      if (query != '/getResource' || uri == null) {
        return Response.notFound(uri);
      }

      if (!uri.endsWith('.dart') && !uri.endsWith('.dill')) {
        return Response.notFound(uri);
      }

      var serverPath = uri;
      if (uri.endsWith('.dart')) {
        serverPath = DartUri(uri).serverPath;
      }

      _logger.finest('serverpath for $uri: $serverPath');

      request = Request(
        request.method,
        Uri(
          scheme: request.requestedUri.scheme,
          host: request.requestedUri.host,
          port: request.requestedUri.port,
          path: serverPath,
        ),
        protocolVersion: request.protocolVersion,
        context: request.context,
        headers: request.headers,
        handlerPath: request.handlerPath,
        encoding: request.encoding,
      );

      return await _assetHandler(request);
    } catch (e, s) {
      _logger.severe('Error loading $uri', e, s);
      rethrow;
    }
  }
}
