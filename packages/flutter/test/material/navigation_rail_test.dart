import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Renders at the correct default width', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);
  });

  testWidgets('Renders only icons - [labelType]=none ', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.hotel), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle), findsOneWidget);
  });

  testWidgets('Renders icons and labels - [labelType]=all', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.hotel), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle), findsOneWidget);

    expect(find.text('Abc'), findsOneWidget);
    expect(find.text('Def'), findsOneWidget);
    expect(find.text('Ghi'), findsOneWidget);
    expect(find.text('Jkl'), findsOneWidget);
    expect(find.text('Mno'), findsOneWidget);
  });

  testWidgets('Renders icons and selected label - [labelType]=selected', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.hotel), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle), findsOneWidget);

    expect(_labelOpacity(tester, 'Abc'), 1);
    expect(_labelOpacity(tester, 'Def'), 0);
    expect(_labelOpacity(tester, 'Ghi'), 0);
    expect(_labelOpacity(tester, 'Jkl'), 0);
    expect(_labelOpacity(tester, 'Mno'), 0);
  });

  testWidgets('Destination spacing is correct - [labelType]=none, [textScaleFactor]=1.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.none,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    // The destination padding is 24, but the top has additional padding of 8.
    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 32.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 104.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 176.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 248.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 320.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=none, [textScaleFactor]=3.0', (WidgetTester tester) async {
    // Since the rail is icon only, its destinations should not be affected by
    // textScaleFactor.
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.none,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    // The destination padding is 24, but the top has additional padding of 8.
    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 32.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 104.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 176.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 248.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 320.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=none, [textScaleFactor]=0.75', (WidgetTester tester) async {
    // Since the rail is icon only, its destinations should not be affected by
    // textScaleFactor.
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 0.75,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.none,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    // The destination padding is 24, but the top has additional padding of 8.
    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 32.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 104.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 176.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 248.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 320.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=selected, [textScaleFactor]=1.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 24.0)),
    );
    expect(
      _labelRenderBox(tester, 'Abc').localToGlobal(Offset.zero),
      equals(const Offset(15.0, 48.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 104.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 176.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 248.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 320.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=selected, [textScaleFactor]=3.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    // The rail and destinations sizes grow to fit the larger text labels.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 142);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 24.0)),
    );
    expect(
      _labelRenderBox(tester, 'Abc').localToGlobal(Offset.zero),
      equals(const Offset(8.0, 48.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 130.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 202.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 274.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 346.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=selected, [textScaleFactor]=0.75', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 0.75,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.selected,
      ),
    );

    // A smaller textScaleFactor will not reduce the default size of the rail.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 24.0)),
    );

    expect(
      _labelRenderBox(tester, 'Abc').localToGlobal(Offset.zero),
      equals(const Offset(20.0, 48.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 104.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 176.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 248.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 320.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=all, [textScaleFactor]=1', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 24.0)),
    );
    expect(
      _labelRenderBox(tester, 'Abc').localToGlobal(Offset.zero),
      equals(const Offset(15.0, 48.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 96.0)),
    );
    expect(
      _labelRenderBox(tester, 'Def').localToGlobal(Offset.zero),
      equals(const Offset(15.0, 120.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 168.0)),
    );
    expect(
      _labelRenderBox(tester, 'Ghi').localToGlobal(Offset.zero),
      equals(const Offset(15.0, 192.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 240.0)),
    );
    expect(
      _labelRenderBox(tester, 'Jkl').localToGlobal(Offset.zero),
      equals(const Offset(15.0, 264.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 312.0)),
    );
    expect(
      _labelRenderBox(tester, 'Mno').localToGlobal(Offset.zero),
      equals(const Offset(15.0, 336.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=all, [textScaleFactor]=3.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    // The rail and destinations sizes grow to fit the larger text labels.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 142);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 24.0)),
    );
    expect(
      _labelRenderBox(tester, 'Abc').localToGlobal(Offset.zero),
      equals(const Offset(8.0, 48.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 122.0)),
    );
    expect(
      _labelRenderBox(tester, 'Def').localToGlobal(Offset.zero),
      equals(const Offset(8.0, 146.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 220.0)),
    );
    expect(
      _labelRenderBox(tester, 'Ghi').localToGlobal(Offset.zero),
      equals(const Offset(8.0, 244.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 318.0)),
    );
    expect(
      _labelRenderBox(tester, 'Jkl').localToGlobal(Offset.zero),
      equals(const Offset(8.0, 342.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(59.0, 416.0)),
    );
    expect(
      _labelRenderBox(tester, 'Mno').localToGlobal(Offset.zero),
      equals(const Offset(8.0, 440.0)),
    );
  });

  testWidgets('Destination spacing is correct - [labelType]=all, [textScaleFactor]=0.75', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 0.75,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    // A smaller textScaleFactor will not reduce the default size of the rail.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 24.0)),
    );
    expect(
      _labelRenderBox(tester, 'Abc').localToGlobal(Offset.zero),
      equals(const Offset(20.0, 48.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 96.0)),
    );
    expect(
      _labelRenderBox(tester, 'Def').localToGlobal(Offset.zero),
      equals(const Offset(20.0, 120.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 168.0)),
    );
    expect(
      _labelRenderBox(tester, 'Ghi').localToGlobal(Offset.zero),
      equals(const Offset(20.0, 192.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 240.0)),
    );
    expect(
      _labelRenderBox(tester, 'Jkl').localToGlobal(Offset.zero),
      equals(const Offset(20.0, 264.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 312.0)),
    );
    expect(
      _labelRenderBox(tester, 'Mno').localToGlobal(Offset.zero),
      equals(const Offset(20.0, 336.0)),
    );
  });

  testWidgets('Destination spacing is correct for a compact rail - [preferredWidth]=56, [textScaleFactor]=1.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        preferredWidth: 56,
        destinations: _testDestinations(),
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 56);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 24.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 80.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 136.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 192.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 248.0)),
    );
  });

  testWidgets('Destination spacing is correct for a compact rail - [preferredWidth]=56, [textScaleFactor]=3.0', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        preferredWidth: 56,
        destinations: _testDestinations(),
      ),
    );

    // Since the rail is icon only, its preferred width should not be affected
    // by  textScaleFactor.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 56);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 24.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 80.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 136.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 192.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 248.0)),
    );
  });

  testWidgets('Destination spacing is correct for a compact rail - [preferredWidth]=56, [textScaleFactor]=0.75', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      textScaleFactor: 3.0,
      navigationRail: NavigationRail(
        preferredWidth: 56,
        destinations: _testDestinations(),
      ),
    );

    // Since the rail is icon only, its preferred width should not be affected
    // by  textScaleFactor.
    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 56);

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 24.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 80.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 136.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 192.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(16.0, 248.0)),
    );
  });

  testWidgets('Group alignment works - [groupAlignment]=top', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        groupAlignment: NavigationRailGroupAlignment.top,
        destinations: _testDestinations(),
      ),
    );

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 32.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 104.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 176.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 248.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 320.0)),
    );
  });

  testWidgets('Group alignment works - [groupAlignment]=center', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        groupAlignment: NavigationRailGroupAlignment.center,
        destinations: _testDestinations(),
      ),
    );

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 148.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 220.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 292.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 364.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 436.0)),
    );
  });

  testWidgets('Group alignment works - [groupAlignment]=bottom', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        groupAlignment: NavigationRailGroupAlignment.bottom,
        destinations: _testDestinations(),
      ),
    );

    expect(
      _iconRenderBox(tester, Icons.favorite).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 264.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.bookmark_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 336.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.star_border).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 408.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.hotel).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 480.0)),
    );
    expect(
      _iconRenderBox(tester, Icons.remove_circle).localToGlobal(Offset.zero),
      equals(const Offset(24.0, 552.0)),
    );
  });

  testWidgets('Leading and trailing appear in the correct places', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        leading: FloatingActionButton(onPressed: () { }),
        trailing: FloatingActionButton(onPressed: () { }),
        destinations: _testDestinations(),
      ),
    );

    final RenderBox leading = tester.renderObject<RenderBox>(find.byType(FloatingActionButton).at(0));
    final RenderBox trailing = tester.renderObject<RenderBox>(find.byType(FloatingActionButton).at(1));
    expect(leading.localToGlobal(Offset.zero), const Offset(8.0, 8.0));
    expect(trailing.localToGlobal(Offset.zero), const Offset(8.0, 544.0));
  });

  testWidgets('Extended rail destinations appear correctly', (WidgetTester tester) async {
  });

  testWidgets('Extended rail width can be changed', (WidgetTester tester) async {
  });

  testWidgets('Extended rail animation can be consumed', (WidgetTester tester) async {
  });

  testWidgets('Custom selected and unselected textStyles are honored', (WidgetTester tester) async {
    const TextStyle selectedTextStyle = TextStyle(fontWeight: FontWeight.w300, fontSize: 17.0);
    const TextStyle unselectedTextStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0);

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
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
        destinations: _testDestinations(),
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

  testWidgets('Rail backgroundColor can be changed', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    expect(_railMaterial(tester).color, equals(Colors.white));

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.green,
      ),
    );

    expect(_railMaterial(tester).color, equals(Colors.green));
  });

  testWidgets('Rail elevation can be changed', (WidgetTester tester) async {
    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
      ),
    );

    expect(_railMaterial(tester).elevation, equals(0));

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        labelType: NavigationRailLabelType.all,
        elevation: 7,
      ),
    );

    expect(_railMaterial(tester).elevation, equals(7));
  });

  testWidgets('onDestinationSelected is called', (WidgetTester tester) async {
    int mutatedIndex;

    await _pumpNavigationRail(
      tester,
      navigationRail: NavigationRail(
        destinations: _testDestinations(),
        onDestinationSelected: (int index) {
          mutatedIndex = index;
        },
        labelType: NavigationRailLabelType.all,
      ),
    );

    await tester.tap(find.text('Def'));
    expect(mutatedIndex, 1);

    await tester.tap(find.text('Ghi'));
    expect(mutatedIndex, 2);
  });

  testWidgets('Destinations can be changed', (WidgetTester tester) async {
  });

  testWidgets('Semantics - labelType=[none]', (WidgetTester tester) async {
  });

  testWidgets('Semantics - labelType=[selected]', (WidgetTester tester) async {
  });

  testWidgets('Semantics - labelType=[all]', (WidgetTester tester) async {
  });

  testWidgets('Semantics - extended', (WidgetTester tester) async {
  });
}

