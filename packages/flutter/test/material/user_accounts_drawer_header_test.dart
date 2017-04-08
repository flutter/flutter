// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UserAccountsDrawerHeader test', (WidgetTester tester) async {
    final Key avatarA = const Key('A');
    final Key avatarC = const Key('C');
    final Key avatarD = const Key('D');

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new UserAccountsDrawerHeader(
            currentAccountPicture: new CircleAvatar(
              key: avatarA,
              child: const Text('A'),
            ),
            otherAccountsPictures: <Widget>[
              new CircleAvatar(
                child: const Text('B'),
              ),
              new CircleAvatar(
                key: avatarC,
                child: const Text('C'),
              ),
              new CircleAvatar(
                key: avatarD,
                child: const Text('D'),
              ),
              new CircleAvatar(
                child: const Text('E'),
              )
            ],
            accountName: const Text("name"),
            accountEmail: const Text("email"),
          ),
        ),
      ),
    );

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

    box = tester.renderObject(find.byType(UserAccountsDrawerHeader));
    expect(box.size.height, equals(160.0 + 8.0 + 1.0)); // height + bottom margin + bottom edge)

    final Point topLeft = tester.getTopLeft(find.byType(UserAccountsDrawerHeader));
    final Point topRight = tester.getTopRight(find.byType(UserAccountsDrawerHeader));

    final Point avatarATopLeft = tester.getTopLeft(find.byKey(avatarA));
    final Point avatarDTopRight = tester.getTopRight(find.byKey(avatarD));
    final Point avatarCTopRight = tester.getTopRight(find.byKey(avatarC));

    expect(avatarATopLeft.x - topLeft.x, equals(16.0));
    expect(avatarATopLeft.y - topLeft.y, equals(16.0));
    expect(topRight.x - avatarDTopRight.x, equals(16.0));
    expect(avatarDTopRight.y - topRight.y, equals(16.0));
    expect(avatarDTopRight.x - avatarCTopRight.x, equals(40.0 + 16.0)); // size + space between
  });


  testWidgets('UserAccountsDrawerHeader null parameters', (WidgetTester tester) async {
    Widget buildFrame({
      Widget currentAccountPicture,
      List<Widget> otherAccountsPictures,
      Widget accountName,
      Widget accountEmail,
      VoidCallback onDetailsPressed,
      EdgeInsets margin,
    }) {
      return new Material(
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
      tester.getCenter(find.text('accountName')).y,
      tester.getCenter(find.byType(Icon)).y
    );

    await tester.pumpWidget(buildFrame(
      accountEmail: const Text('accountEmail'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountEmail')).y,
      tester.getCenter(find.byType(Icon)).y
    );

    await tester.pumpWidget(buildFrame(
      accountName: const Text('accountName'),
      accountEmail: const Text('accountEmail'),
      onDetailsPressed: () { },
    ));
    expect(
      tester.getCenter(find.text('accountEmail')).y,
      tester.getCenter(find.byType(Icon)).y
    );
    expect(
      tester.getBottomLeft(find.text('accountEmail')).y,
      greaterThan(tester.getBottomLeft(find.text('accountName')).y)
    );
    expect(
      tester.getBottomLeft(find.text('accountEmail')).x,
      tester.getBottomLeft(find.text('accountName')).x
    );

    await tester.pumpWidget(buildFrame(
      currentAccountPicture: new CircleAvatar(child: const Text('A')),
    ));
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(buildFrame(
      otherAccountsPictures: <Widget>[new CircleAvatar(child: const Text('A'))],
    ));
    expect(find.text('A'), findsOneWidget);

    final Key avatarA = const Key('A');
    await tester.pumpWidget(buildFrame(
      currentAccountPicture: new CircleAvatar(key: avatarA, child: const Text('A')),
      accountName: const Text('accountName'),
    ));
    expect(
      tester.getBottomLeft(find.byKey(avatarA)).x,
      tester.getBottomLeft(find.text('accountName')).x
    );
    expect(
      tester.getBottomLeft(find.text('accountName')).y,
      greaterThan(tester.getBottomLeft(find.byKey(avatarA)).y)
    );
  });
}
