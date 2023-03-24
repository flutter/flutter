// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({super.key});

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  late IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.expand_more);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, {super.key});

  final String text;

  @override
  TestTextState createState() => TestTextState();
}

class TestTextState extends State<TestText> {
  late TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return Text(widget.text);
  }
}

void main() {
  const Color dividerColor = Color(0x1f333333);
  const Color foregroundColor = Colors.blueAccent;
  const Color unselectedWidgetColor = Colors.black54;
  const Color headerColor = Colors.black45;

  testWidgets('ExpansionTile initial state', (WidgetTester tester) async {
    final Key topKey = UniqueKey();
    const Key expandedKey = PageStorageKey<String>('expanded');
    const Key collapsedKey = PageStorageKey<String>('collapsed');
    const Key defaultKey = PageStorageKey<String>('default');

    final Key tileKey = UniqueKey();
    const Clip clipBehavior = Clip.antiAlias;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        dividerColor: dividerColor,
      ),
      home: Material(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(title: const Text('Top'), key: topKey),
              ExpansionTile(
                key: expandedKey,
                initiallyExpanded: true,
                title: const Text('Expanded'),
                backgroundColor: Colors.red,
                clipBehavior: clipBehavior,
                children: <Widget>[
                  ListTile(
                    key: tileKey,
                    title: const Text('0'),
                  ),
                ],
              ),
              ExpansionTile(
                key: collapsedKey,
                title: const Text('Collapsed'),
                children: <Widget>[
                  ListTile(
                    key: tileKey,
                    title: const Text('0'),
                  ),
                ],
              ),
              const ExpansionTile(
                key: defaultKey,
                title: Text('Default'),
                children: <Widget>[
                  ListTile(title: Text('0')),
                ],
              ),
            ],
          ),
        ),
      ),
    ));

    double getHeight(Key key) => tester.getSize(find.byKey(key)).height;
    Container getContainer(Key key) => tester.firstWidget(find.descendant(
      of: find.byKey(key),
      matching: find.byType(Container),
    ));

    expect(getHeight(topKey), getHeight(expandedKey) - getHeight(tileKey) - 2.0);
    expect(getHeight(topKey), getHeight(collapsedKey) - 2.0);
    expect(getHeight(topKey), getHeight(defaultKey) - 2.0);

    // expansionTile should have Clip.antiAlias as clipBehavior
    expect(getContainer(expandedKey).clipBehavior, clipBehavior);

    ShapeDecoration expandedContainerDecoration = getContainer(expandedKey).decoration! as ShapeDecoration;
    expect(expandedContainerDecoration.color, Colors.red);
    expect((expandedContainerDecoration.shape as Border).top.color, dividerColor);
    expect((expandedContainerDecoration.shape as Border).bottom.color, dividerColor);

    ShapeDecoration collapsedContainerDecoration = getContainer(collapsedKey).decoration! as ShapeDecoration;
    expect(collapsedContainerDecoration.color, Colors.transparent);
    expect((collapsedContainerDecoration.shape as Border).top.color, Colors.transparent);
    expect((collapsedContainerDecoration.shape as Border).bottom.color, Colors.transparent);

    await tester.tap(find.text('Expanded'));
    await tester.tap(find.text('Collapsed'));
    await tester.tap(find.text('Default'));

    await tester.pump();

    // Pump to the middle of the animation for expansion.
    await tester.pump(const Duration(milliseconds: 100));
    final ShapeDecoration collapsingContainerDecoration = getContainer(collapsedKey).decoration! as ShapeDecoration;
    expect(collapsingContainerDecoration.color, Colors.transparent);
    expect((collapsingContainerDecoration.shape as Border).top.color, const Color(0x15222222));
    expect((collapsingContainerDecoration.shape as Border).bottom.color, const Color(0x15222222));

    // Pump all the way to the end now.
    await tester.pump(const Duration(seconds: 1));

    expect(getHeight(topKey), getHeight(expandedKey) - 2.0);
    expect(getHeight(topKey), getHeight(collapsedKey) - getHeight(tileKey) - 2.0);
    expect(getHeight(topKey), getHeight(defaultKey) - getHeight(tileKey) - 2.0);

    // Expanded should be collapsed now.
    expandedContainerDecoration = getContainer(expandedKey).decoration! as ShapeDecoration;
    expect(expandedContainerDecoration.color, Colors.transparent);
    expect((expandedContainerDecoration.shape as Border).top.color, Colors.transparent);
    expect((expandedContainerDecoration.shape as Border).bottom.color, Colors.transparent);

    // Collapsed should be expanded now.
    collapsedContainerDecoration = getContainer(collapsedKey).decoration! as ShapeDecoration;
    expect(collapsedContainerDecoration.color, Colors.transparent);
    expect((collapsedContainerDecoration.shape as Border).top.color, dividerColor);
    expect((collapsedContainerDecoration.shape as Border).bottom.color, dividerColor);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('ExpansionTile Theme dependencies', (WidgetTester tester) async {
    final Key expandedTitleKey = UniqueKey();
    final Key collapsedTitleKey = UniqueKey();
    final Key expandedIconKey = UniqueKey();
    final Key collapsedIconKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(primary: foregroundColor),
          unselectedWidgetColor: unselectedWidgetColor,
          textTheme: const TextTheme(titleMedium: TextStyle(color: headerColor)),
        ),
        home: Material(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const ListTile(title: Text('Top')),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: TestText('Expanded', key: expandedTitleKey),
                  backgroundColor: Colors.red,
                  trailing: TestIcon(key: expandedIconKey),
                  children: const <Widget>[ListTile(title: Text('0'))],
                ),
                ExpansionTile(
                  title: TestText('Collapsed', key: collapsedTitleKey),
                  trailing: TestIcon(key: collapsedIconKey),
                  children: const <Widget>[ListTile(title: Text('0'))],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Color iconColor(Key key) => tester.state<TestIconState>(find.byKey(key)).iconTheme.color!;
    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color!;

    expect(textColor(expandedTitleKey), foregroundColor);
    expect(textColor(collapsedTitleKey), headerColor);
    expect(iconColor(expandedIconKey), foregroundColor);
    expect(iconColor(collapsedIconKey), unselectedWidgetColor);

    // Tap both tiles to change their state: collapse and extend respectively
    await tester.tap(find.text('Expanded'));
    await tester.tap(find.text('Collapsed'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(textColor(expandedTitleKey), headerColor);
    expect(textColor(collapsedTitleKey), foregroundColor);
    expect(iconColor(expandedIconKey), unselectedWidgetColor);
    expect(iconColor(collapsedIconKey), foregroundColor);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('ExpansionTile subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpansionTile(
            title: Text('Title'),
            subtitle: Text('Subtitle'),
            children: <Widget>[ListTile(title: Text('0'))],
          ),
        ),
      ),
    );

    expect(find.text('Subtitle'), findsOneWidget);
  });

  testWidgets('ExpansionTile maintainState', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          dividerColor: dividerColor,
        ),
        home: const Material(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ExpansionTile(
                  title: Text('Tile 1'),
                  maintainState: true,
                  children: <Widget>[
                    Text('Maintaining State'),
                  ],
                ),
                ExpansionTile(
                  title: Text('Title 2'),
                  children: <Widget>[
                    Text('Discarding State'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

     // This text should be offstage while ExpansionTile collapsed
     expect(find.text('Maintaining State', skipOffstage: false), findsOneWidget);
     expect(find.text('Maintaining State'), findsNothing);
     // This text shouldn't be there while ExpansionTile collapsed
     expect(find.text('Discarding State'), findsNothing);
   });

  testWidgets('ExpansionTile padding test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: Center(
          child: ExpansionTile(
            title: Text('Hello'),
            tilePadding: EdgeInsets.fromLTRB(8, 12, 4, 10),
          ),
        ),
      ),
    ));

    final Rect titleRect = tester.getRect(find.text('Hello'));
    final Rect trailingRect = tester.getRect(find.byIcon(Icons.expand_more));
    final Rect listTileRect = tester.getRect(find.byType(ListTile));
    final Rect tallerWidget = titleRect.height > trailingRect.height ? titleRect : trailingRect;

    // Check the positions of title and trailing Widgets, after padding is applied.
    expect(listTileRect.left, titleRect.left - 8);
    expect(listTileRect.right, trailingRect.right + 4);

    // Calculate the remaining height of ListTile from the default height.
    final double remainingHeight = 56 - tallerWidget.height;
    expect(listTileRect.top, tallerWidget.top - remainingHeight / 2 - 12);
    expect(listTileRect.bottom, tallerWidget.bottom + remainingHeight / 2 + 10);
  });

  testWidgets('ExpansionTile expandedAlignment test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: Center(
          child: ExpansionTile(
            title: Text('title'),
            expandedAlignment: Alignment.centerLeft,
            children: <Widget>[
              SizedBox(height: 100, width: 100),
              SizedBox(height: 100, width: 80),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    final Rect columnRect = tester.getRect(find.byType(Column).last);

    // The expandedAlignment is used to define the alignment of the Column widget in
    // expanded tile, not the alignment of the children inside the Column.
    expect(columnRect.left, 0.0);
    // The width of the Column is the width of the largest child. The largest width
    // being 100.0, the offset of the right edge of Column from X-axis should be 100.0.
    expect(columnRect.right, 100.0);
  });

  testWidgets('ExpansionTile expandedCrossAxisAlignment test', (WidgetTester tester) async {
    const Key child0Key = Key('child0');
    const Key child1Key = Key('child1');

    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: Center(
          child: ExpansionTile(
            title: Text('title'),
            // Set the column's alignment to Alignment.centerRight to test CrossAxisAlignment
            // of children widgets. This helps distinguish the effect of expandedAlignment
            // and expandedCrossAxisAlignment later in the test.
            expandedAlignment: Alignment.centerRight,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 100, width: 100, key: child0Key),
              SizedBox(height: 100, width: 80, key: child1Key),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    final Rect columnRect = tester.getRect(find.byType(Column).last);
    final Rect child0Rect = tester.getRect(find.byKey(child0Key));
    final Rect child1Rect = tester.getRect(find.byKey(child1Key));

    // Since expandedAlignment is set to Alignment.centerRight, the column of children
    // should be aligned to the center right of the expanded tile. This provides confirmation
    // that the expandedCrossAxisAlignment.start is 700.0, where columnRect.left is.
    expect(columnRect.right, 800.0);
    // The width of the Column is the width of the largest child. The largest width
    // being 100.0, the offset of the left edge of Column from X-axis should be 700.0.
    expect(columnRect.left, 700.0);

    // Considering the value of expandedCrossAxisAlignment is CrossAxisAlignment.start,
    // the offset of the left edge of both the children from X-axis should be 700.0.
    expect(child0Rect.left, 700.0);
    expect(child1Rect.left, 700.0);
  });

  testWidgets('CrossAxisAlignment.baseline is not allowed', (WidgetTester tester) async {
    expect(
      () {
        MaterialApp(
          home: Material(
            child: ExpansionTile(
              initiallyExpanded: true,
              title: const Text('title'),
              expandedCrossAxisAlignment: CrossAxisAlignment.baseline,
            ),
          ),
        );
      },
      throwsA(isA<AssertionError>().having((AssertionError error) => error.toString(), '.toString()', contains(
        'CrossAxisAlignment.baseline is not supported since the expanded'
        ' children are aligned in a column, not a row. Try to use another constant.',
      ))),
    );
  });

  testWidgets('expandedCrossAxisAlignment and expandedAlignment default values', (WidgetTester tester) async {
    const Key child1Key = Key('child1');

    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: Center(
          child: ExpansionTile(
            title: Text('title'),
            children: <Widget>[
              SizedBox(height: 100, width: 100),
              SizedBox(height: 100, width: 80, key: child1Key),
            ],
          ),
        ),
      ),
    ));


    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    final Rect columnRect = tester.getRect(find.byType(Column).last);
    final Rect child1Rect = tester.getRect(find.byKey(child1Key));

    // The default viewport size is Size(800, 600).
    // By default the value of extendedAlignment is Alignment.center, hence the offset
    // of left and right edges from x axis should be equal.
    expect(columnRect.left, 800 - columnRect.right);

    // By default the value of extendedCrossAxisAlignment is CrossAxisAlignment.center, hence
    // the offset of left and right edges from Column should be equal.
    expect(child1Rect.left - columnRect.left, columnRect.right - child1Rect.right);

  });

  testWidgets('childrenPadding default value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ExpansionTile(
              title: Text('title'),
              children: <Widget>[
                SizedBox(height: 100, width: 100),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    final Rect columnRect = tester.getRect(find.byType(Column).last);
    final Rect paddingRect = tester.getRect(find.byType(Padding).last);

    // By default, the value of childrenPadding is EdgeInsets.zero, hence offset
    // of all the edges from x-axis and y-axis should be equal for Padding and Column.
    expect(columnRect.top, paddingRect.top);
    expect(columnRect.left, paddingRect.left);
    expect(columnRect.right, paddingRect.right);
    expect(columnRect.bottom, paddingRect.bottom);
  });

  testWidgets('ExpansionTile childrenPadding test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ExpansionTile(
              title: Text('title'),
              childrenPadding: EdgeInsets.fromLTRB(10, 8, 12, 4),
              children: <Widget>[
                SizedBox(height: 100, width: 100),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    final Rect columnRect = tester.getRect(find.byType(Column).last);
    final Rect paddingRect = tester.getRect(find.byType(Padding).last);

    // Check the offset of all the edges from x-axis and y-axis after childrenPadding
    // is applied.
    expect(columnRect.left, paddingRect.left + 10);
    expect(columnRect.top, paddingRect.top + 8);
    expect(columnRect.right, paddingRect.right - 12);
    expect(columnRect.bottom, paddingRect.bottom - 4);
  });

  testWidgets('ExpansionTile.collapsedBackgroundColor', (WidgetTester tester) async {
    const Key expansionTileKey = Key('expansionTileKey');
    const Color backgroundColor = Colors.red;
    const Color collapsedBackgroundColor = Colors.brown;

    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: ExpansionTile(
          key: expansionTileKey,
          title: Text('Title'),
          backgroundColor: backgroundColor,
          collapsedBackgroundColor: collapsedBackgroundColor,
          children: <Widget>[
            SizedBox(height: 100, width: 100),
          ],
        ),
      ),
    ));

    ShapeDecoration shapeDecoration =  tester.firstWidget<Container>(find.descendant(
      of: find.byKey(expansionTileKey),
      matching: find.byType(Container),
    )).decoration! as ShapeDecoration;

    expect(shapeDecoration.color, collapsedBackgroundColor);

    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();

    shapeDecoration =  tester.firstWidget<Container>(find.descendant(
      of: find.byKey(expansionTileKey),
      matching: find.byType(Container),
    )).decoration! as ShapeDecoration;

    expect(shapeDecoration.color, backgroundColor);
  });

  testWidgets('ExpansionTile default iconColor, textColor', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Material(
        child: ExpansionTile(
          title: TestText('title'),
          trailing: TestIcon(),
          children: <Widget>[
            SizedBox(height: 100, width: 100),
          ],
        ),
      ),
    ));

    Color getIconColor() => tester.state<TestIconState>(find.byType(TestIcon)).iconTheme.color!;
    Color getTextColor() => tester.state<TestTextState>(find.byType(TestText)).textStyle.color!;

    expect(getIconColor(), theme.colorScheme.onSurfaceVariant);
    expect(getTextColor(), theme.colorScheme.onSurface);

    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    expect(getIconColor(), theme.colorScheme.primary);
    expect(getTextColor(), theme.colorScheme.onSurface);
  });

  testWidgets('ExpansionTile iconColor, textColor', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/78281

    const Color iconColor = Color(0xff00ff00);
    const Color collapsedIconColor = Color(0xff0000ff);
    const Color textColor = Color(0xff00ffff);
    const Color collapsedTextColor = Color(0xffff00ff);

    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: ExpansionTile(
          iconColor: iconColor,
          collapsedIconColor: collapsedIconColor,
          textColor: textColor,
          collapsedTextColor: collapsedTextColor,
          title: TestText('title'),
          trailing: TestIcon(),
          children: <Widget>[
            SizedBox(height: 100, width: 100),
          ],
        ),
      ),
    ));

    Color getIconColor() => tester.state<TestIconState>(find.byType(TestIcon)).iconTheme.color!;
    Color getTextColor() => tester.state<TestTextState>(find.byType(TestText)).textStyle.color!;

    expect(getIconColor(), collapsedIconColor);
    expect(getTextColor(), collapsedTextColor);

    await tester.tap(find.text('title'));
    await tester.pumpAndSettle();

    expect(getIconColor(), iconColor);
    expect(getTextColor(), textColor);
  });

  testWidgets('ExpansionTile Border', (WidgetTester tester) async {
    const Key expansionTileKey = PageStorageKey<String>('expansionTile');

    const Border collapsedShape = Border(
      top: BorderSide(color: Colors.blue),
      bottom: BorderSide(color: Colors.green)
    );
    final Border shape = Border.all(color: Colors.red);

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ExpansionTile(
                key: expansionTileKey,
                title: const Text('ExpansionTile'),
                collapsedShape: collapsedShape,
                shape: shape,
                children: const <Widget>[
                  ListTile(
                    title: Text('0'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));

    Container getContainer(Key key) => tester.firstWidget(find.descendant(
      of: find.byKey(key),
      matching: find.byType(Container),
    ));

    // expansionTile should be Collapsed now.
    ShapeDecoration expandedContainerDecoration = getContainer(expansionTileKey).decoration! as ShapeDecoration;
    expect(expandedContainerDecoration.shape, collapsedShape);

    await tester.tap(find.text('ExpansionTile'));
    await tester.pumpAndSettle();

    // expansionTile should be Expanded now.
    expandedContainerDecoration = getContainer(expansionTileKey).decoration! as ShapeDecoration;
    expect(expandedContainerDecoration.shape, shape);
  });

  testWidgets('ExpansionTile platform controlAffinity test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: ExpansionTile(
          title: Text('Title'),
        ),
      ),
    ));

    final ListTile listTile = tester.widget(find.byType(ListTile));
    expect(listTile.leading, isNull);
    expect(listTile.trailing.runtimeType, RotationTransition);
  });

  testWidgets('ExpansionTile trailing controlAffinity test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: ExpansionTile(
          title: Text('Title'),
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      ),
    ));

    final ListTile listTile = tester.widget(find.byType(ListTile));
    expect(listTile.leading, isNull);
    expect(listTile.trailing.runtimeType, RotationTransition);
  });

  testWidgets('ExpansionTile leading controlAffinity test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: ExpansionTile(
          title: Text('Title'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ));

    final ListTile listTile = tester.widget(find.byType(ListTile));
    expect(listTile.leading.runtimeType, RotationTransition);
    expect(listTile.trailing, isNull);
  });

  testWidgets('ExpansionTile override rotating icon test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: ExpansionTile(
          title: Text('Title'),
          leading: Icon(Icons.info),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ));

    final ListTile listTile = tester.widget(find.byType(ListTile));
    expect(listTile.leading.runtimeType, Icon);
    expect(listTile.trailing, isNull);
  });

  group('Material 2', () {
    // Tests that are only relevant for Material 2. Once ThemeData.useMaterial3
    // is turned on by default, these tests can be removed.

    testWidgets('ExpansionTile default iconColor, textColor', (WidgetTester tester) async {
      final ThemeData theme = ThemeData(useMaterial3: false);

      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Material(
          child: ExpansionTile(
            title: TestText('title'),
            trailing: TestIcon(),
            children: <Widget>[
              SizedBox(height: 100, width: 100),
            ],
          ),
        ),
      ));

      Color getIconColor() => tester.state<TestIconState>(find.byType(TestIcon)).iconTheme.color!;
      Color getTextColor() => tester.state<TestTextState>(find.byType(TestText)).textStyle.color!;

      expect(getIconColor(), theme.unselectedWidgetColor);
      expect(getTextColor(), theme.textTheme.titleMedium!.color);

      await tester.tap(find.text('title'));
      await tester.pumpAndSettle();

      expect(getIconColor(), theme.colorScheme.primary);
      expect(getTextColor(), theme.colorScheme.primary);
    });
  });

  testWidgets('ExpansionTileController isExpanded, expand() and collapse()', (WidgetTester tester) async {
    final ExpansionTileController controller = ExpansionTileController();

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ExpansionTile(
          controller: controller,
          title: const Text('Title'),
          children: const <Widget>[
            Text('Child 0'),
          ],
        ),
      ),
    ));

    expect(find.text('Child 0'), findsNothing);
    expect(controller.isExpanded, isFalse);
    controller.expand();
    expect(controller.isExpanded, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Child 0'), findsOneWidget);
    expect(controller.isExpanded, isTrue);
    controller.collapse();
    expect(controller.isExpanded, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Child 0'), findsNothing);
  });

  testWidgets('Calling ExpansionTileController.expand/collapsed has no effect if it is already expanded/collapsed', (WidgetTester tester) async {
    final ExpansionTileController controller = ExpansionTileController();

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ExpansionTile(
          controller: controller,
          title: const Text('Title'),
          initiallyExpanded: true,
          children: const <Widget>[
            Text('Child 0'),
          ],
        ),
      ),
    ));

    expect(find.text('Child 0'), findsOneWidget);
    expect(controller.isExpanded, isTrue);
    controller.expand();
    expect(controller.isExpanded, isTrue);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('Child 0'), findsOneWidget);
    controller.collapse();
    expect(controller.isExpanded, isFalse);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(controller.isExpanded, isFalse);
    expect(find.text('Child 0'), findsNothing);
    controller.collapse();
    expect(controller.isExpanded, isFalse);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Call to ExpansionTileController.of()', (WidgetTester tester) async {
    final GlobalKey titleKey = GlobalKey();
    final GlobalKey childKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('Title', key: titleKey),
          children: <Widget>[
            Text('Child 0', key: childKey),
          ],
        ),
      ),
    ));

    final ExpansionTileController controller1 = ExpansionTileController.of(childKey.currentContext!);
    expect(controller1.isExpanded, isTrue);

    final ExpansionTileController controller2 = ExpansionTileController.of(titleKey.currentContext!);
    expect(controller2.isExpanded, isTrue);

    expect(controller1, controller2);
  });

  testWidgets('Call to ExpansionTile.maybeOf()', (WidgetTester tester) async {
    final GlobalKey titleKey = GlobalKey();
    final GlobalKey nonDescendantKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Column(
          children: <Widget>[
            ExpansionTile(
              title: Text('Title', key: titleKey),
              children: const <Widget>[
                Text('Child 0'),
              ],
            ),
            Text('Non descendant', key: nonDescendantKey),
          ],
        ),
      ),
    ));

    final ExpansionTileController? controller1 = ExpansionTileController.maybeOf(titleKey.currentContext!);
    expect(controller1, isNotNull);
    expect(controller1?.isExpanded, isFalse);

    final ExpansionTileController? controller2 = ExpansionTileController.maybeOf(nonDescendantKey.currentContext!);
    expect(controller2, isNull);
  });
}
