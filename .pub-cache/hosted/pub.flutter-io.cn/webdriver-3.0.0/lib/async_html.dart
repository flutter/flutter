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

library webdriver.html;

import 'dart:async' show Future;

import 'async_core.dart' as core
    show createDriver, fromExistingSession, fromExistingSessionSync, WebDriver;
import 'src/common/spec.dart';
import 'src/request/async_xhr_request_client.dart';

export 'package:webdriver/async_core.dart'
    hide createDriver, fromExistingSession, fromExistingSessionSync;
export 'package:webdriver/src/request/async_xhr_request_client.dart';

final Uri defaultUri = Uri.parse('http://127.0.0.1:4444/wd/hub/');

/// Creates a new async WebDriver using [AsyncXhrRequestClient].
///
/// This will bring in dependency on `dart:html`.
/// Note: WebDriver endpoints will be constructed using [resolve] against
/// [uri]. Therefore, if [uri] does not end with a trailing slash, the
/// last path component will be dropped.
Future<core.WebDriver> createDriver(
        {Uri? uri,
        Map<String, dynamic>? desired,
        WebDriverSpec spec = WebDriverSpec.Auto,
        Map<String, String> webDriverHeaders = const {}}) =>
    core.createDriver(
        (prefix) => AsyncXhrRequestClient(prefix, headers: webDriverHeaders),
        uri: uri,
        desired: desired,
        spec: spec);

/// Creates an async WebDriver from existing session using
/// [AsyncXhrRequestClient].
///
/// This will bring in dependency on `dart:html`.
/// Note: WebDriver endpoints will be constructed using [resolve] against
/// [uri]. Therefore, if [uri] does not end with a trailing slash, the
/// last path component will be dropped.
Future<core.WebDriver> fromExistingSession(String sessionId,
        {Uri? uri, WebDriverSpec spec = WebDriverSpec.Auto}) =>
    core.fromExistingSession(
        (prefix) => AsyncXhrRequestClient(prefix), sessionId,
        uri: uri, spec: spec);

/// Creates an async WebDriver from existing session with a sync function using
/// [AsyncXhrRequestClient].
///
/// The function is sync, so all necessary information ([sessionId], [spec],
/// [capabilities]) has to be given. Because otherwise, making a call to
/// WebDriver server will make this function async.
///
/// This will bring in dependency on `dart:html`.
/// Note: WebDriver endpoints will be constructed using [resolve] against
/// [uri]. Therefore, if [uri] does not end with a trailing slash, the
/// last path component will be dropped.
core.WebDriver fromExistingSessionSync(String sessionId, WebDriverSpec spec,
        {Uri? uri, Map<String, dynamic>? capabilities}) =>
    core.fromExistingSessionSync(
        (prefix) => AsyncXhrRequestClient(prefix), sessionId, spec,
        uri: uri, capabilities: capabilities);
