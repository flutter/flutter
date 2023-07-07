// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library webdriver.sync_core;

import 'dart:collection' show UnmodifiableMapView;

import 'src/common/request_client.dart';
import 'src/common/session.dart';
import 'src/common/spec.dart';
import 'src/common/utils.dart';
import 'src/sync/web_driver.dart' show WebDriver;

export 'package:webdriver/src/common/by.dart';
export 'package:webdriver/src/common/capabilities.dart';
export 'package:webdriver/src/common/command_event.dart';
export 'package:webdriver/src/common/cookie.dart';
export 'package:webdriver/src/common/exception.dart';
export 'package:webdriver/src/common/log.dart';
export 'package:webdriver/src/common/mouse.dart';
export 'package:webdriver/src/common/spec.dart';
export 'package:webdriver/src/sync/alert.dart';
export 'package:webdriver/src/sync/common.dart';
export 'package:webdriver/src/sync/cookies.dart';
export 'package:webdriver/src/sync/keyboard.dart';
export 'package:webdriver/src/sync/logs.dart';
export 'package:webdriver/src/sync/mouse.dart';
export 'package:webdriver/src/sync/target_locator.dart';
export 'package:webdriver/src/sync/timeouts.dart';
export 'package:webdriver/src/sync/web_driver.dart';
export 'package:webdriver/src/sync/web_element.dart';
export 'package:webdriver/src/sync/window.dart';

final Uri defaultUri = Uri.parse('http://127.0.0.1:4444/wd/hub/');

/// Creates a new sync WebDriver.
///
/// This is intended for internal use! Please use [createDriver] from
/// sync_io.dart.
WebDriver createDriver(
    SyncRequestClient Function(Uri prefix) createRequestClient,
    {Uri? uri,
    Map<String, dynamic>? desired,
    WebDriverSpec spec = WebDriverSpec.Auto}) {
  uri ??= defaultUri;

  // This client's prefix at root, it has no session prefix in it.
  final client = createRequestClient(uri);

  final handler = getHandler(spec);

  final session = client.send(
      handler.session.buildCreateRequest(desired: desired),
      handler.session.parseCreateResponse);

  if (session.spec != WebDriverSpec.JsonWire &&
      session.spec != WebDriverSpec.W3c) {
    throw 'Unexpected spec: ${session.spec}';
  }

  return WebDriver(uri, session.id, UnmodifiableMapView(session.capabilities!),
      createRequestClient(uri.resolve('session/${session.id}/')), session.spec);
}

/// Creates a sync WebDriver from existing session.
///
/// This is intended for internal use! Please use [fromExistingSession] from
/// sync_io.dart.
WebDriver fromExistingSession(String sessionId,
    SyncRequestClient Function(Uri prefix) createRequestClient,
    {Uri? uri,
    WebDriverSpec spec = WebDriverSpec.Auto,
    Map<String, dynamic>? capabilities}) {
  uri ??= defaultUri;

  var session = SessionInfo(sessionId, spec, capabilities);

  // Update session info if not all is provided.
  if (spec == WebDriverSpec.Auto || capabilities == null) {
    // This client's prefix at root, it has no session prefix in it.
    final client = createRequestClient(uri);

    final handler = getHandler(spec);

    session = client.send(handler.session.buildInfoRequest(sessionId),
        (response) => handler.session.parseInfoResponse(response, sessionId));
  }

  if (session.spec != WebDriverSpec.JsonWire &&
      session.spec != WebDriverSpec.W3c) {
    throw 'Unexpected spec: ${session.spec}';
  }

  return WebDriver(
      uri,
      session.id,
      UnmodifiableMapView(session.capabilities ?? {}),
      createRequestClient(uri.resolve('session/${session.id}/')),
      session.spec);
}
