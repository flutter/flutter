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

library webdriver.sync_io;

import 'src/request/sync_http_request_client.dart';

import 'sync_core.dart' as core
    show createDriver, fromExistingSession, WebDriver, WebDriverSpec;

export 'package:webdriver/sync_core.dart'
    hide createDriver, fromExistingSession;

/// Creates a new sync WebDriver using [SyncHttpRequestClient].
///
/// This will bring in dependency on `dart:io`.
/// Note: WebDriver endpoints will be constructed using [resolve] against
/// [uri]. Therefore, if [uri] does not end with a trailing slash, the
/// last path component will be dropped.
core.WebDriver createDriver(
        {Uri? uri,
        Map<String, dynamic>? desired,
        core.WebDriverSpec spec = core.WebDriverSpec.Auto,
        Map<String, String> webDriverHeaders = const {}}) =>
    core.createDriver(
        (prefix) => SyncHttpRequestClient(prefix, headers: webDriverHeaders),
        uri: uri,
        desired: desired,
        spec: spec);

/// Creates a sync WebDriver from existing session using
/// [SyncHttpRequestClient].
///
/// It will not make a call to WebDriver server if both [spec] (other than
/// [core.WebDriverSpec.Auto]) and [capabilities] are provided (empty is fine).
/// Otherwise, [capabilities] will be ignored.
///
/// This will bring in dependency on `dart:io`.
/// Note: WebDriver endpoints will be constructed using [resolve] against
/// [uri]. Therefore, if [uri] does not end with a trailing slash, the
/// last path component will be dropped.
core.WebDriver fromExistingSession(String sessionId,
        {Uri? uri,
        core.WebDriverSpec spec = core.WebDriverSpec.Auto,
        Map<String, dynamic>? capabilities}) =>
    core.fromExistingSession(
        sessionId, (prefix) => SyncHttpRequestClient(prefix),
        uri: uri, spec: spec, capabilities: capabilities);
