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

import 'dart:async';

import '../common/exception.dart';
import '../common/log.dart';
import '../common/request_client.dart';
import '../common/webdriver_handler.dart';

class Logs {
  final AsyncRequestClient _client;
  final WebDriverHandler _handler;

  Logs(this._client, this._handler);

  Stream<LogEntry> get(String logType) async* {
    try {
      final entries = await _client.send(
          _handler.logs.buildGetLogsRequest(logType),
          _handler.logs.parseGetLogsResponse);
      for (var entry in entries) {
        yield entry;
      }
    } on UnknownCommandException {
      // Produces no entries for Firefox.
    }
  }

  @override
  String toString() => '$_handler.logs($_client)';

  @override
  int get hashCode => _client.hashCode;

  @override
  bool operator ==(other) =>
      other is Logs && _handler == other._handler && _client == other._client;
}
