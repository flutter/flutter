// packages/flutter/test/widgets/adaptive_button_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/adaptive_button.dart';

void main() {
  testWidgets('AdaptiveButton renders ElevatedButton on Android', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(MaterialApp(
      home: AdaptiveButton(
        child: Text('Click Me'),
        onPressed: () {},
      ),
    ));

    expect(find.byType(ElevatedButton), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('AdaptiveButton renders CupertinoButton on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(CupertinoApp(
      home: AdaptiveButton(
        child: Text('Tap Me'),
        onPressed: () {},
      ),
    ));

    expect(find.byType(CupertinoButton), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
