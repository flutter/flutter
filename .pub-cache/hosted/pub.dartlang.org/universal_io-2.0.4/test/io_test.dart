// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library main_test;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'helpers_impl_default.dart'
    if (dart.library.html) 'helpers_impl_browser.dart';

part 'src/file.dart';
part 'src/http_client.dart';
part 'src/internet_address.dart';
part 'src/platform.dart';

var serverPort = -1;
var secureServerPort = -1;

void main() {
  setUpAll(() async {
    final channel = spawnHybridUri('server.dart', message: {});
    final streamQueue = StreamQueue(channel.stream);
    serverPort = ((await streamQueue.next) as num).toInt();
    secureServerPort = ((await streamQueue.next) as num).toInt();

    addTearDown(() {
      channel.sink.close();
      streamQueue.cancel();
    });
  });

  group('Chrome', () {
    _testFile();
    _testInternetAddress();
    _testPlatform();
    _testHttpClient(isBrowser: true);
  }, testOn: 'chrome');

  group('VM:', () {
    _testFile();
    _testInternetAddress();
    _testPlatform();
    _testHttpClient(isBrowser: false);
  }, testOn: 'vm');


  group('Node.JS', () {
    _testFile();
    _testInternetAddress();
    _testPlatform();
  }, testOn: 'node');
}