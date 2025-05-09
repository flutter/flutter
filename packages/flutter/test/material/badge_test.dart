// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Large Badge defaults', (WidgetTester tester) async {
    late final ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (BuildContext context) {
              // theme.textTheme is updated when the MaterialApp is built.
              theme = Theme.of(context);
              return const Badge(label: Text('0'), child: Icon(Icons.add));
            },
          ),
        ),
      ),
    );

    expect(
      tester.renderObject<RenderParagraph>(find.text('0')).text.style,
      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onError),
    );

    // default badge alignment = AlignmentDirection.topEnd
    // default offset for LTR = Offset(4, -4)
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default largeSize = 16
    // '0'.width = 12
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    expect(tester.getTopLeft(find.text('0')), const Offset(16, -4));

    final RenderBox box = tester.renderObject(find.byType(Badge));
    final RRect rrect = RRect.fromLTRBR(12, -4, 31.5, 12, const Radius.circular(8));
    expect(box, paints..rrect(rrect: rrect, color: theme.colorScheme.error));
  });

  testWidgets('Large Badge defaults with RTL', (WidgetTester tester) async {
    late final ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topLeft,
            child: Builder(
              builder: (BuildContext context) {
                // theme.textTheme is updated when the MaterialApp is built.
                theme = Theme.of(context);
                return const Badge(label: Text('0'), child: Icon(Icons.add));
              },
            ),
          ),
        ),
      ),
    );

    expect(
      tester.renderObject<RenderParagraph>(find.text('0')).text.style,
      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onError),
    );

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    expect(tester.getTopLeft(find.text('0')), const Offset(0, -4));

    final RenderBox box = tester.renderObject(find.byType(Badge));
    final RRect rrect = RRect.fromLTRBR(-4, -4, 15.5, 12, const Radius.circular(8));
    expect(box, paints..rrect(rrect: rrect, color: theme.colorScheme.error));
  });

  // Essentially the same as 'Large Badge defaults'
  testWidgets('Badge.count', (WidgetTester tester) async {
    late final ThemeData theme;

    Widget buildFrame(int count) {
      return MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (BuildContext context) {
              // theme.textTheme is updated when the MaterialApp is built.
              if (count == 0) {
                theme = Theme.of(context);
              }
              return Badge.count(count: count, child: const Icon(Icons.add));
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(0));

    expect(
      tester.renderObject<RenderParagraph>(find.text('0')).text.style,
      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onError),
    );

    // default badge alignment = AlignmentDirectional(12, -4)
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default largeSize = 16
    // '0'.width = 12
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    // x = alignment.start + padding.left
    // y = alignment.top
    expect(tester.getTopLeft(find.text('0')), const Offset(16, -4));

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // '0'.width = 12
    // L = alignment.start
    // T = alignment.top
    // R = L + '0'.width + padding.width
    // B = T + largeSize, R = largeSize/2
    final RRect rrect = RRect.fromLTRBR(12, -4, 31.5, 12, const Radius.circular(8));
    expect(box, paints..rrect(rrect: rrect, color: theme.colorScheme.error));

    await tester.pumpWidget(buildFrame(1000));
    expect(find.text('999+'), findsOneWidget);
  });

  testWidgets('Small Badge defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Align(alignment: Alignment.topLeft, child: Badge(child: Icon(Icons.add))),
      ),
    );

    // default badge location is end=0, top=0
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default smallSize = 6
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // L = icon.size.width - smallSize
    // T = 0
    // R = icon.size.width
    // B = smallSize
    expect(
      box,
      paints..rrect(
        rrect: RRect.fromLTRBR(18, 0, 24, 6, const Radius.circular(3)),
        color: theme.colorScheme.error,
      ),
    );
  });

  testWidgets('Small Badge RTL defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Align(alignment: Alignment.topLeft, child: Badge(child: Icon(Icons.add))),
        ),
      ),
    );

    // default badge location is end=0, top=0
    // default smallSize = 6
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // L = 0
    // T = 0
    // R = smallSize
    // B = smallSize
    expect(
      box,
      paints..rrect(
        rrect: RRect.fromLTRBR(0, 0, 6, 6, const Radius.circular(3)),
        color: theme.colorScheme.error,
      ),
    );
  });

  testWidgets('Large Badge textStyle and colors', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    const Color green = Color(0xff00ff00);
    const Color black = Color(0xff000000);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Align(
          alignment: Alignment.topLeft,
          child: Badge(
            textColor: green,
            backgroundColor: black,
            textStyle: TextStyle(fontSize: 10),
            label: Text('0'),
            child: Icon(Icons.add),
          ),
        ),
      ),
    );

    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('0')).text.style!;
    expect(textStyle.fontSize, 10);
    expect(textStyle.color, green);
    expect(tester.renderObject(find.byType(Badge)), paints..rrect(color: black));
  });

  testWidgets('isLabelVisible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Badge(label: Text('0'), isLabelVisible: false, child: Icon(Icons.add)),
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.byType(Icon), findsOneWidget);

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);
    final RenderBox box = tester.renderObject(find.byType(Badge));
    expect(box, isNot(paints..rrect()));
  });

  testWidgets('Large Badge alignment', (WidgetTester tester) async {
    const Radius badgeRadius = Radius.circular(8);

    Widget buildFrame(Alignment alignment, [Offset offset = Offset.zero]) {
      return MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Badge(
            // Default largeSize = 16, badge with label is "large".
            label: Container(width: 8, height: 8, color: Colors.blue),
            alignment: alignment,
            offset: offset,
            child: Container(color: const Color(0xFF00FF00), width: 200, height: 200),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Alignment.topLeft));
    final RenderBox box = tester.renderObject(find.byType(Badge));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 0, 16, 16, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.topCenter));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(100 - 8, 0, 100 + 8, 16, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.topRight));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 16, 0, 200, 16, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.centerLeft));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 100, 16, 100 + 16, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.centerRight));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 16, 100, 200, 100 + 16, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomLeft));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 200, 16, 200 + 16, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomCenter));
    expect(
      box,
      paints..rrect(rrect: RRect.fromLTRBR(100 - 8, 200, 100 + 8, 200 + 16, badgeRadius)),
    );

    await tester.pumpWidget(buildFrame(Alignment.bottomRight));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 16, 200, 200, 200 + 16, badgeRadius)));

    const Offset offset = Offset(5, 10);

    await tester.pumpWidget(buildFrame(Alignment.topLeft, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 0, 16, 16, badgeRadius).shift(offset)));

    await tester.pumpWidget(buildFrame(Alignment.topCenter, offset));
    expect(
      box,
      paints..rrect(rrect: RRect.fromLTRBR(100 - 8, 0, 100 + 8, 16, badgeRadius).shift(offset)),
    );

    await tester.pumpWidget(buildFrame(Alignment.topRight, offset));
    expect(
      box,
      paints..rrect(rrect: RRect.fromLTRBR(200 - 16, 0, 200, 16, badgeRadius).shift(offset)),
    );

    await tester.pumpWidget(buildFrame(Alignment.centerLeft, offset));
    expect(
      box,
      paints..rrect(rrect: RRect.fromLTRBR(0, 100, 16, 100 + 16, badgeRadius).shift(offset)),
    );

    await tester.pumpWidget(buildFrame(Alignment.centerRight, offset));
    expect(
      box,
      paints
        ..rrect(rrect: RRect.fromLTRBR(200 - 16, 100, 200, 100 + 16, badgeRadius).shift(offset)),
    );

    await tester.pumpWidget(buildFrame(Alignment.bottomLeft, offset));
    expect(
      box,
      paints..rrect(rrect: RRect.fromLTRBR(0, 200, 16, 200 + 16, badgeRadius).shift(offset)),
    );

    await tester.pumpWidget(buildFrame(Alignment.bottomCenter, offset));
    expect(
      box,
      paints
        ..rrect(rrect: RRect.fromLTRBR(100 - 8, 200, 100 + 8, 200 + 16, badgeRadius).shift(offset)),
    );

    await tester.pumpWidget(buildFrame(Alignment.bottomRight, offset));
    expect(
      box,
      paints
        ..rrect(rrect: RRect.fromLTRBR(200 - 16, 200, 200, 200 + 16, badgeRadius).shift(offset)),
    );
  });

  testWidgets('Small Badge alignment', (WidgetTester tester) async {
    const Radius badgeRadius = Radius.circular(3);

    Widget buildFrame(Alignment alignment, [Offset offset = Offset.zero]) {
      return MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Badge(
            // Default smallSize = 6, badge without label is "small".
            alignment: alignment,
            offset: offset, // Not used for smallSize badges.
            child: Container(color: const Color(0xFF00FF00), width: 200, height: 200),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Alignment.topLeft));
    final RenderBox box = tester.renderObject(find.byType(Badge));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 0, 6, 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.topCenter));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(100 - 3, 0, 100 + 3, 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.topRight));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 6, 0, 200, 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.centerLeft));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 100, 6, 100 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.centerRight));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 6, 100, 200, 100 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomLeft));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 200, 6, 200 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomCenter));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(100 - 3, 200, 100 + 3, 200 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomRight));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 6, 200, 200, 200 + 6, badgeRadius)));

    const Offset offset = Offset(5, 10); // Not used for smallSize Badges.

    await tester.pumpWidget(buildFrame(Alignment.topLeft, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 0, 6, 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.topCenter, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(100 - 3, 0, 100 + 3, 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.topRight, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 6, 0, 200, 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.centerLeft, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 100, 6, 100 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.centerRight, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 6, 100, 200, 100 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomLeft, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 200, 6, 200 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomCenter, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(100 - 3, 200, 100 + 3, 200 + 6, badgeRadius)));

    await tester.pumpWidget(buildFrame(Alignment.bottomRight, offset));
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(200 - 6, 200, 200, 200 + 6, badgeRadius)));
  });

  testWidgets('Badge Larger than large size', (WidgetTester tester) async {
    const Radius badgeRadius = Radius.circular(15);

    Widget buildFrame(Alignment alignment, [Offset offset = Offset.zero]) {
      return MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Badge(
            // LargeSize = 16, make content of badge bigger than the default.
            label: Container(width: 30, height: 30, color: Colors.blue),
            alignment: alignment,
            offset: offset,
            child: Container(color: const Color(0xFF00FF00), width: 200, height: 200),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Alignment.topLeft));
    final RenderBox box = tester.renderObject(find.byType(Badge));
    // Badge should scale with content
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, -7, 30 + 8, 23, badgeRadius)));
  });

  testWidgets('Badge ThemeData.badgeTheme', (WidgetTester tester) async {

    final ThemeData theme = ThemeData(
      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xFF000001),
        textColor: Color(0xFF000002),
        textStyle: TextStyle(fontSize: 21),
        padding: EdgeInsets.all(16),
        alignment: Alignment.topLeft,
        offset: Offset(13, 13),
      ),
    );

    Widget buildFrame({ThemeData? theme, BadgeThemeData? badgeTheme, Widget? badge}) {
      final Widget badgeWidget = badge ?? const Badge(label: Text('0'), child: SizedBox());
      return MaterialApp(
        key: UniqueKey(),
        theme: theme,
        home: Align(
          alignment: Alignment.topLeft,
          child:
              badgeTheme != null ? BadgeTheme(data: badgeTheme, child: badgeWidget) : badgeWidget,
        ),
      );
    }

    await tester.pumpWidget(buildFrame(theme: theme));
    final RenderObject badge = tester.renderObject(find.byType(Badge));
    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('0')).text.style!;

    // backgroundColor
    expect(badge, paints..rrect(color: const Color(0xFF000001)));

    // textColor
    expect(textStyle.color, const Color(0xFF000002));

    // textStyle
    expect(textStyle.fontSize, 21);

    // alignment, offset, padding
    expect(badge, paints..rrect(rrect: RRect.fromLTRBR(13.0, -5.5, 66.0, 47.5, const Radius.circular(26.5))));

    // largeSize
    await tester.pumpWidget(
      buildFrame(
        theme: ThemeData(badgeTheme: const BadgeThemeData(largeSize: 52.0)),
        badge: const Badge(label: SizedBox(height: 20, child: Text('0'))),
      ),
    );
    final Size largeSize = tester.getSize(find.byType(Badge));
    expect(largeSize.height, equals(52.0));

    // smallSize
    await tester.pumpWidget(
      buildFrame(
        theme: ThemeData(badgeTheme: const BadgeThemeData(smallSize: 42.0)),
        badge: const Badge(),
      ),
    );
    final Size smallSize = tester.getSize(find.byType(Badge));
    expect(smallSize.height, equals(42.0));
  });

  testWidgets('Badge BadgeThemeData Overrides ThemeData.badgeTheme', (WidgetTester tester) async {

    final ThemeData theme = ThemeData(
      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xFF000001),
        textColor: Color(0xFF000002),
        textStyle: TextStyle(fontSize: 21),
        padding: EdgeInsets.all(16),
        alignment: Alignment.topCenter,
        offset: Offset(13, 13),
      ),
    );

    const BadgeThemeData badgeThemeData = BadgeThemeData(
      backgroundColor: Color(0xFF000003),
      textColor: Color(0xFF000004),
      textStyle: TextStyle(fontSize: 22),
      padding: EdgeInsets.all(17),
      alignment: Alignment.topLeft,
      offset: Offset(14, 14),
    );

    Widget buildFrame({ThemeData? theme, BadgeThemeData? badgeTheme, Widget? badge}) {
      final Widget badgeWidget = badge ?? const Badge(label: Text('0'), child: SizedBox());
      return MaterialApp(
        key: UniqueKey(),
        theme: theme,
        home: Align(
          alignment: Alignment.topLeft,
          child:
              badgeTheme != null ? BadgeTheme(data: badgeTheme, child: badgeWidget) : badgeWidget,
        ),
      );
    }

    await tester.pumpWidget(buildFrame(theme: theme, badgeTheme: badgeThemeData));

    final RenderObject badge = tester.renderObject(find.byType(Badge));
    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('0')).text.style!;

    // backgroundColor
    expect(badge, paints..rrect(color: const Color(0xFF000003)));

    // textColor
    expect(textStyle.color, const Color(0xFF000004));

    // textStyle
    expect(textStyle.fontSize, 22);

    // alignment, offset, padding
    expect(badge, paints..rrect(rrect: RRect.fromLTRBR(14.0, -6, 70.0, 50.0, const Radius.circular(28.0))));

    // largeSize
    await tester.pumpWidget(
      buildFrame(
        theme: ThemeData(badgeTheme: const BadgeThemeData(largeSize: 52.0)),
        badgeTheme: const BadgeThemeData(largeSize: 53.0),
        badge: const Badge(label: SizedBox(height: 20, child: Text('0'))),
      ),
    );
    final Size largeSize = tester.getSize(find.byType(Badge));
    expect(largeSize.height, equals(53.0));

    // smallSize
    await tester.pumpWidget(
      buildFrame(
        theme: ThemeData(badgeTheme: const BadgeThemeData(smallSize: 42.0)),
        badgeTheme: const BadgeThemeData(smallSize: 43.0),
        badge: const Badge(),
      ),
    );
    final Size smallSize = tester.getSize(find.byType(Badge));
    expect(smallSize.height, equals(43.0));
  });

  testWidgets('Badge Overrides Theme', (WidgetTester tester) async {

    final ThemeData theme = ThemeData(
      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xFF000001),
        textColor: Color(0xFF000002),
        textStyle: TextStyle(fontSize: 21),
        padding: EdgeInsets.all(16),
        alignment: Alignment.topCenter,
        offset: Offset(13, 13),
      ),
    );

    const BadgeThemeData badgeThemeData = BadgeThemeData(
      backgroundColor: Color(0xFF000003),
      textColor: Color(0xFF000004),
      textStyle: TextStyle(fontSize: 22),
      padding: EdgeInsets.all(17),
      alignment: Alignment.topCenter,
      offset: Offset(14, 14),
    );

    Widget buildFrame({ThemeData? theme, BadgeThemeData? badgeTheme, Widget? badge}) {
      final Widget badgeWidget = badge ?? const Badge(label: Text('0'), child: SizedBox());
      return MaterialApp(
        key: UniqueKey(),
        theme: theme,
        home: Align(
          alignment: Alignment.topLeft,
          child:
              badgeTheme != null ? BadgeTheme(data: badgeTheme, child: badgeWidget) : badgeWidget,
        ),
      );
    }

    await tester.pumpWidget(
      buildFrame(
        theme: theme,
        badgeTheme: badgeThemeData,
        badge: const Badge(
          label: Text('0'),
          backgroundColor: Color(0xFF000005),
          textColor: Color(0xFF000006),
          textStyle: TextStyle(fontSize: 23),
          padding: EdgeInsets.all(18),
          alignment: Alignment.topLeft,
          offset: Offset(15, 15),
          child: SizedBox(),
        ),
      ),
    );

    final RenderObject badge = tester.renderObject(find.byType(Badge));
    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('0')).text.style!;

    // backgroundColor
    expect(badge, paints..rrect(color: const Color(0xFF000005)));

    // textColor
    expect(textStyle.color, const Color(0xFF000006));

    // textStyle
    expect(textStyle.fontSize, 23);

    // alignment, offset, padding
    expect(badge, paints..rrect(rrect: RRect.fromLTRBR(15.0, -6.5, 74.0, 52.5, const Radius.circular(29.5))));

    // largeSize
    await tester.pumpWidget(
      buildFrame(
        theme: ThemeData(badgeTheme: const BadgeThemeData(largeSize: 52.0)),
        badgeTheme: const BadgeThemeData(largeSize: 53.0),
        badge: const Badge(largeSize: 54.0, label: SizedBox(height: 20, child: Text('0'))),
      ),
    );
    final Size largeSize = tester.getSize(find.byType(Badge));
    expect(largeSize.height, equals(54.0));

    // smallSize
    await tester.pumpWidget(
      buildFrame(
        theme: ThemeData(badgeTheme: const BadgeThemeData(smallSize: 42.0)),
        badgeTheme: const BadgeThemeData(smallSize: 43.0),
        badge: const Badge(smallSize: 44.0,),
      ),
    );
    final Size smallSize = tester.getSize(find.byType(Badge));
    expect(smallSize.height, equals(44.0));
  });
}
