// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void main() {
  late SpyStringValueNotifier valueListenable;
  late Widget textBuilderUnderTest;
  late int rebuildCount;

  Widget builderForValueListenable(
    ValueListenable<String?> valueListenable,
  ) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<String?>(
        valueListenable: valueListenable,
        builder: (BuildContext context, String? value, Widget? child) {
          rebuildCount += 1;

          if (value == null)
            return const Placeholder();
          return Text(value);
        },
      ),
    );
  }

  setUp(() {
    valueListenable = SpyStringValueNotifier(null);
    textBuilderUnderTest = builderForValueListenable(valueListenable);
    rebuildCount = 0;
  });

  testWidgets('Null value is ok', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('Widget builds with initial value', (WidgetTester tester) async {
    valueListenable = SpyStringValueNotifier('Bachman');

    await tester.pumpWidget(builderForValueListenable(valueListenable));

    expect(find.text('Bachman'), findsOneWidget);
  });

  testWidgets('Widget updates when value changes', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    valueListenable.value = 'Dinesh';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Dinesh'), findsOneWidget);
  });

  testWidgets('Widget does not rebuilds if value is the same', (WidgetTester tester) async {
    const Duration duration = Duration(milliseconds: 100);
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: duration,
    )..value = 0;
    final Animation<String> animation = TweenSequence<String>(<TweenSequenceItem<String>>[
      TweenSequenceItem<String>(tween: ConstantTween<String>('Gilfoyle'), weight: 1.0),
      TweenSequenceItem<String>(tween: ConstantTween<String>('Dinesh'), weight: 1.0),
    ]).animate(controller);

    final Finder finder1 = find.text('Gilfoyle');
    final Finder finder2 = find.text('Dinesh');

    await tester.pumpWidget(builderForValueListenable(animation));

    await tester.pump();
    expect(finder1, findsOneWidget);
    expect(finder2, findsNothing);
    expect(rebuildCount, equals(1));

    controller.value = 0.3;
    await tester.pump();
    expect(finder1, findsOneWidget);
    expect(finder2, findsNothing);
    expect(rebuildCount, equals(1));

    controller.animateTo(0.6);
    await tester.pumpAndSettle(duration);
    expect(finder1, findsNothing);
    expect(finder2, findsOneWidget);
    expect(rebuildCount, equals(2));

    controller.forward();
    await tester.pumpAndSettle(duration);
    expect(finder1, findsNothing);
    expect(finder2, findsOneWidget);
    expect(rebuildCount, equals(2));
  });

  testWidgets('Can change listenable', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    final ValueListenable<String?> differentListenable =
        SpyStringValueNotifier('Hendricks');

    await tester.pumpWidget(builderForValueListenable(differentListenable));

    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Hendricks'), findsOneWidget);
  });

  testWidgets('Stops listening to old listenable after chainging listenable', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    final ValueListenable<String?> differentListenable =
       SpyStringValueNotifier('Hendricks');

    await tester.pumpWidget(builderForValueListenable(differentListenable));

    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Hendricks'), findsOneWidget);

    // Change value of the (now) disconnected listenable.
    valueListenable.value = 'Big Head';

    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Big Head'), findsNothing);
    expect(find.text('Hendricks'), findsOneWidget);
  });

  testWidgets('Self-cleans when removed', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());

    expect(find.text('Gilfoyle'), findsNothing);
    expect(valueListenable.hasListeners, false);
  });
}

class SpyStringValueNotifier extends ValueNotifier<String?> {
  SpyStringValueNotifier(String? initialValue) : super(initialValue);

  /// Override for test visibility only.
  @override
  bool get hasListeners => super.hasListeners;
}
