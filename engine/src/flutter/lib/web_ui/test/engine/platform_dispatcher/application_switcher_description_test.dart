// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  String? getCssThemeColor() {
    final theme = domDocument.querySelector('#flutterweb-theme') as DomHTMLMetaElement?;
    return theme?.content;
  }

  const MethodCodec codec = JSONMethodCodec();

  group('Title and Primary Color/Theme meta', () {
    test('is set on the document by platform message', () {
      expect(domDocument.title, '');
      expect(getCssThemeColor(), isNull);

      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(
          const MethodCall('SystemChrome.setApplicationSwitcherDescription', <String, dynamic>{
            'label': 'Title Test',
            'primaryColor': 0xFF00FF00,
          }),
        ),
        null,
      );

      const expectedPrimaryColor = ui.Color(0xFF00FF00);

      expect(domDocument.title, 'Title Test');
      expect(getCssThemeColor(), expectedPrimaryColor.toCssString());

      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(
          const MethodCall('SystemChrome.setApplicationSwitcherDescription', <String, dynamic>{
            'label': 'Different title',
            'primaryColor': 0xFFFABADA,
          }),
        ),
        null,
      );

      const expectedNewPrimaryColor = ui.Color(0xFFFABADA);

      expect(domDocument.title, 'Different title');
      expect(getCssThemeColor(), expectedNewPrimaryColor.toCssString());
    });

    test('supports null title and primaryColor', () {
      const expectedNullColor = ui.Color(0xFF000000);
      // TODO(yjbanov): https://github.com/flutter/flutter/issues/39159
      domDocument.title = 'Something Else';
      expect(domDocument.title, 'Something Else');

      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(
          const MethodCall('SystemChrome.setApplicationSwitcherDescription', <String, dynamic>{
            'label': null,
            'primaryColor': null,
          }),
        ),
        null,
      );

      expect(domDocument.title, '');
      expect(getCssThemeColor(), expectedNullColor.toCssString());

      domDocument.title = 'Something Else';
      expect(domDocument.title, 'Something Else');

      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(
          const MethodCall('SystemChrome.setApplicationSwitcherDescription', <String, dynamic>{}),
        ),
        null,
      );

      expect(domDocument.title, '');
      expect(getCssThemeColor(), expectedNullColor.toCssString());
    });
  });
}
