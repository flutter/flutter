// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'With enabled, MediaQueryRefreshMode rebuilds subtree when parent MediaQueryData is change',
          (WidgetTester tester) async {
        int buildCount = 0;
        final Widget child = Builder(builder: (BuildContext context) {
          buildCount++;
          MediaQuery.of(context);
          return const Placeholder();
        });

        final Widget firstTestWidget = MediaQuery(
          data: const MediaQueryData(),
          child: MediaQueryRefreshMode(
            child: child,
          ),
        );

        await tester.pumpWidget(firstTestWidget);
        expect(buildCount, equals(1));

        final Widget secondTestWidget = MediaQuery(
          data: const MediaQueryData(size: Size(100, 100)),
          child: MediaQueryRefreshMode(
            child: child,
          ),
        );

        await tester.pumpWidget(secondTestWidget);
        expect(buildCount, equals(2));
      });

  testWidgets(
      'With disabled, MediaQueryRefreshMode will not rebuilds subtree when parent MediaQueryData is change',
          (WidgetTester tester) async {
        int buildCount = 0;
        final Widget child = Builder(builder: (BuildContext context) {
          buildCount++;
          MediaQuery.of(context);
          return const Placeholder();
        });

        final Widget firstTestWidget = MediaQuery(
          data: const MediaQueryData(),
          child: MediaQueryRefreshMode(
            enabled: false,
            child: child,
          ),
        );

        await tester.pumpWidget(firstTestWidget);
        expect(buildCount, equals(1));

        final Widget secondTestWidget = MediaQuery(
          data: const MediaQueryData(size: Size(100, 100)),
          child: MediaQueryRefreshMode(
            enabled: false,
            child: child,
          ),
        );

        await tester.pumpWidget(secondTestWidget);
        expect(buildCount, equals(1));
      });

  testWidgets(
      'With disabled first and enabled later, '
          'MediaQueryRefreshMode will rebuilds subtree when parent MediaQueryData is change',
          (WidgetTester tester) async {
        int buildCount = 0;
        final Widget child = Builder(builder: (BuildContext context) {
          buildCount++;
          MediaQuery.of(context);
          return const Placeholder();
        });

        final Widget firstTestWidget = MediaQuery(
          data: const MediaQueryData(),
          child: MediaQueryRefreshMode(
            enabled: false,
            child: child,
          ),
        );

        await tester.pumpWidget(firstTestWidget);
        expect(buildCount, equals(1));

        final Widget secondTestWidget = MediaQuery(
          data: const MediaQueryData(size: Size(100, 100)),
          child: MediaQueryRefreshMode(
            child: child,
          ),
        );

        await tester.pumpWidget(secondTestWidget);
        expect(buildCount, equals(2));
      });

  testWidgets(
      'With enabled first and disabled later, '
          'MediaQueryRefreshMode will not rebuilds subtree when parent MediaQueryData is change',
          (WidgetTester tester) async {
        int buildCount = 0;
        final Widget child = Builder(builder: (BuildContext context) {
          buildCount++;
          MediaQuery.of(context);
          return const Placeholder();
        });

        final Widget firstTestWidget = MediaQuery(
          data: const MediaQueryData(),
          child: MediaQueryRefreshMode(
            child: child,
          ),
        );

        await tester.pumpWidget(firstTestWidget);
        expect(buildCount, equals(1));

        final Widget secondTestWidget = MediaQuery(
          data: const MediaQueryData(size: Size(100, 100)),
          child: MediaQueryRefreshMode(
            enabled: false,
            child: child,
          ),
        );

        await tester.pumpWidget(secondTestWidget);
        expect(buildCount, equals(1));
      });
}
