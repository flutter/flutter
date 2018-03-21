// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

const Key avatarA = const Key('A');
const Key avatarC = const Key('C');
const Key avatarD = const Key('D');

Future<Null> pumpTestWidget(WidgetTester tester, {
  bool withName: true,
  bool withEmail: true,
  bool withOnDetailsPressedHandler: true,
}) async {
  await tester.pumpWidget(
    new MaterialApp(
      home: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.only(
            left: 10.0,
            top: 20.0,
            right: 30.0,
            bottom: 40.0,
          ),
        ),
        child: new Material(
          child: new Center(
            child: new UserAccountsDrawerHeader(
              onDetailsPressed: withOnDetailsPressedHandler ? () {} : null,
              currentAccountPicture: const ExcludeSemantics(
                child: const CircleAvatar(
                  key: avatarA,
                  child: const Text('A'),
                ),
              ),
              otherAccountsPictures: const <Widget>[
                const CircleAvatar(
                  child: const Text('B'),
                ),
                const CircleAvatar(
                  key: avatarC,
                  child: const Text('C'),
                ),
                const CircleAvatar(
                  key: avatarD,
                  child: const Text('D'),
                ),
                const CircleAvatar(
                  child: const Text('E'),
                )
              ],
              accountName: withName ? const Text('name') : null,
              accountEmail: withEmail ? const Text('email') : null,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('UserAccountsDrawerHeader test', (WidgetTester tester) async {
    await pumpTestWidget(tester);

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('E'), findsNothing);

    expect(find.text('name'), findsOneWidget);
    expect(find.text('email'), findsOneWidget);

    RenderBox box = tester.renderObject(find.byKey(avatarA));
    expect(box.size.width, equals(72.0));
    expect(box.size.height, equals(72.0));

    box = tester.renderObject(find.byKey(avatarC));
    expect(box.size.width, equals(40.0));
    expect(box.size.height, equals(40.0));

    // Verify height = height + top padding + bottom margin + bottom edge)
    box = tester.renderObject(find.byType(UserAccountsDrawerHeader));
    expect(box.size.height, equals(160.0 + 20.0 + 8.0 + 1.0));

    final Offset topLeft = tester.getTopLeft(find.byType(UserAccountsDrawerHeader));
    final Offset topRight = tester.getTopRight(find.byType(UserAccountsDrawerHeader));

    final Offset avatarATopLeft = tester.getTopLeft(find.byKey(avatarA));
    final Offset avatarDTopRight = tester.getTopRight(find.byKey(avatarD));
    final Offset avatarCTopRight = tester.getTopRight(find.byKey(avatarC));

    expect(avatarATopLeft.dx - topLeft.dx, equals(16.0 + 10.0)); // left padding
    expect(avatarATopLeft.dy - topLeft.dy, equals(16.0 + 20.0)); // add top padding
    expect(topRight.dx - avatarDTopRight.dx, equals(16.0 + 30.0)); // right padding
    expect(avatarDTopRight.dy - topRight.dy, equals(16.0 + 20.0)); // add top padding
    expect(avatarDTopRight.dx - avatarCTopRight.dx, equals(40.0 + 16.0)); // size + space between
  });


  testWidgets('UserAccountsDrawerHeader null parameters LTR', (WidgetTester tester) async {
    Widget buildFrame({
      Widget currentAccountPicture,
      List<Widget> otherAccountsPictures,
      Widget accountName,
      Widget accountEmail,
      VoidCallback onDetailsPressed,
      EdgeInsets margin,
    }) {
      return new MaterialApp(
        home: new Material(
          child: new Center(
            child: new UserAccountsDrawerHeader(
              currentAccountPicture: currentAccountPicture,
              otherAccountsPictures: otherAccountsPictures,
              accountName: accountName,
              accountEmail: accountEmail,
              onDetailsPressed: onDetailsPressed,
              margin: margin,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    final RenderBox box = tester.renderObject(find.byType(UserAccountsDrawerHeader));
    expect(box.size.height, equals(160.0 + 1.0)); // height + bottom edge)
    expect(find.byType(Icon), findsNothing);

    await tester.pumpWidget(buildFrame(
      onDetailsPressed: () { },
    ));
    expect(find.byType(Icon), findsOneWidget);

    await tester.pumpWidget(buildFrame(
      accountName: const Text('accountName'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountName')).dy,
      tester.getCenter(find.byType(Icon)).dy
    );
    expect(
      tester.getCenter(find.text('accountName')).dx,
      lessThan(tester.getCenter(find.byType(Icon)).dx)
    );

    await tester.pumpWidget(buildFrame(
      accountEmail: const Text('accountEmail'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountEmail')).dy,
      tester.getCenter(find.byType(Icon)).dy
    );
    expect(
      tester.getCenter(find.text('accountEmail')).dx,
      lessThan(tester.getCenter(find.byType(Icon)).dx)
    );

    await tester.pumpWidget(buildFrame(
      accountName: const Text('accountName'),
      accountEmail: const Text('accountEmail'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountEmail')).dy,
      tester.getCenter(find.byType(Icon)).dy
    );
    expect(
      tester.getCenter(find.text('accountEmail')).dx,
      lessThan(tester.getCenter(find.byType(Icon)).dx)
    );
    expect(
      tester.getBottomLeft(find.text('accountEmail')).dy,
      greaterThan(tester.getBottomLeft(find.text('accountName')).dy)
    );
    expect(
      tester.getBottomLeft(find.text('accountEmail')).dx,
      tester.getBottomLeft(find.text('accountName')).dx
    );

    await tester.pumpWidget(buildFrame(
      currentAccountPicture: const CircleAvatar(child: const Text('A')),
    ));
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(buildFrame(
      otherAccountsPictures: <Widget>[const CircleAvatar(child: const Text('A'))],
    ));
    expect(find.text('A'), findsOneWidget);

    const Key avatarA = const Key('A');
    await tester.pumpWidget(buildFrame(
      currentAccountPicture: const CircleAvatar(key: avatarA, child: const Text('A')),
      accountName: const Text('accountName'),
    ));
    expect(
      tester.getBottomLeft(find.byKey(avatarA)).dx,
      tester.getBottomLeft(find.text('accountName')).dx
    );
    expect(
      tester.getBottomLeft(find.text('accountName')).dy,
      greaterThan(tester.getBottomLeft(find.byKey(avatarA)).dy)
    );
  });

  testWidgets('UserAccountsDrawerHeader null parameters RTL', (WidgetTester tester) async {
    Widget buildFrame({
      Widget currentAccountPicture,
      List<Widget> otherAccountsPictures,
      Widget accountName,
      Widget accountEmail,
      VoidCallback onDetailsPressed,
      EdgeInsets margin,
    }) {
      return new MaterialApp(
        home: new Directionality(
          textDirection: TextDirection.rtl,
          child: new Material(
            child: new Center(
              child: new UserAccountsDrawerHeader(
                currentAccountPicture: currentAccountPicture,
                otherAccountsPictures: otherAccountsPictures,
                accountName: accountName,
                accountEmail: accountEmail,
                onDetailsPressed: onDetailsPressed,
                margin: margin,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    final RenderBox box = tester.renderObject(find.byType(UserAccountsDrawerHeader));
    expect(box.size.height, equals(160.0 + 1.0)); // height + bottom edge)
    expect(find.byType(Icon), findsNothing);

    await tester.pumpWidget(buildFrame(
      onDetailsPressed: () { },
    ));
    expect(find.byType(Icon), findsOneWidget);

    await tester.pumpWidget(buildFrame(
      accountName: const Text('accountName'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountName')).dy,
      tester.getCenter(find.byType(Icon)).dy
    );
    expect(
      tester.getCenter(find.text('accountName')).dx,
      greaterThan(tester.getCenter(find.byType(Icon)).dx)
    );

    await tester.pumpWidget(buildFrame(
      accountEmail: const Text('accountEmail'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountEmail')).dy,
      tester.getCenter(find.byType(Icon)).dy
    );
    expect(
      tester.getCenter(find.text('accountEmail')).dx,
      greaterThan(tester.getCenter(find.byType(Icon)).dx)
    );

    await tester.pumpWidget(buildFrame(
      accountName: const Text('accountName'),
      accountEmail: const Text('accountEmail'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountEmail')).dy,
      tester.getCenter(find.byType(Icon)).dy
    );
    expect(
      tester.getCenter(find.text('accountEmail')).dx,
      greaterThan(tester.getCenter(find.byType(Icon)).dx)
    );
    expect(
      tester.getBottomLeft(find.text('accountEmail')).dy,
      greaterThan(tester.getBottomLeft(find.text('accountName')).dy)
    );
    expect(
      tester.getBottomRight(find.text('accountEmail')).dx,
      tester.getBottomRight(find.text('accountName')).dx
    );

    await tester.pumpWidget(buildFrame(
      currentAccountPicture: const CircleAvatar(child: const Text('A')),
    ));
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(buildFrame(
      otherAccountsPictures: <Widget>[const CircleAvatar(child: const Text('A'))],
    ));
    expect(find.text('A'), findsOneWidget);

    const Key avatarA = const Key('A');
    await tester.pumpWidget(buildFrame(
      currentAccountPicture: const CircleAvatar(key: avatarA, child: const Text('A')),
      accountName: const Text('accountName'),
    ));
    expect(
      tester.getBottomRight(find.byKey(avatarA)).dx,
      tester.getBottomRight(find.text('accountName')).dx
    );
    expect(
      tester.getBottomLeft(find.text('accountName')).dy,
      greaterThan(tester.getBottomLeft(find.byKey(avatarA)).dy)
    );
  });

  testWidgets('UserAccountsDrawerHeader provides semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await pumpTestWidget(tester);

    expect(
      semantics,
      hasSemantics(
        new TestSemantics(
          children: <TestSemantics>[
            new TestSemantics(
              label: 'Signed in\nname\nemail',
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                new TestSemantics(
                  label: r'B',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  label: r'C',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  label: r'D',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.isButton],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: r'Show accounts',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
        ignoreId: true, ignoreTransform: true, ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('UserAccountsDrawerHeader provides semantics with missing properties', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await pumpTestWidget(
      tester,
      withEmail: false,
      withName: false,
      withOnDetailsPressedHandler: false,
    );

    expect(
      semantics,
      hasSemantics(
        new TestSemantics(
          children: <TestSemantics>[
            new TestSemantics(
              label: 'Signed in',
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                new TestSemantics(
                  label: r'B',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  label: r'C',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  label: r'D',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
        ignoreId: true, ignoreTransform: true, ignoreRect: true,
      ),
    );

    semantics.dispose();
  });
}
