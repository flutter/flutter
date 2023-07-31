// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/src/devtools/client.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late json_rpc.Peer client;
  late DevToolsClient devToolsClient;
  setUp(() {
    final requestController = StreamController<String>();
    final requestStream = requestController.stream;
    final requestSink = requestController.sink;

    final responseController = StreamController<String>();
    final responseStream = responseController.stream;
    final responseSink = responseController.sink;
    client = json_rpc.Peer(StreamChannel(responseStream, requestSink));
    unawaited(client.listen());

    devToolsClient = DevToolsClient(
      stream: requestStream,
      sink: responseSink,
    );
  });

  test('DevToolsClient API', () async {
    var response = await client.sendRequest('connected', {
      'uri': 'http://127.0.0.1:8181',
    });
    expect(response, isNull);
    expect(devToolsClient.hasConnection, true);
    expect(devToolsClient.vmServiceUri, Uri.parse('http://127.0.0.1:8181'));
    expect(devToolsClient.embedded, false);
    expect(devToolsClient.currentPage, isNull);

    response = await client.sendRequest('disconnected');
    expect(response, isNull);
    expect(devToolsClient.hasConnection, false);
    expect(devToolsClient.vmServiceUri, isNull);
    expect(devToolsClient.embedded, false);
    expect(devToolsClient.currentPage, isNull);

    response = await client.sendRequest('currentPage', {
      'id': 'foo',
      'embedded': true,
    });

    expect(response, isNull);
    expect(devToolsClient.hasConnection, false);
    expect(devToolsClient.vmServiceUri, isNull);
    expect(devToolsClient.embedded, true);
    expect(devToolsClient.currentPage, 'foo');

    // TODO: add tests for package:devtools_shared/devtools_server.dart
  });

  test('DevToolsClient notifications', () async {
    final enableNotifications = Completer<void>();
    client.registerMethod(
      'enableNotifications',
      (_) => enableNotifications.complete(),
    );
    devToolsClient.enableNotifications();
    await enableNotifications.future;

    final showPage = Completer<void>();
    String? pageId;
    client.registerMethod('showPage', (parameters) {
      pageId = parameters['page'].asString;
      showPage.complete();
    });
    devToolsClient.showPage('foo');
    await showPage.future;
    expect(pageId, 'foo');

    final connectToVmService = Completer<void>();
    String? uri;
    bool notifyUser = false;
    client.registerMethod('connectToVm', (parameters) {
      uri = parameters['uri'].asString;
      notifyUser = parameters['notify'].asBool;
      connectToVmService.complete();
    });
    devToolsClient.connectToVmService(Uri.parse('http://127.0.0.1:8181'), true);
    await connectToVmService.future;
    expect(uri, 'http://127.0.0.1:8181');
    expect(notifyUser, true);

    final notify = Completer<void>();
    client.registerMethod('notify', (_) => notify.complete());
    devToolsClient.notify();
    await notify.future;
  });
}
