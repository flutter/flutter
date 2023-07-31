// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'events.dart';
import 'services/chrome_proxy_service.dart' show ChromeProxyService;
import 'services/debug_service.dart';

final _logger = Logger('DwdsVmClient');

// A client of the vm service that registers some custom extensions like
// hotRestart.
class DwdsVmClient {
  final VmService client;
  final StreamController<Map<String, Object>> _requestController;
  final StreamController<Map<String, Object>> _responseController;

  static const int kFeatureDisabled = 100;
  static const String kFeatureDisabledMessage = 'Feature is disabled.';

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void> _closed;

  DwdsVmClient(this.client, this._requestController, this._responseController);

  Future<void> close() => _closed ??= () async {
        await _requestController.close();
        await _responseController.close();
        await client.dispose();
      }();

  static Future<DwdsVmClient> create(
      DebugService debugService, DwdsStats dwdsStats) async {
    // Set up hot restart as an extension.
    final requestController = StreamController<Map<String, Object>>();
    final responseController = StreamController<Map<String, Object>>();
    VmServerConnection(requestController.stream, responseController.sink,
        debugService.serviceExtensionRegistry, debugService.chromeProxyService);
    final client =
        VmService(responseController.stream.map(jsonEncode), (request) {
      if (requestController.isClosed) {
        _logger.warning(
            'Attempted to send a request but the connection is closed:\n\n'
            '$request');
        return;
      }
      requestController.sink.add(jsonDecode(request) as Map<String, dynamic>);
    });
    final chromeProxyService =
        debugService.chromeProxyService as ChromeProxyService;

    // Register '_flutter.listViews' method on the chrome proxy service vm.
    // In native world, this method is provided by the engine, but the web
    // engine is not aware of the VM uri or the isolates.
    //
    // Issue: https://github.com/dart-lang/webdev/issues/1315
    client.registerServiceCallback('_flutter.listViews', (request) async {
      final vm = await chromeProxyService.getVM();
      final isolates = vm.isolates;
      return <String, dynamic>{
        'result': <String, Object>{
          'views': <Object>[
            for (var isolate in isolates)
              <String, Object>{
                'id': isolate.id,
                'isolate': isolate.toJson(),
              }
          ],
        }
      };
    });
    await client.registerService('_flutter.listViews', 'DWDS');

    client.registerServiceCallback(
        'hotRestart',
        (request) => captureElapsedTime(
            () => _hotRestart(chromeProxyService, client),
            (_) => DwdsEvent.hotRestart()));
    await client.registerService('hotRestart', 'DWDS');

    client.registerServiceCallback(
        'fullReload',
        (request) => captureElapsedTime(() => _fullReload(chromeProxyService),
            (_) => DwdsEvent.fullReload()));
    await client.registerService('fullReload', 'DWDS');

    client.registerServiceCallback('ext.dwds.screenshot', (_) async {
      await chromeProxyService.remoteDebugger.enablePage();
      final response = await chromeProxyService.remoteDebugger
          .sendCommand('Page.captureScreenshot');
      return {'result': response.result};
    });
    await client.registerService('ext.dwds.screenshot', 'DWDS');

    client.registerServiceCallback('ext.dwds.sendEvent', (event) async {
      _processSendEvent(event, chromeProxyService, dwdsStats);
      return {'result': Success().toJson()};
    });
    await client.registerService('ext.dwds.sendEvent', 'DWDS');

    client.registerServiceCallback('ext.dwds.emitEvent', (event) async {
      emitEvent(DwdsEvent(
          event['type'] as String, event['payload'] as Map<String, dynamic>));
      return {'result': Success().toJson()};
    });
    await client.registerService('ext.dwds.emitEvent', 'DWDS');

    client.registerServiceCallback('_yieldControlToDDS', (request) async {
      final ddsUri = request['uri'] as String;
      if (ddsUri == null) {
        return RPCError(
          request['method'] as String,
          RPCError.kInvalidParams,
          "'Missing parameter: 'uri'",
        ).toMap();
      }
      return DebugService.yieldControlToDDS(ddsUri)
          ? {'result': Success().toJson()}
          : {
              'error': {
                'code': kFeatureDisabled,
                'message': kFeatureDisabledMessage,
                'details':
                    'Existing VM service clients prevent DDS from taking control.',
              },
            };
    });
    await client.registerService('_yieldControlToDDS', 'DWDS');

    return DwdsVmClient(client, requestController, responseController);
  }
}

