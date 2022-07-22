import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestBreakpoint0 extends Breakpoint{
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width>=0;
  }
}
class TestBreakpoint800 extends Breakpoint{
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width>=800 && MediaQuery.of(context).size.width<1000;
  }
}
class TestBreakpoint1000 extends Breakpoint{
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width>=1000;
  }
}

Future<MaterialApp> scaffold({
  required double width,
  required WidgetTester tester,
  bool animations = true,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: AdaptiveScaffold(
        internalAnimations: animations,
        breakpoints: <Breakpoint>[TestBreakpoint0(), TestBreakpoint800(), TestBreakpoint1000()],
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.article), label: 'Articles'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.video_call), label: 'Video'),
        ],
        smallBody: (_) => Container(color: Colors.red),
        body: (_) => Container(color: Colors.green),
        largeBody: (_) => Container(color: Colors.blue),
        smallSecondaryBody: (_) => Container(color: Colors.red),
        secondaryBody: (_) => Container(color: Colors.green),
        largeSecondaryBody: (_) => Container(color: Colors.blue),
      ),
    ),
  );
}
void main() {
  testWidgets('adaptive scaffold lays out slots as expected', (WidgetTester tester) async {
      final Finder b = find.byKey(const Key('body0'));
      final Finder b1 = find.byKey(const Key('body1'));
      final Finder b2 = find.byKey(const Key('body2'));
      final Finder sb = find.byKey(const Key('secondaryBody0'));
      final Finder sb1 = find.byKey(const Key('secondaryBody1'));
      final Finder sb2 = find.byKey(const Key('secondaryBody2'));
      final Finder bnav = find.byKey(const Key('bottomNavigation'));
      final Finder pnav = find.byKey(const Key('primaryNavigation'));
      final Finder pnav1 = find.byKey(const Key('primaryNavigation1'));

      await tester.pumpWidget(await scaffold(width: 300, tester: tester));
      await tester.pumpAndSettle();

      expect(b, findsOneWidget);
      expect(sb, findsOneWidget);
      expect(bnav, findsOneWidget);
      expect(pnav, findsNothing);

      expect(tester.getTopLeft(b), Offset.zero);
      expect(tester.getTopLeft(sb), const Offset(150, 0));
      expect(tester.getTopLeft(bnav), const Offset(0, 744));


      await tester.pumpWidget(await scaffold(width: 900, tester: tester));
      await tester.pumpAndSettle();

      expect(b, findsNothing);
      expect(b1, findsOneWidget);
      expect(sb, findsNothing);
      expect(sb1, findsOneWidget);
      expect(bnav, findsNothing);
      expect(pnav, findsOneWidget);

      expect(tester.getTopLeft(b1), const Offset(72, 0));
      expect(tester.getTopLeft(sb1), const Offset(450, 0));
      expect(tester.getTopLeft(pnav), Offset.zero);
      expect(tester.getBottomRight(pnav), const Offset(72, 800));

      await tester.pumpWidget(await scaffold(width: 1100, tester: tester));
      await tester.pumpAndSettle();

      expect(b1, findsNothing);
      expect(b2, findsOneWidget);
      expect(sb1, findsNothing);
      expect(sb2, findsOneWidget);
      expect(pnav, findsNothing);
      expect(pnav1, findsOneWidget);

      expect(tester.getTopLeft(b2), const Offset(192, 0));
      expect(tester.getTopLeft(sb2), const Offset(550, 0));
      expect(tester.getTopLeft(pnav1), Offset.zero);
      expect(tester.getBottomRight(pnav1), const Offset(192, 800));
  });
  testWidgets('adaptive scaffold animations work correctly', (WidgetTester tester) async {
    final Finder b = find.byKey(const Key('body0'));
    final Finder sb = find.byKey(const Key('secondaryBody0'));

    await tester.pumpWidget(await scaffold(width: 400, tester: tester));
    await tester.pumpWidget(await scaffold(width: 800, tester: tester));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(b), const Offset(14.4, 0));
    expect(tester.getBottomRight(b), offsetMoreOrLessEquals(const Offset(778.2, 755.2), epsilon: 1.0));
    expect(tester.getTopLeft(sb), offsetMoreOrLessEquals(const Offset(778.2, 0), epsilon: 1.0));
    expect(tester.getBottomRight(sb), offsetMoreOrLessEquals(const Offset(1178.2, 755.2), epsilon: 1.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.getTopLeft(b), const Offset(57.6, 0));
    expect(tester.getBottomRight(b), offsetMoreOrLessEquals(const Offset(416.0, 788.8), epsilon: 1.0));
    expect(tester.getTopLeft(sb), offsetMoreOrLessEquals(const Offset(416, 0), epsilon: 1.0));
    expect(tester.getBottomRight(sb), offsetMoreOrLessEquals(const Offset(816, 788.8), epsilon: 1.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(b), const Offset(72, 0));
    expect(tester.getBottomRight(b), const Offset(400, 800));
    expect(tester.getTopLeft(sb), const Offset(400, 0));
    expect(tester.getBottomRight(sb), const Offset(800, 800));
  });
  testWidgets('adaptive scaffold animations can be disabled', (WidgetTester tester) async {
    final Finder b = find.byKey(const Key('body0'));
    final Finder sb = find.byKey(const Key('secondaryBody0'));

    await tester.pumpWidget(await scaffold(width: 400, tester: tester, animations: false));
    await tester.pumpWidget(await scaffold(width: 800, tester: tester, animations: false));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(b), const Offset(72, 0));
    expect(tester.getBottomRight(b), const Offset(400, 800));
    expect(tester.getTopLeft(sb), const Offset(400, 0));
    expect(tester.getBottomRight(sb), const Offset(800, 800));
  });
}
