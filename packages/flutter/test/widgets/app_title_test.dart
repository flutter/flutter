// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

const Color kTitleColor = Color(0xFF333333);
const String kTitleString = 'Hello World';

Future<void> pumpApp(WidgetTester tester, { GenerateAppTitle? onGenerateTitle }) async {
  await tester.pumpWidget(
    WidgetsApp(
      supportedLocales: const <Locale>[
        Locale('en', 'US'),
        Locale('en', 'GB'),
      ],
      title: kTitleString,
      color: kTitleColor,
      onGenerateTitle: onGenerateTitle,
      onGenerateRoute: (RouteSettings settings) {
        return PageRouteBuilder<void>(
          pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
            return Container();
          }
        );
      },
    ),
  );
}

void main() {
  testWidgets('Specified title and color are used to build a Title', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(tester.widget<Title>(find.byType(Title)).title, kTitleString);
    expect(tester.widget<Title>(find.byType(Title)).color, kTitleColor);
  });

  testWidgets('onGenerateTitle handles changing locales', (WidgetTester tester) async {
    String generateTitle(BuildContext context) {
      return Localizations.localeOf(context).toString();
    }

    await pumpApp(tester, onGenerateTitle: generateTitle);
    expect(tester.widget<Title>(find.byType(Title)).title, 'en_US');
    expect(tester.widget<Title>(find.byType(Title)).color, kTitleColor);

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();
    expect(tester.widget<Title>(find.byType(Title)).title, 'en_GB');
    expect(tester.widget<Title>(find.byType(Title)).color, kTitleColor);

    // Not a supported locale, so we switch to supportedLocales[0], en_US
    await tester.binding.setLocale('fr', 'CA');
    await tester.pump();
    expect(tester.widget<Title>(find.byType(Title)).title, 'en_US');
    expect(tester.widget<Title>(find.byType(Title)).color, kTitleColor);
  });

}
