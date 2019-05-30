// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/service.dart';
// ignore: implementation_imports
import 'package:dwds/src/chrome_proxy_service.dart' show ChromeProxyService;
import 'package:pedantic/pedantic.dart';
import 'package:vm_service_lib/vm_service_lib.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../convert.dart';

class WebdevVmClient {
  WebdevVmClient(
    this.client,
    this._requestController,
    this._responseController,
  );

  final VmService client;
  final StreamController<Map<String, Object>> _requestController;
  final StreamController<Map<String, Object>> _responseController;

  Future<void> close() async {
    await _requestController.close();
    await _responseController.close();
    client.dispose();
  }

  static Future<WebdevVmClient> create(DebugService debugService) async {
    // Set up hot restart as an extension.
    final StreamController<Map<String, Object>> requestController = StreamController<Map<String, Object>>();
    final StreamController<Map<String, Object>> responseController = StreamController<Map<String, Object>>();
    VmServerConnection(
      requestController.stream,
      responseController.sink,
      debugService.serviceExtensionRegistry,
      debugService.chromeProxyService,
    );
    final VmService client = VmService(
      responseController.stream.map<Object>(jsonEncode),
      (String request) => requestController.sink.add(jsonDecode(request)));
    final ChromeProxyService chromeProxyService = debugService.chromeProxyService;

    client.registerServiceCallback('hotRestart', (Map<String, Object> request) async {
      chromeProxyService.destroyIsolate();
      final WipResponse response = await chromeProxyService.tabConnection.runtime.sendCommand(
        'Runtime.evaluate',
        params: <String, Object>{'expression': r'$dartHotRestart();', 'awaitPromise': true});
      final Map<String, dynamic> exceptionDetails = response.result['exceptionDetails'];
      if (exceptionDetails != null) {
        return <String, Object>{
          'error': <String, Object>{
            'code': -32603,
            'message': exceptionDetails['exception']['description'],
            'data': exceptionDetails,
          }
        };
      } else {
        unawaited(chromeProxyService.createIsolate());
        return <String, Object>{'result': Success().toJson()};
      }
    });
    await client.registerService('hotRestart', 'WebDev');

    return WebdevVmClient(client, requestController, responseController);
  }
}
