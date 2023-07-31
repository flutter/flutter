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

library webdriver.core;

import 'dart:async' show Future;
import 'dart:collection' show UnmodifiableMapView;

import 'src/async/web_driver.dart';
import 'src/common/capabilities.dart';
import 'src/common/request_client.dart';
import 'src/common/spec.dart';
import 'src/common/utils.dart';

export 'package:webdriver/src/async/alert.dart';
export 'package:webdriver/src/async/common.dart';
export 'package:webdriver/src/async/cookies.dart';
export 'package:webdriver/src/async/keyboard.dart';
export 'package:webdriver/src/async/logs.dart';
export 'package:webdriver/src/async/mouse.dart';
export 'package:webdriver/src/async/target_locator.dart';
export 'package:webdriver/src/async/timeouts.dart';
export 'package:webdriver/src/async/web_driver.dart';
export 'package:webdriver/src/async/web_element.dart';
export 'package:webdriver/src/async/window.dart';
export 'package:webdriver/src/common/by.dart';
export 'package:webdriver/src/common/capabilities.dart';
export 'package:webdriver/src/common/command_event.dart';
export 'package:webdriver/src/common/cookie.dart';
export 'package:webdriver/src/common/exception.dart';
export 'package:webdriver/src/common/log.dart';
export 'package:webdriver/src/common/mouse.dart';
export 'package:webdriver/src/common/spec.dart';

final Uri defaultUri = Uri.parse('http://127.0.0.1:4444/wd/hub/');

/// Creates a new async WebDriver.
///
/// This is intended for internal use! Please use [createDriver] from
/// async_io.dart or async_html.dart.
Future<WebDriver> createDriver(
    AsyncRequestClient Function(Uri prefix) createRequestClient,
    {Uri? uri,
    Map<String, dynamic>? desired,
    WebDriverSpec spec = WebDriverSpec.Auto}) async {
  uri ??= defaultUri;

  // This client's prefix at root, it has no session prefix in it.
  final client = createRequestClient(uri);

  final handler = getHandler(spec);

  final session = await client.send(
      handler.session.buildCreateRequest(desired: desired),
      handler.session.parseCreateResponse);

  if (session.spec != WebDriverSpec.JsonWire &&
      session.spec != WebDriverSpec.W3c) {
    throw 'Unexpected spec: ${session.spec}';
  }

  return WebDriver(uri, session.id, UnmodifiableMapView(session.capabilities!),
      createRequestClient(uri.resolve('session/${session.id}/')), session.spec);
}

/// Creates an async WebDriver from existing session.
///
/// This is intended for internal use! Please use [fromExistingSession] from
/// async_io.dart or async_html.dart.
Future<WebDriver> fromExistingSession(
    AsyncRequestClient Function(Uri prefix) createRequestClient,
    String sessionId,
    {Uri? uri,
    WebDriverSpec spec = WebDriverSpec.Auto}) async {
  uri ??= defaultUri;

  // This client's prefix at root, it has no session prefix in it.
  final client = createRequestClient(uri);

  final handler = getHandler(spec);

  final session = await client.send(handler.session.buildInfoRequest(sessionId),
      (response) => handler.session.parseInfoResponse(response, sessionId));

  if (session.spec != WebDriverSpec.JsonWire &&
      session.spec != WebDriverSpec.W3c) {
    throw 'Unexpected spec: ${session.spec}';
  }

  return WebDriver(uri, session.id, UnmodifiableMapView(session.capabilities!),
      createRequestClient(uri.resolve('session/${session.id}/')), session.spec);
}

/// Creates an async WebDriver from existing session with a sync function.
///
/// This will be helpful when you can't use async when creating WebDriver. For
/// example in a consctructor.
///
/// This is intended for internal use! Please use [fromExistingSessionSync] from
/// async_io.dart or async_html.dart.
WebDriver fromExistingSessionSync(
    AsyncRequestClient Function(Uri prefix) createRequestClient,
    String sessionId,
    WebDriverSpec spec,
    {Uri? uri,
    Map<String, dynamic>? capabilities}) {
  uri ??= defaultUri;

  capabilities ??= Capabilities.empty;

  if (spec != WebDriverSpec.JsonWire && spec != WebDriverSpec.W3c) {
    throw 'Unexpected spec: $spec';
  }

  return WebDriver(uri, sessionId, UnmodifiableMapView(capabilities),
      createRequestClient(uri.resolve('session/$sessionId/')), spec);
}
