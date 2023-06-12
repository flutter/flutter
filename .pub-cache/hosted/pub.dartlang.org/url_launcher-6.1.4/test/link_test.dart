// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/src/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'mocks/mock_url_launcher_platform.dart';

void main() {
  late MockUrlLauncher mock;

  setUp(() {
    mock = MockUrlLauncher();
    UrlLauncherPlatform.instance = mock;
  });

  group('Link', () {
    testWidgets('handles null uri correctly', (WidgetTester tester) async {
      bool isBuilt = false;
      FollowLink? followLink;

      final Link link = Link(
        uri: null,
        builder: (BuildContext context, FollowLink? followLink2) {
          isBuilt = true;
          followLink = followLink2;
          return Container();
        },
      );
      await tester.pumpWidget(link);

      expect(link.isDisabled, isTrue);
      expect(isBuilt, isTrue);
      expect(followLink, isNull);
    });

    testWidgets('calls url_launcher for external URLs with blank target',
        (WidgetTester tester) async {
      FollowLink? followLink;

      await tester.pumpWidget(Link(
        uri: Uri.parse('http://example.com/foobar'),
        target: LinkTarget.blank,
        builder: (BuildContext context, FollowLink? followLink2) {
          followLink = followLink2;
          return Container();
        },
      ));

      mock
        ..setLaunchExpectations(
          url: 'http://example.com/foobar',
          launchMode: PreferredLaunchMode.externalApplication,
          universalLinksOnly: false,
          enableJavaScript: true,
          enableDomStorage: true,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      await followLink!();
      expect(mock.canLaunchCalled, isTrue);
      expect(mock.launchCalled, isTrue);
    });

    testWidgets('calls url_launcher for external URLs with self target',
        (WidgetTester tester) async {
      FollowLink? followLink;

      await tester.pumpWidget(Link(
        uri: Uri.parse('http://example.com/foobar'),
        target: LinkTarget.self,
        builder: (BuildContext context, FollowLink? followLink2) {
          followLink = followLink2;
          return Container();
        },
      ));

      mock
        ..setLaunchExpectations(
          url: 'http://example.com/foobar',
          launchMode: PreferredLaunchMode.inAppWebView,
          universalLinksOnly: false,
          enableJavaScript: true,
          enableDomStorage: true,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      await followLink!();
      expect(mock.canLaunchCalled, isTrue);
      expect(mock.launchCalled, isTrue);
    });

    testWidgets('pushes to framework for internal route names',
        (WidgetTester tester) async {
      final Uri uri = Uri.parse('/foo/bar');
      FollowLink? followLink;

      await tester.pumpWidget(MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Link(
                uri: uri,
                builder: (BuildContext context, FollowLink? followLink2) {
                  followLink = followLink2;
                  return Container();
                },
              ),
          '/foo/bar': (BuildContext context) => Container(),
        },
      ));

      bool frameworkCalled = false;
      final Future<ByteData> Function(Object?, String) originalPushFunction =
          pushRouteToFrameworkFunction;
      pushRouteToFrameworkFunction = (Object? _, String __) {
        frameworkCalled = true;
        return Future<ByteData>.value(ByteData(0));
      };

      await followLink!();

      // Shouldn't use url_launcher when uri is an internal route name.
      expect(mock.canLaunchCalled, isFalse);
      expect(mock.launchCalled, isFalse);

      // A route should have been pushed to the framework.
      expect(frameworkCalled, true);

      // Restore the original function.
      pushRouteToFrameworkFunction = originalPushFunction;
    });
  });
}
