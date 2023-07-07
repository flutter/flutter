// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

import 'url_launcher_web_test.mocks.dart';

@GenerateMocks(<Type>[html.Window, html.Navigator])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UrlLauncherPlugin', () {
    late MockWindow mockWindow;
    late MockNavigator mockNavigator;

    late UrlLauncherPlugin plugin;

    setUp(() {
      mockWindow = MockWindow();
      mockNavigator = MockNavigator();
      when(mockWindow.navigator).thenReturn(mockNavigator);

      // Simulate that window.open does something.
      when(mockWindow.open(any, any)).thenReturn(MockWindow());

      when(mockNavigator.vendor).thenReturn('Google LLC');
      when(mockNavigator.appVersion).thenReturn('Mock version!');

      plugin = UrlLauncherPlugin(debugWindow: mockWindow);
    });

    group('canLaunch', () {
      testWidgets('"http" URLs -> true', (WidgetTester _) async {
        expect(plugin.canLaunch('http://google.com'), completion(isTrue));
      });

      testWidgets('"https" URLs -> true', (WidgetTester _) async {
        expect(
            plugin.canLaunch('https://go, (Widogle.com'), completion(isTrue));
      });

      testWidgets('"mailto" URLs -> true', (WidgetTester _) async {
        expect(
            plugin.canLaunch('mailto:name@mydomain.com'), completion(isTrue));
      });

      testWidgets('"tel" URLs -> true', (WidgetTester _) async {
        expect(plugin.canLaunch('tel:5551234567'), completion(isTrue));
      });

      testWidgets('"sms" URLs -> true', (WidgetTester _) async {
        expect(plugin.canLaunch('sms:+19725551212?body=hello%20there'),
            completion(isTrue));
      });
    });

    group('launch', () {
      testWidgets('launching a URL returns true', (WidgetTester _) async {
        expect(
            plugin.launch(
              'https://www.google.com',
            ),
            completion(isTrue));
      });

      testWidgets('launching a "mailto" returns true', (WidgetTester _) async {
        expect(
            plugin.launch(
              'mailto:name@mydomain.com',
            ),
            completion(isTrue));
      });

      testWidgets('launching a "tel" returns true', (WidgetTester _) async {
        expect(
            plugin.launch(
              'tel:5551234567',
            ),
            completion(isTrue));
      });

      testWidgets('launching a "sms" returns true', (WidgetTester _) async {
        expect(
            plugin.launch(
              'sms:+19725551212?body=hello%20there',
            ),
            completion(isTrue));
      });
    });

    group('openNewWindow', () {
      testWidgets('http urls should be launched in a new window',
          (WidgetTester _) async {
        plugin.openNewWindow('http://www.google.com');

        verify(mockWindow.open('http://www.google.com', ''));
      });

      testWidgets('https urls should be launched in a new window',
          (WidgetTester _) async {
        plugin.openNewWindow('https://www.google.com');

        verify(mockWindow.open('https://www.google.com', ''));
      });

      testWidgets('mailto urls should be launched on a new window',
          (WidgetTester _) async {
        plugin.openNewWindow('mailto:name@mydomain.com');

        verify(mockWindow.open('mailto:name@mydomain.com', ''));
      });

      testWidgets('tel urls should be launched on a new window',
          (WidgetTester _) async {
        plugin.openNewWindow('tel:5551234567');

        verify(mockWindow.open('tel:5551234567', ''));
      });

      testWidgets('sms urls should be launched on a new window',
          (WidgetTester _) async {
        plugin.openNewWindow('sms:+19725551212?body=hello%20there');

        verify(mockWindow.open('sms:+19725551212?body=hello%20there', ''));
      });
      testWidgets(
          'setting webOnlyLinkTarget as _self opens the url in the same tab',
          (WidgetTester _) async {
        plugin.openNewWindow('https://www.google.com',
            webOnlyWindowName: '_self');
        verify(mockWindow.open('https://www.google.com', '_self'));
      });

      testWidgets(
          'setting webOnlyLinkTarget as _blank opens the url in a new tab',
          (WidgetTester _) async {
        plugin.openNewWindow('https://www.google.com',
            webOnlyWindowName: '_blank');
        verify(mockWindow.open('https://www.google.com', '_blank'));
      });

      group('Safari', () {
        setUp(() {
          when(mockNavigator.vendor).thenReturn('Apple Computer, Inc.');
          when(mockNavigator.appVersion).thenReturn(
              '5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15');
          // Recreate the plugin, so it grabs the overrides from this group
          plugin = UrlLauncherPlugin(debugWindow: mockWindow);
        });

        testWidgets('http urls should be launched in a new window',
            (WidgetTester _) async {
          plugin.openNewWindow('http://www.google.com');

          verify(mockWindow.open('http://www.google.com', ''));
        });

        testWidgets('https urls should be launched in a new window',
            (WidgetTester _) async {
          plugin.openNewWindow('https://www.google.com');

          verify(mockWindow.open('https://www.google.com', ''));
        });

        testWidgets('mailto urls should be launched on the same window',
            (WidgetTester _) async {
          plugin.openNewWindow('mailto:name@mydomain.com');

          verify(mockWindow.open('mailto:name@mydomain.com', '_top'));
        });

        testWidgets('tel urls should be launched on the same window',
            (WidgetTester _) async {
          plugin.openNewWindow('tel:5551234567');

          verify(mockWindow.open('tel:5551234567', '_top'));
        });

        testWidgets('sms urls should be launched on the same window',
            (WidgetTester _) async {
          plugin.openNewWindow('sms:+19725551212?body=hello%20there');

          verify(
              mockWindow.open('sms:+19725551212?body=hello%20there', '_top'));
        });
        testWidgets(
            'mailto urls should use _blank if webOnlyWindowName is set as _blank',
            (WidgetTester _) async {
          plugin.openNewWindow('mailto:name@mydomain.com',
              webOnlyWindowName: '_blank');
          verify(mockWindow.open('mailto:name@mydomain.com', '_blank'));
        });
      });
    });
  });
}