void _processSendEvent(Map<String, dynamic> event,
    ChromeProxyService chromeProxyService, DwdsStats dwdsStats) {
  final type = event['type'] as String;
  final payload = event['payload'] as Map<String, dynamic>;
  switch (type) {
    case 'DevtoolsEvent':
      {
        _logger.finest('Received DevTools event: $event');
        final action = payload == null ? null : payload['action'] as String;
        final screen = payload == null ? null : payload['screen'] as String;
        if (action == 'pageReady') {
          if (dwdsStats.isFirstDebuggerReady) {
            if (dwdsStats.devToolsStart != null) {
              final time = DateTime.now()
                  .difference(dwdsStats.devToolsStart)
                  .inMilliseconds;
              emitEvent(DwdsEvent.devToolsLoad(time, screen));
              _logger.fine('DevTools load time: $time ms');
            }
            if (dwdsStats.debuggerStart != null) {
              final time = DateTime.now()
                  .difference(dwdsStats.debuggerStart)
                  .inMilliseconds;
              emitEvent(DwdsEvent.debuggerReady(time, screen));
              _logger.fine('Debugger ready time: $time ms');
            }
          } else {
            _logger
                .finest('Debugger and DevTools startup times alredy recorded.'
                    ' Ignoring $event.');
          }
        } else {
          _logger.finest('Ignoring unknown event: $event');
        }
      }
  }
}

Future<Map<String, dynamic>> _hotRestart(
    ChromeProxyService chromeProxyService, VmService client) async {
  _logger.info('Attempting a hot restart');

  chromeProxyService.terminatingIsolates = true;
  await _disableBreakpointsAndResume(client, chromeProxyService);
  int context;
  try {
    _logger.info('Attempting to get execution context ID.');
    context = await chromeProxyService.executionContext.id;
    _logger.info('Got execution context ID.');
  } on StateError catch (e) {
    // We couldn't find the execution context. `hotRestart` may have been
    // triggered in the middle of a full reload.
    return {
      'error': {
        'code': RPCError.kInternalError,
        'message': e.message,
      }
    };
  }
  // Start listening for isolate create events before issuing a hot
  // restart. Only return success after the isolate has fully started.
  final stream = chromeProxyService.onEvent('Isolate');
  try {
    // Generate run id to hot restart all apps loaded into the tab.
    final runId = const Uuid().v4().toString();
    _logger.info('Issuing \$dartHotRestartDwds request');
    await chromeProxyService.remoteDebugger
        .sendCommand('Runtime.evaluate', params: {
      'expression': '\$dartHotRestartDwds(\'$runId\');',
      'awaitPromise': true,
      'contextId': context,
    });
    _logger.info('\$dartHotRestartDwds request complete.');
  } on WipError catch (exception) {
    final code = exception.error['code'];
    // This corresponds to `Execution context was destroyed` which can
    // occur during a hot restart that must fall back to a full reload.
    if (code != RPCError.kServerError) {
      return {
        'error': {
          'code': exception.error['code'],
          'message': exception.error['message'],
          'data': exception,
        }
      };
    }
  }

  _logger.info('Waiting for Isolate Start event.');
  await stream.firstWhere((event) => event.kind == EventKind.kIsolateStart);
  chromeProxyService.terminatingIsolates = false;

  _logger.info('Successful hot restart');
  return {'result': Success().toJson()};
}

Future<Map<String, dynamic>> _fullReload(
    ChromeProxyService chromeProxyService) async {
  _logger.info('Attempting a full reload');
  await chromeProxyService.remoteDebugger.enablePage();
  await chromeProxyService.remoteDebugger.pageReload();
  _logger.info('Successful full reload');
  return {'result': Success().toJson()};
}

Future<void> _disableBreakpointsAndResume(
    VmService client, ChromeProxyService chromeProxyService) async {
  _logger.info('Attempting to disable breakpoints and resume the isolate');
  final vm = await client.getVM();
  if (vm.isolates.isEmpty) throw StateError('No active isolate to resume.');
  final isolateRef = vm.isolates.first;

  await chromeProxyService.disableBreakpoints();
  try {
    // Any checks for paused status result in race conditions or hangs
    // at this point:
    //
    // - `getIsolate()` and check for status:
    //    the app migth still pause on existing breakpoint.
    //
    // - `pause()` and wait for `Debug.paused` event:
    //   chrome does not send the `Debug.Paused `notification
    //   without shifting focus to chrome.
    //
    // Instead, just try resuming and
    // ignore failures indicating that the app is already running:
    //
    // WipError -32000 Can only perform operation while paused.
    await client.resume(isolateRef.id);
  } on RPCError catch (e, s) {
    if (!e.message.contains('Can only perform operation while paused')) {
      _logger.severe('Hot restart failed to resume exiting isolate', e, s);
      rethrow;
    }
  }
  _logger.info('Successfully disabled breakpoints and resumed the isolate');
}
