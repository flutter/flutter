// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@OnPlatform({'windows': Skip('appveyor is not setup to install Chrome')})
import 'dart:async';
import 'dart:io';

import 'package:browser_launcher/src/chrome.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

void main() {
  Chrome? chrome;

  Future<WipConnection> connectToTab(String url) async {
    var tab = await chrome!.chromeConnection.getTab((t) => t.url.contains(url));
    expect(tab, isNotNull);
    return tab!.connect();
  }

  Future<void> openTab(String url) async {
    await chrome!.chromeConnection.getUrl(_openTabUrl(url));
  }

  Future<void> launchChromeWithDebugPort(
      {int port = 0, String? userDataDir, bool signIn = false}) async {
    chrome = await Chrome.startWithDebugPort([_googleUrl],
        debugPort: port, userDataDir: userDataDir, signIn: signIn);
  }

  Future<void> launchChrome() async {
    await Chrome.start([_googleUrl]);
  }

  group('chrome with temp data dir', () {
    tearDown(() async {
      await chrome?.close();
      chrome = null;
    });

    test('can launch chrome', () async {
      await launchChrome();
      expect(chrome, isNull);
    });

    test('can launch chrome with debug port', () async {
      await launchChromeWithDebugPort();
      expect(chrome, isNotNull);
    });

    test('has a working debugger', () async {
      await launchChromeWithDebugPort();
      var tabs = await chrome!.chromeConnection.getTabs();
      expect(
          tabs,
          contains(const TypeMatcher<ChromeTab>()
              .having((t) => t.url, 'url', _googleUrl)));
    });

    test('uses open debug port if provided port is 0', () async {
      await launchChromeWithDebugPort(port: 0);
      expect(chrome!.debugPort, isNot(equals(0)));
    });

    test('can provide a specific debug port', () async {
      var port = await findUnusedPort();
      await launchChromeWithDebugPort(port: port);
      expect(chrome!.debugPort, port);
    });
  });

  group('chrome with user data dir', () {
    late Directory dataDir;

    for (var signIn in [false, true]) {
      group('and signIn = $signIn', () {
        setUp(() {
          dataDir = Directory.systemTemp.createTempSync(_userDataDirName);
        });

        tearDown(() async {
          await chrome?.close();
          chrome = null;

          var attempts = 0;
          while (true) {
            try {
              attempts++;
              await Future.delayed(const Duration(milliseconds: 100));
              dataDir.deleteSync(recursive: true);
              break;
            } catch (_) {
              if (attempts > 3) rethrow;
            }
          }
        });

        test('can launch with debug port', () async {
          await launchChromeWithDebugPort(
              userDataDir: dataDir.path, signIn: signIn);
          expect(chrome, isNotNull);
        });

        test('has a working debugger', () async {
          await launchChromeWithDebugPort(
              userDataDir: dataDir.path, signIn: signIn);
          var tabs = await chrome!.chromeConnection.getTabs();
          expect(
              tabs,
              contains(const TypeMatcher<ChromeTab>()
                  .having((t) => t.url, 'url', _googleUrl)));
        });

        test('has correct profile path', () async {
          await launchChromeWithDebugPort(
              userDataDir: dataDir.path, signIn: signIn);
          await openTab(_chromeVersionUrl);

          var wipConnection = await connectToTab(_chromeVersionUrl);
          var result = await _evaluateExpression(wipConnection.page,
              "document.getElementById('profile_path').textContent");

          expect(result, contains(_userDataDirName));
        });
      });
    }
  });
}

String _openTabUrl(String url) => '/json/new?$url';

Future<String> _evaluateExpression(WipPage page, String expression) async {
  var result = '';
  while (result.isEmpty) {
    await Future.delayed(Duration(milliseconds: 100));
    var wipResponse = await page.sendCommand(
      'Runtime.evaluate',
      params: {'expression': expression},
    );
    var response = wipResponse.json['result'] as Map<String, dynamic>;
    var value = (response['result'] as Map<String, dynamic>)['value'];
    result = (value != null && value is String) ? value : '';
  }
  return result;
}

const _googleUrl = 'https://www.google.com/';
const _chromeVersionUrl = 'chrome://version/';
const _userDataDirName = 'data dir';
