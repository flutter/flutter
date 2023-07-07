// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('canLaunch', (WidgetTester _) async {
    expect(
        await canLaunchUrl(Uri(scheme: 'randomscheme', path: 'a_path')), false);

    // Generally all devices should have some default browser.
    expect(await canLaunchUrl(Uri(scheme: 'http', host: 'flutter.dev')), true);
    expect(await canLaunchUrl(Uri(scheme: 'https', host: 'flutter.dev')), true);

    // SMS handling is available by default on most platforms.
    if (kIsWeb || !(Platform.isLinux || Platform.isWindows)) {
      expect(await canLaunchUrl(Uri(scheme: 'sms', path: '5555555555')), true);
    }

    // Sanity-check legacy API.
    // ignore: deprecated_member_use
    expect(await canLaunch('randomstring'), false);
    // Generally all devices should have some default browser.
    // ignore: deprecated_member_use
    expect(await canLaunch('https://flutter.dev'), true);
  });
}