List<NavigationRailDestination> _testDestinations() {
  return const <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.favorite_border),
      activeIcon: Icon(Icons.favorite),
      label: Text('Abc'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bookmark_border),
      activeIcon: Icon(Icons.bookmark),
      label: Text('Def'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.star_border),
      activeIcon: Icon(Icons.star),
      label: Text('Ghi'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.hotel),
      activeIcon: Icon(Icons.home),
      label: Text('Jkl'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.remove_circle),
      activeIcon: Icon(Icons.add_circle),
      label: Text('Mno'),
    ),
  ];
}

Future<void> _pumpNavigationRail(
  WidgetTester tester, {
  double textScaleFactor,
  NavigationRail navigationRail,
}) async {
  textScaleFactor ??= 1.0;
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

RenderBox _iconRenderBox(WidgetTester tester, IconData iconData) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byIcon(iconData),
      matching: find.byType(RichText),
    ).first,
  );
}

RenderBox _labelRenderBox(WidgetTester tester, String text) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.text(text),
      matching: find.byType(RichText),
    ).first,
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

// Only valid when labelType = selected.
double _labelOpacity(WidgetTester tester, String text) {
  final Opacity opacityWidget = tester.firstWidget<Opacity>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Opacity),
    ),
  );
  return opacityWidget.opacity;
}

Material _railMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byType(Material),
    ),
  );
}