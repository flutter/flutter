import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

Widget boilerplate({ Widget? child, TextDirection textDirection = TextDirection.ltr }) {
  return Localizations(
    locale: const Locale('pt', 'BR'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Directionality(
      textDirection: textDirection,
      child: Material(
        child: child,
      ),
    ),
  );
}
void main(){

  testWidgets('Test semantics of TabPageSelector in pt-BR', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
      initialIndex: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              indicatorWeight: 30.0,
              tabs: const <Widget>[Tab(text: 'TAB1'), Tab(text: 'TAB2')],
            ),
            Flexible(
              child: TabBarView(
                controller: controller,
                children: const <Widget>[Text('PAGE1'), Text('PAGE2')],
              ),
            ),
            Expanded(
              child: TabPageSelector(
                controller: controller
              )
            ),
          ],
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'Guia 1 de 2',
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              label: 'TAB1\nGuia 1 de 2',
              flags: <SemanticsFlag>[SemanticsFlag.isFocusable, SemanticsFlag.isSelected],
              id: 2,
              rect: TestSemantics.fullScreen,
              actions: 1,
            ),
            TestSemantics(
              label: 'TAB2\nGuia 2 de 2',
              flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
              id: 3,
              rect: TestSemantics.fullScreen,
              actions: <SemanticsAction>[SemanticsAction.tap],
            ),
            TestSemantics(
              id: 4,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                  id: 6,
                  rect: TestSemantics.fullScreen,
                  actions: <SemanticsAction>[SemanticsAction.scrollLeft],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 5,
                      rect: TestSemantics.fullScreen,
                      label: 'PAGE1'
                    ),
                  ]
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });
}