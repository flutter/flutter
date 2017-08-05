// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

Widget buildFrame({
  Locale locale: null,
  LocalizationsDelegate delegate: null,
  WidgetBuilder buildContent,
}) {
  return new WidgetsApp(
    color: const Color(0xFFFFFFFF),
    locale: locale,
    localizationsDelegate: delegate,
    onGenerateRoute: (RouteSettings settings) {
      return new PageRouteBuilder<Null>(
        settings: settings,
        pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
          return buildContent(context);
        }
      );
    },
  );
}

void main() {
  testWidgets('Localizations.of in a WidgetsApp', (WidgetTester tester) async {
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        buildContent: (BuildContext context) {
          pageContext = context;
          return new Text('Hello World');
        }
      )
    );

    expect(Localizations.of<Null>(pageContext, Null), null);

    // Rebuld the frame with a non-null delegate

    // Rebuild the frame with a null delegate again

  });

  testWidgets('Localizations.localeFor in a WidgetsApp with system locale', (WidgetTester tester) async {
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        buildContent: (BuildContext context) {
          pageContext = context;
          return new Text('Hello World');
        }
      )
    );

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();
    expect(Localizations.localeOf(pageContext), const Locale('en', 'GB'));

    await tester.binding.setLocale('en', 'US');
    await tester.pump();
    expect(Localizations.localeOf(pageContext), const Locale('en', 'US'));
  });

  testWidgets('Localizations.localeFor in a WidgetsApp with an explicit locale', (WidgetTester tester) async {
    final Locale locale = const Locale('en', 'US');
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        locale: locale,
        buildContent: (BuildContext context) {
          pageContext = context;
          return new Text('Hello World');
        },
      )
    );

    expect(Localizations.localeOf(pageContext), locale);

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();

    // The WidgetApp's explicit locale overrides the system's locale.
    expect(Localizations.localeOf(pageContext), locale);
  });
}
