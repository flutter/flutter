// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Custom selected and unselected textStyles are honored', (WidgetTester tester) async {
    const TextStyle selectedTextStyle = TextStyle(fontWeight: FontWeight.w300, fontSize: 17.0);
    const TextStyle unselectedTextStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0);

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: selectedTextStyle,
        unselectedLabelTextStyle: unselectedTextStyle,
      ),
    );

    final TextStyle actualSelectedTextStyle = tester.renderObject<RenderParagraph>(find.text('Abc')).text.style;
    final TextStyle actualUnselectedTextStyle = tester.renderObject<RenderParagraph>(find.text('Def')).text.style;
    expect(actualSelectedTextStyle.fontSize, equals(selectedTextStyle.fontSize));
    expect(actualSelectedTextStyle.fontWeight, equals(selectedTextStyle.fontWeight));
    expect(actualUnselectedTextStyle.fontSize, equals(actualUnselectedTextStyle.fontSize));
    expect(actualUnselectedTextStyle.fontWeight, equals(actualUnselectedTextStyle.fontWeight));
  });

  testWidgets('Custom selected and unselected iconThemes are honored', (WidgetTester tester) async {
    const IconThemeData selectedIconTheme = IconThemeData(size: 36, color: Color(0x00000001));
    const IconThemeData unselectedIconTheme = IconThemeData(size: 18, color: Color(0x00000002));

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: selectedIconTheme,
        unselectedIconTheme: unselectedIconTheme,
      ),
    );

    final TextStyle actualSelectedIconTheme = _iconStyle(tester, Icons.favorite);
    final TextStyle actualUnselectedIconTheme = _iconStyle(tester, Icons.bookmark_border);
    expect(actualSelectedIconTheme.color, equals(selectedIconTheme.color));
    expect(actualSelectedIconTheme.fontSize, equals(selectedIconTheme.size));
    expect(actualUnselectedIconTheme.color, equals(unselectedIconTheme.color));
    expect(actualUnselectedIconTheme.fontSize, equals(unselectedIconTheme.size));
  });

  testWidgets('backgroundColor can be changed', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    expect(_railMaterial(tester).color, equals(Colors.white));

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.green,
      ),
    );

    expect(_railMaterial(tester).color, equals(Colors.green));
  });

  testWidgets('elevation can be changed', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    expect(_railMaterial(tester).elevation, equals(0));

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
        elevation: 7,
      ),
    );

    expect(_railMaterial(tester).elevation, equals(7));
  });

  testWidgets('Renders at the correct default width - [labelType]=none (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);
  });

  testWidgets('Renders at the correct default width - [labelType]=selected', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        labelType: NavigationRailLabelType.selected,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);
  });

  testWidgets('Renders at the correct default width - [labelType]=all', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        labelType: NavigationRailLabelType.all,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);
  });

  testWidgets('Renders wider for a destination with a long label - [labelType]=all', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        labelType: NavigationRailLabelType.all,
        destinations: const <NavigationRailDestination>[
          NavigationRailDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: Text('Abc'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: Text('Longer Label'),
          ),
        ],
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    // Total padding is 16 (8 on each side).
    expect(renderBox.size.width, _labelRenderBox(tester, 'Longer Label').size.width + 16.0);
  });

  testWidgets('Renders only icons - [labelType]=none (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.hotel), findsOneWidget);

    // When there are no labels, a 0 opacity label is still shown for semantics.
    expect(_labelOpacity(tester, 'Abc'), 0);
    expect(_labelOpacity(tester, 'Def'), 0);
    expect(_labelOpacity(tester, 'Ghi'), 0);
    expect(_labelOpacity(tester, 'Jkl'), 0);
  });

  testWidgets('Renders icons and labels - [labelType]=all', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.hotel), findsOneWidget);

    expect(find.text('Abc'), findsOneWidget);
    expect(find.text('Def'), findsOneWidget);
    expect(find.text('Ghi'), findsOneWidget);
    expect(find.text('Jkl'), findsOneWidget);

    // When displaying all labels, there is no opacity.
    expect(_opacityAboveLabel('Abc'), findsNothing);
    expect(_opacityAboveLabel('Def'), findsNothing);
    expect(_opacityAboveLabel('Ghi'), findsNothing);
    expect(_opacityAboveLabel('Jkl'), findsNothing);
  });

  testWidgets('Renders icons and selected label - [labelType]=selected', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.hotel), findsOneWidget);

    // Only the selected label is visible.
    expect(_labelOpacity(tester, 'Abc'), 1);
    expect(_labelOpacity(tester, 'Def'), 0);
    expect(_labelOpacity(tester, 'Ghi'), 0);
    expect(_labelOpacity(tester, 'Jkl'), 0);
  });

  testWidgets('Destination spacing is correct - [labelType]=none (default), [textScaleFactor]=1.0 (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=none (default), [textScaleFactor]=3.0', (WidgetTester tester) async {
    // Since the rail is icon only, its destinations should not be affected by
    // textScaleFactor.
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=none (default), [textScaleFactor]=0.75', (WidgetTester tester) async {
    // Since the rail is icon only, its destinations should not be affected by
    // textScaleFactor.
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 0.75,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=selected, [textScaleFactor]=1.0 (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height - firstLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstLabelRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 + firstIconRenderBox.size.height - firstLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=selected, [textScaleFactor]=3.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    // The rail and destinations sizes grow to fit the larger text labels.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 142.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );

    // The first label sits right below the first icon.
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - firstLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + firstIconRenderBox.size.height,
        ),
      ),
    );

    nextDestinationY += 16.0 + firstIconRenderBox.size.height + firstLabelRenderBox.size.height + 16.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + 24.0,
        ),
      ),
    );

    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + 24.0,
        ),
      ),
    );

    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + 24.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=selected, [textScaleFactor]=0.75', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 0.75,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    // A smaller textScaleFactor will not reduce the default width of the rail
    // since there is a minWidth.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height - firstLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstLabelRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 + firstIconRenderBox.size.height - firstLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(Offset(
        (72.0 - fourthIconRenderBox.size.width) / 2.0,
        nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
      )),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=all, [textScaleFactor]=1.0 (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + firstIconRenderBox.size.height,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    final RenderBox secondLabelRenderBox = _labelRenderBox(tester, 'Def');
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      secondLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + secondIconRenderBox.size.height,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    final RenderBox thirdLabelRenderBox = _labelRenderBox(tester, 'Ghi');
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      thirdLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + thirdIconRenderBox.size.height,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    final RenderBox fourthLabelRenderBox = _labelRenderBox(tester, 'Jkl');
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      fourthLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + fourthIconRenderBox.size.height,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=all, [textScaleFactor]=3.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    // The rail and destinations sizes grow to fit the larger text labels.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 142.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - firstLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + firstIconRenderBox.size.height,
        ),
      ),
    );

    nextDestinationY += 16.0 + firstIconRenderBox.size.height + firstLabelRenderBox.size.height + 16.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    final RenderBox secondLabelRenderBox = _labelRenderBox(tester, 'Def');
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      secondLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - secondLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + secondIconRenderBox.size.height,
        ),
      ),
    );

    nextDestinationY += 16.0 + secondIconRenderBox.size.height + secondLabelRenderBox.size.height + 16.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    final RenderBox thirdLabelRenderBox = _labelRenderBox(tester, 'Ghi');
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      thirdLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - thirdLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + thirdIconRenderBox.size.height,
        ),
      ),
    );

    nextDestinationY += 16.0 + thirdIconRenderBox.size.height + thirdLabelRenderBox.size.height + 16.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    final RenderBox fourthLabelRenderBox = _labelRenderBox(tester, 'Jkl');
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      fourthLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (142.0 - fourthLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + fourthIconRenderBox.size.height,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=all, [textScaleFactor]=0.75', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 0.75,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    // A smaller textScaleFactor will not reduce the default size of the rail.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + firstIconRenderBox.size.height,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    final RenderBox secondLabelRenderBox = _labelRenderBox(tester, 'Def');
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      secondLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + secondIconRenderBox.size.height,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    final RenderBox thirdLabelRenderBox = _labelRenderBox(tester, 'Ghi');
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      thirdLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + thirdIconRenderBox.size.height,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    final RenderBox fourthLabelRenderBox = _labelRenderBox(tester, 'Jkl');
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0,
        ),
      ),
    );
    expect(
      fourthLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthLabelRenderBox.size.width) / 2.0,
          nextDestinationY + 16.0 + fourthIconRenderBox.size.height,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct for a compact rail - [preferredWidth]=56, [textScaleFactor]=1.0 (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        minWidth: 56.0,
        destinations: _destinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 56.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 56 below the first destination.
    nextDestinationY += 56.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 56 below the second destination.
    nextDestinationY += 56.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 56 below the third destination.
    nextDestinationY += 56.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct for a compact rail - [preferredWidth]=56, [textScaleFactor]=3.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        minWidth: 56.0,
        destinations: _destinations(),
      ),
    );

    // Since the rail is icon only, its preferred width should not be affected
    // by  textScaleFactor.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 56.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 56 below the first destination.
    nextDestinationY += 56.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 56 below the second destination.
    nextDestinationY += 56.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 56 below the third destination.
    nextDestinationY += 56.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Destination spacing is correct for a compact rail - [preferredWidth]=56, [textScaleFactor]=0.75', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        minWidth: 56.0,
        destinations: _destinations(),
      ),
    );

    // Since the rail is icon only, its preferred width should not be affected
    // by  textScaleFactor.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 56.0);

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 56 below the first destination.
    nextDestinationY += 56.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 56 below the second destination.
    nextDestinationY += 56.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 56 below the third destination.
    nextDestinationY += 56.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (56.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (56.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Group alignment works - [groupAlignment]=-1.0 (default)', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
      ),
    );

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Group alignment works - [groupAlignment]=0.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        groupAlignment: 0.0,
        destinations: _destinations(),
      ),
    );

    double nextDestinationY = 160.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Group alignment works - [groupAlignment]=1.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        groupAlignment: 1.0,
        destinations: _destinations(),
      ),
    );

    double nextDestinationY = 312.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Leading and trailing appear in the correct places', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        leading: FloatingActionButton(onPressed: () { }),
        trailing: FloatingActionButton(onPressed: () { }),
        destinations: _destinations(),
      ),
    );

    final RenderBox leading = tester.renderObject<RenderBox>(find.byType(FloatingActionButton).at(0));
    final RenderBox trailing = tester.renderObject<RenderBox>(find.byType(FloatingActionButton).at(1));
    expect(leading.localToGlobal(Offset.zero), const Offset(0.0, 8.0));
    expect(trailing.localToGlobal(Offset.zero), const Offset(0.0, 360.0));
  });

  testWidgets('Extended rail animates the width and labels appear - [textDirection]=LTR', (WidgetTester tester) async {
    bool extended = false;
    StateSetter stateSetter;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return Scaffold(
              body: Row(
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: 0,
                    destinations: _destinations(),
                    extended: extended,
                  ),
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final RenderBox rail = tester.firstRenderObject<RenderBox>(find.byType(NavigationRail));

    expect(rail.size.width, equals(72.0));

    stateSetter(() {
      extended = true;
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(rail.size.width, equals(164.0));

    await tester.pumpAndSettle();
    expect(rail.size.width, equals(256.0));

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          72.0,
          nextDestinationY + (72.0 - firstLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    final RenderBox secondLabelRenderBox = _labelRenderBox(tester, 'Def');
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      secondLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          72.0,
          nextDestinationY + (72.0 - secondLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    final RenderBox thirdLabelRenderBox = _labelRenderBox(tester, 'Ghi');
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      thirdLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          72.0,
          nextDestinationY + (72.0 - thirdLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    final RenderBox fourthLabelRenderBox = _labelRenderBox(tester, 'Jkl');
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          (72.0 - fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      fourthLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          72.0,
          nextDestinationY + (72.0 - fourthLabelRenderBox.size.height) / 2.0,
        ),
      ),
    );
  });

  testWidgets('Extended rail animates the width and labels appear - [textDirection]=RTL', (WidgetTester tester) async {
    bool extended = false;
    StateSetter stateSetter;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Row(
                  textDirection: TextDirection.rtl,
                  children: <Widget>[
                    NavigationRail(
                      selectedIndex: 0,
                      destinations: _destinations(),
                      extended: extended,
                    ),
                    const Expanded(
                      child: Text('body'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    final RenderBox rail = tester.firstRenderObject<RenderBox>(find.byType(NavigationRail));

    expect(rail.size.width, equals(72.0));
    expect(rail.localToGlobal(Offset.zero), equals(const Offset(728.0, 0.0)));

    stateSetter(() {
      extended = true;
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(rail.size.width, equals(164.0));
    expect(rail.localToGlobal(Offset.zero), equals(const Offset(636.0, 0.0)));

    await tester.pumpAndSettle();
    expect(rail.size.width, equals(256.0));
    expect(rail.localToGlobal(Offset.zero), equals(const Offset(544.0, 0.0)));

    // The first destination is 8 from the top because of the default vertical
    // padding at the to of the rail.
    double nextDestinationY = 8.0;
    final RenderBox firstIconRenderBox = _iconRenderBox(tester, Icons.favorite);
    final RenderBox firstLabelRenderBox = _labelRenderBox(tester, 'Abc');
    expect(
      firstIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - (72.0 + firstIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - firstIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      firstLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - 72.0 - firstLabelRenderBox.size.width,
          nextDestinationY + (72.0 - firstLabelRenderBox.size.height)  / 2.0,
        ),
      ),
    );

    // The second destination is 72 below the first destination.
    nextDestinationY += 72.0;
    final RenderBox secondIconRenderBox = _iconRenderBox(tester, Icons.bookmark_border);
    final RenderBox secondLabelRenderBox = _labelRenderBox(tester, 'Def');
    expect(
      secondIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - (72.0 + secondIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - secondIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      secondLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - 72.0 - secondLabelRenderBox.size.width,
          nextDestinationY + (72.0 - secondLabelRenderBox.size.height)  / 2.0,
        ),
      ),
    );

    // The third destination is 72 below the second destination.
    nextDestinationY += 72.0;
    final RenderBox thirdIconRenderBox = _iconRenderBox(tester, Icons.star_border);
    final RenderBox thirdLabelRenderBox = _labelRenderBox(tester, 'Ghi');
    expect(
      thirdIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - (72.0 + thirdIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - thirdIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      thirdLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - 72.0 - thirdLabelRenderBox.size.width,
          nextDestinationY + (72.0 - thirdLabelRenderBox.size.height)  / 2.0,
        ),
      ),
    );

    // The fourth destination is 72 below the third destination.
    nextDestinationY += 72.0;
    final RenderBox fourthIconRenderBox = _iconRenderBox(tester, Icons.hotel);
    final RenderBox fourthLabelRenderBox = _labelRenderBox(tester, 'Jkl');
    expect(
      fourthIconRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - (72.0 + fourthIconRenderBox.size.width) / 2.0,
          nextDestinationY + (72.0 - fourthIconRenderBox.size.height) / 2.0,
        ),
      ),
    );
    expect(
      fourthLabelRenderBox.localToGlobal(Offset.zero),
      equals(
        Offset(
          800.0 - 72.0 - fourthLabelRenderBox.size.width,
          nextDestinationY + (72.0 - fourthLabelRenderBox.size.height)  / 2.0,
        ),
      ),
    );
  });

  testWidgets('Extended rail gets wider with longer labels are larger text scale', (WidgetTester tester) async {
    bool extended = false;
    StateSetter stateSetter;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return Scaffold(
              body: Row(
                children: <Widget>[
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
                    child: NavigationRail(
                      selectedIndex: 0,
                      destinations: const <NavigationRailDestination>[
                        NavigationRailDestination(
                          icon: Icon(Icons.favorite_border),
                          selectedIcon: Icon(Icons.favorite),
                          label: Text('Abc'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.bookmark_border),
                          selectedIcon: Icon(Icons.bookmark),
                          label: Text('Longer Label'),
                        ),
                      ],
                      extended: extended,
                    ),
                  ),
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final RenderBox rail = tester.firstRenderObject<RenderBox>(find.byType(NavigationRail));

    expect(rail.size.width, equals(72.0));

    stateSetter(() {
      extended = true;
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(rail.size.width, equals(332.0));

    await tester.pumpAndSettle();
    expect(rail.size.width, equals(584.0));
  });

  testWidgets('Extended rail final width can be changed', (WidgetTester tester) async {
    bool extended = false;
    StateSetter stateSetter;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return Scaffold(
              body: Row(
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: 0,
                    minExtendedWidth: 300,
                    destinations: _destinations(),
                    extended: extended,
                  ),
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final RenderBox rail = tester.firstRenderObject<RenderBox>(find.byType(NavigationRail));

    expect(rail.size.width, equals(72.0));

    stateSetter(() {
      extended = true;
    });

    await tester.pumpAndSettle();
    expect(rail.size.width, equals(300.0));
  });

  testWidgets('Extended rail animation can be consumed', (WidgetTester tester) async {
    bool extended = false;
    Animation<double> animation;
    StateSetter stateSetter;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return Scaffold(
              body: Row(
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: 0,
                    leading: Builder(
                      builder: (BuildContext context) {
                        animation = NavigationRail.extendedAnimation(context);
                        return FloatingActionButton(onPressed: () { },);
                      },
                    ),
                    destinations: _destinations(),
                    extended: extended,
                  ),
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(animation.isDismissed, isTrue);

    stateSetter(() {
      extended = true;
    });
    await tester.pumpAndSettle();

    expect(animation.isCompleted, isTrue);
  });

  testWidgets('onDestinationSelected is called', (WidgetTester tester) async {
    int selectedIndex;

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: _destinations(),
        onDestinationSelected: (int index) {
          selectedIndex = index;
        },
        labelType: NavigationRailLabelType.all,
      ),
    );

    await tester.tap(find.text('Def'));
    expect(selectedIndex, 1);

    await tester.tap(find.text('Ghi'));
    expect(selectedIndex, 2);
  });

  testWidgets('Changing destinations animate when [labelType]=selected', (WidgetTester tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: Row(
                children: <Widget>[
                  NavigationRail(
                    destinations: _destinations(),
                    selectedIndex: selectedIndex,
                    labelType: NavigationRailLabelType.selected,
                    onDestinationSelected: (int index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Tap the second destination.
    await tester.tap(find.byIcon(Icons.bookmark_border));
    expect(selectedIndex, 1);

    // The second destination animates in.
    expect(_labelOpacity(tester, 'Def'), equals(0.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_labelOpacity(tester, 'Def'), equals(0.5));
    await tester.pumpAndSettle();
    expect(_labelOpacity(tester, 'Def'), equals(1.0));

    // Tap the third destination.
    await tester.tap(find.byIcon(Icons.star_border));
    expect(selectedIndex, 2);

    // The second destination animates out quickly and the third destination
    // animates in.
    expect(_labelOpacity(tester, 'Ghi'), equals(0.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(_labelOpacity(tester, 'Def'), equals(0.5));
    expect(_labelOpacity(tester, 'Ghi'), equals(0.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(_labelOpacity(tester, 'Def'), equals(0.0));
    expect(_labelOpacity(tester, 'Ghi'), equals(0.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_labelOpacity(tester, 'Ghi'), equals(0.5));
    await tester.pumpAndSettle();
    expect(_labelOpacity(tester, 'Ghi'), equals(1.0));
  });

  testWidgets('Semantics - labelType=[none]', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await _pumpLocalizedTestRail(tester, labelType: NavigationRailLabelType.none);

    expect(semantics, hasSemantics(_expectedSemantics(), ignoreId: true, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Semantics - labelType=[selected]', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await _pumpLocalizedTestRail(tester, labelType: NavigationRailLabelType.selected);

    expect(semantics, hasSemantics(_expectedSemantics(), ignoreId: true, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Semantics - labelType=[all]', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await _pumpLocalizedTestRail(tester, labelType: NavigationRailLabelType.all);

    expect(semantics, hasSemantics(_expectedSemantics(), ignoreId: true, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Semantics - extended', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await _pumpLocalizedTestRail(tester, extended: true);

    expect(semantics, hasSemantics(_expectedSemantics(), ignoreId: true, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });
}

TestSemantics _expectedSemantics() {
  return TestSemantics.root(
    children: <TestSemantics>[
      TestSemantics(
        textDirection: TextDirection.ltr,
        children: <TestSemantics>[
          TestSemantics(
            children: <TestSemantics>[
              TestSemantics(
                flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                children: <TestSemantics>[
                  TestSemantics(
                    flags: <SemanticsFlag>[
                      SemanticsFlag.isSelected,
                      SemanticsFlag.isFocusable,
                    ],
                    actions: <SemanticsAction>[SemanticsAction.tap],
                    label: 'Abc\nTab 1 of 4',
                    textDirection: TextDirection.ltr,
                  ),
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                    actions: <SemanticsAction>[SemanticsAction.tap],
                    label: 'Def\nTab 2 of 4',
                    textDirection: TextDirection.ltr,
                  ),
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                    actions: <SemanticsAction>[SemanticsAction.tap],
                    label: 'Ghi\nTab 3 of 4',
                    textDirection: TextDirection.ltr,
                  ),
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                    actions: <SemanticsAction>[SemanticsAction.tap],
                    label: 'Jkl\nTab 4 of 4',
                    textDirection: TextDirection.ltr,
                  ),
                  TestSemantics(
                    label: 'body',
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

List<NavigationRailDestination> _destinations() {
  return const <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: Text('Abc'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bookmark_border),
      selectedIcon: Icon(Icons.bookmark),
      label: Text('Def'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.star_border),
      selectedIcon: Icon(Icons.star),
      label: Text('Ghi'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.hotel),
      selectedIcon: Icon(Icons.home),
      label: Text('Jkl'),
    ),
  ];
}

Future<void> _pumpNavigationRail(
  WidgetTester tester, {
  double textScaleFactor = 1.0,
  NavigationRail navigationRail,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
            child: Scaffold(
              body: Row(
                children: <Widget>[
                  navigationRail,
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _pumpLocalizedTestRail(WidgetTester tester, { NavigationRailLabelType labelType, bool extended = false }) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: 0,
                extended: extended,
                destinations: _destinations(),
                labelType: labelType,
              ),
              const Expanded(
                child: Text('body'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

RenderBox _iconRenderBox(WidgetTester tester, IconData iconData) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byIcon(iconData),
      matching: find.byType(RichText),
    ),
  );
}

RenderBox _labelRenderBox(WidgetTester tester, String text) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.text(text),
      matching: find.byType(RichText),
    ),
  );
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.byIcon(icon),
      matching: find.byType(RichText),
    ),
  ).text.style;
}

Finder _opacityAboveLabel(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(Opacity),
  );
}

// Only valid when labelType != all.
double _labelOpacity(WidgetTester tester, String text) {
  final Opacity opacityWidget = tester.widget<Opacity>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Opacity),
    ),
  );
  return opacityWidget.opacity;
}

Material _railMaterial(WidgetTester tester) {
  // The first material is for the rail, and the rest are for the destinations.
  return tester.firstWidget<Material>(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byType(Material),
    ),
  );
}