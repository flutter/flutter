// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default search field has a border radius', (WidgetTester tester) async {
    await tester.pumpWidget(const CupertinoApp(home: Center(child: CupertinoSearchTextField())));

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(CupertinoSearchTextField),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(9)));
  });

  testWidgets('decoration overrides default background color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            decoration: BoxDecoration(color: Color.fromARGB(1, 1, 1, 1)),
          ),
        ),
      ),
    );

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(CupertinoSearchTextField),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(decoration.color, const Color.fromARGB(1, 1, 1, 1));
  });

  testWidgets('decoration overrides default border radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            decoration: BoxDecoration(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
    );

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(CupertinoSearchTextField),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.zero);
  });

  testWidgets('text entries are padded by default', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'initial');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(controller: controller)),
      ),
    );

    expect(
      tester.getTopLeft(find.text('initial')) -
          tester.getTopLeft(find.byType(CupertinoSearchTextField)),
      const Offset(31.5, 9.5),
    );
  });

  testWidgets('can change keyboard type', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(keyboardType: TextInputType.number)),
      ),
    );
    await tester.tap(find.byType(CupertinoSearchTextField));
    await tester.showKeyboard(find.byType(CupertinoSearchTextField));
    expect(
      (tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'],
      equals('TextInputType.number'),
    );
  });

  testWidgets('can control text content via controller', (WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(controller: controller)),
      ),
    );

    controller.text = 'controller text';
    await tester.pump();

    expect(find.text('controller text'), findsOneWidget);

    controller.text = '';
    await tester.pump();

    expect(find.text('controller text'), findsNothing);
  });

  testWidgets('placeholder color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.dark),
        home: Center(child: CupertinoSearchTextField()),
      ),
    );

    Text placeholder = tester.widget(find.text('Search'));
    expect(placeholder.style!.color!.value, CupertinoColors.secondaryLabel.darkColor.value);

    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.light),
        home: Center(child: CupertinoSearchTextField()),
      ),
    );

    placeholder = tester.widget(find.text('Search'));
    expect(placeholder.style!.color!.value, CupertinoColors.secondaryLabel.color.value);
  });

  testWidgets("placeholderStyle modifies placeholder's style and doesn't affect text's style", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            placeholder: 'placeholder',
            style: TextStyle(color: Color(0x00FFFFFF), fontWeight: FontWeight.w300),
            placeholderStyle: TextStyle(color: Color(0xAAFFFFFF), fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );

    final Text placeholder = tester.widget(find.text('placeholder'));
    expect(placeholder.style!.color, const Color(0xAAFFFFFF));
    expect(placeholder.style!.fontWeight, FontWeight.w600);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'input');
    await tester.pump();

    final EditableText inputText = tester.widget(find.text('input'));
    expect(inputText.style.color, const Color(0x00FFFFFF));
    expect(inputText.style.fontWeight, FontWeight.w300);
  });

  testWidgets('prefix widget is in front of the text', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'input');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(controller: controller)),
      ),
    );

    expect(
      tester.getTopRight(find.byIcon(CupertinoIcons.search)).dx + 5.5,
      tester.getTopLeft(find.byType(EditableText)).dx,
    );

    expect(
      tester.getTopLeft(find.byType(EditableText)).dx,
      tester.getTopLeft(find.byType(CupertinoSearchTextField)).dx +
          tester.getSize(find.byIcon(CupertinoIcons.search)).width +
          11.5,
    );
  });

  testWidgets('suffix widget is after the text', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'Hi');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(controller: controller)),
      ),
    );

    expect(
      tester.getTopRight(find.byType(EditableText)).dx + 5.5,
      tester.getTopLeft(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx,
    );

    expect(
      tester.getTopRight(find.byType(EditableText)).dx,
      tester.getTopRight(find.byType(CupertinoSearchTextField)).dx -
          tester.getSize(find.byIcon(CupertinoIcons.xmark_circle_fill)).width -
          10.5,
    );
  });

  testWidgets('prefix widget visibility', (WidgetTester tester) async {
    const prefixIcon = Key('prefix');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            prefixIcon: SizedBox(key: prefixIcon, width: 50, height: 50),
          ),
        ),
      ),
    );

    expect(find.byIcon(CupertinoIcons.search), findsNothing);
    expect(find.byKey(prefixIcon), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'text input');
    await tester.pump();

    expect(find.text('text input'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.search), findsNothing);
    expect(find.byKey(prefixIcon), findsOneWidget);
  });

  testWidgets('suffix widget respects visibility mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(suffixMode: OverlayVisibilityMode.notEditing)),
      ),
    );

    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'text input');
    await tester.pump();

    expect(find.text('text input'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
  });

  testWidgets('Default prefix and suffix insets are aligned', (WidgetTester tester) async {
    await tester.pumpWidget(const CupertinoApp(home: Center(child: CupertinoSearchTextField())));

    expect(find.byIcon(CupertinoIcons.search), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'text input');
    await tester.pump();

    expect(find.text('text input'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.search), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

    expect(tester.getTopLeft(find.byIcon(CupertinoIcons.search)), const Offset(6.0, 290.0));
    expect(
      tester.getTopLeft(find.byIcon(CupertinoIcons.xmark_circle_fill)),
      const Offset(775.0, 290.0),
    );

    expect(tester.getBottomRight(find.byIcon(CupertinoIcons.search)), const Offset(26.0, 310.0));
    expect(
      tester.getBottomRight(find.byIcon(CupertinoIcons.xmark_circle_fill)),
      const Offset(795.0, 310.0),
    );
  });

  testWidgets('clear button shows with right visibility mode', (WidgetTester tester) async {
    var controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            controller: controller,
            placeholder: 'placeholder does not affect clear button',
          ),
        ),
      ),
    );

    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'text input');
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
    expect(find.text('text input'), findsOneWidget);

    controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            controller: controller,
            placeholder: 'placeholder does not affect clear button',
            suffixMode: OverlayVisibilityMode.notEditing,
          ),
        ),
      ),
    );
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

    controller.text = 'input';
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
  });

  testWidgets('clear button removes text', (WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(controller: controller)),
      ),
    );

    controller.text = 'text entry';
    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pump();

    expect(controller.text, '');
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('text entry'), findsNothing);
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
  });

  testWidgets('tapping clear button also calls onChanged when text not empty', (
    WidgetTester tester,
  ) async {
    var value = 'text entry';
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            controller: controller,
            placeholder: 'placeholder',
            onChanged: (String newValue) => value = newValue,
          ),
        ),
      ),
    );

    controller.text = value;
    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(find.text('text entry'), findsNothing);
    expect(value, isEmpty);
  });

  testWidgets('RTL puts attachments to the right places', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: CupertinoSearchTextField(suffixMode: OverlayVisibilityMode.always)),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byIcon(CupertinoIcons.search)).dx, 800.0 - 26.0);

    expect(tester.getTopRight(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx, 25.0);
  });

  testWidgets('Can modify prefix and suffix insets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            suffixMode: OverlayVisibilityMode.always,
            prefixInsets: EdgeInsets.zero,
            suffixInsets: EdgeInsets.zero,
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byIcon(CupertinoIcons.search)).dx, 0.0);

    expect(tester.getTopRight(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx, 800.0);
  });

  testWidgets('custom suffix onTap overrides default clearing behavior', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: 'Text');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(controller: controller, onSuffixTap: () {}),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pump();

    expect(controller.text, isNotEmpty);
    expect(find.text('Text'), findsOneWidget);
  });

  testWidgets('onTap is properly forwarded to the inner text field', (WidgetTester tester) async {
    var onTapCallCount = 0;

    // onTap can be null.
    await tester.pumpWidget(const CupertinoApp(home: Center(child: CupertinoSearchTextField())));

    // onTap callback is called if not null.
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            onTap: () {
              onTapCallCount++;
            },
          ),
        ),
      ),
    );

    expect(onTapCallCount, 0);
    await tester.tap(find.byType(CupertinoTextField));
    expect(onTapCallCount, 1);
  });

  testWidgets('autocorrect is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(home: Center(child: CupertinoSearchTextField(autocorrect: false))),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.autocorrect, false);
  });

  testWidgets('enabled is properly forwarded to the inner text field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(home: Center(child: CupertinoSearchTextField(enabled: false))),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.enabled, false);
  });

  testWidgets('textInputAction is set to TextInputAction.search by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CupertinoApp(home: Center(child: CupertinoSearchTextField())));

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.textInputAction, TextInputAction.search);
  });

  testWidgets('autofocus:true gives focus to the widget', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(focusNode: focusNode, autofocus: true)),
      ),
    );

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('smartQuotesType is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(smartQuotesType: SmartQuotesType.disabled)),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.smartQuotesType, SmartQuotesType.disabled);
  });

  testWidgets('smartDashesType is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(smartDashesType: SmartDashesType.disabled)),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.smartDashesType, SmartDashesType.disabled);
  });

  testWidgets('enableIMEPersonalizedLearning is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(enableIMEPersonalizedLearning: false)),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.enableIMEPersonalizedLearning, false);
  });

  testWidgets('cursorWidth is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(home: Center(child: CupertinoSearchTextField(cursorWidth: 1))),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.cursorWidth, 1);
  });

  testWidgets('cursorHeight is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(home: Center(child: CupertinoSearchTextField(cursorHeight: 10))),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.cursorHeight, 10);
  });

  testWidgets('cursorRadius is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(cursorRadius: Radius.circular(1.0))),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.cursorRadius, const Radius.circular(1.0));
  });

  testWidgets('cursorOpacityAnimates is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(cursorOpacityAnimates: false)),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.cursorOpacityAnimates, false);
  });

  testWidgets('cursorColor is properly forwarded to the inner text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: CupertinoSearchTextField(cursorColor: Color.fromARGB(255, 255, 0, 0))),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.cursorColor, const Color.fromARGB(255, 255, 0, 0));
  });

  testWidgets('Icons and placeholder fade while resizing on scroll', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverResizingHeader(
                child: CupertinoSearchTextField(suffixMode: OverlayVisibilityMode.always),
              ),
              SliverFillRemaining(),
            ],
          ),
        ),
      ),
    );

    final Finder searchTextFieldFinder = find.byType(CupertinoSearchTextField);
    expect(searchTextFieldFinder, findsOneWidget);

    final Finder prefixIconFinder = find.descendant(
      of: searchTextFieldFinder,
      matching: find.byIcon(CupertinoIcons.search),
    );
    final Finder suffixIconFinder = find.descendant(
      of: searchTextFieldFinder,
      matching: find.byIcon(CupertinoIcons.xmark_circle_fill),
    );
    final Finder placeholderFinder = find.descendant(
      of: searchTextFieldFinder,
      matching: find.text('Search'),
    );
    expect(prefixIconFinder, findsOneWidget);
    expect(suffixIconFinder, findsOneWidget);
    expect(placeholderFinder, findsOneWidget);

    // Initially, the icons are fully opaque.
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: prefixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      equals(1.0),
    );
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: suffixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      equals(1.0),
    );
    // The default placeholder color is semi-transparent.
    expect(tester.widget<Text>(placeholderFinder).style?.color?.a, equals(0.6));

    final double searchTextFieldHeight = tester.getSize(searchTextFieldFinder).height;

    final TestGesture scrollGesture1 = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await scrollGesture1.moveBy(Offset(0, -searchTextFieldHeight / 5));
    await scrollGesture1.up();
    await tester.pumpAndSettle();

    // The icons and placeholder text start to fade.
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: prefixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      greaterThan(0.0),
    );
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: prefixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      lessThan(1.0),
    );
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: suffixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      greaterThan(0.0),
    );
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: suffixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      lessThan(1.0),
    );
    expect(tester.widget<Text>(placeholderFinder).style?.color?.a, greaterThan(0.0));
    expect(tester.widget<Text>(placeholderFinder).style?.color?.a, lessThan(1.0));

    final TestGesture scrollGesture2 = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await scrollGesture2.moveBy(Offset(0, -4 * searchTextFieldHeight / 5));
    await scrollGesture2.up();
    await tester.pumpAndSettle();

    // The icons and placeholder text have faded completely.
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: prefixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      equals(0.0),
    );
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: suffixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      equals(0.0),
    );
    expect(tester.widget<Text>(placeholderFinder).style?.color?.a, equals(0.0));
  });

  testWidgets('Top padding animates while resizing on scroll', (WidgetTester tester) async {
    const TextDirection direction = TextDirection.ltr;
    await tester.pumpWidget(
      const Directionality(
        textDirection: direction,
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverResizingHeader(child: CupertinoSearchTextField()),
                SliverFillRemaining(),
              ],
            ),
          ),
        ),
      ),
    );

    final Finder searchTextFieldFinder = find.byType(CupertinoSearchTextField);
    expect(searchTextFieldFinder, findsOneWidget);

    final double initialPadding = tester
        .widget<CupertinoTextField>(
          find.descendant(of: searchTextFieldFinder, matching: find.byType(CupertinoTextField)),
        )
        .padding
        .resolve(direction)
        .top;
    expect(initialPadding, equals(8.0));

    final double searchTextFieldHeight = tester.getSize(searchTextFieldFinder).height;

    final TestGesture scrollGesture = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await scrollGesture.moveBy(Offset(0, -searchTextFieldHeight / 5));
    await scrollGesture.up();
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<CupertinoTextField>(
            find.descendant(of: searchTextFieldFinder, matching: find.byType(CupertinoTextField)),
          )
          .padding
          .resolve(direction)
          .top,
      lessThan(initialPadding),
    );
  });

  testWidgets('Fades and animates insets on scroll if search field starts out collapsed', (
    WidgetTester tester,
  ) async {
    const TextDirection direction = TextDirection.ltr;
    const double scrollOffset = 200;
    await tester.pumpWidget(
      const Directionality(
        textDirection: direction,
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar.search(
                  largeTitle: Text('Large title'),
                  searchField: CupertinoSearchTextField(),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 1000)),
              ],
            ),
          ),
        ),
      ),
    );

    final Finder searchTextFieldFinder = find.byType(CupertinoSearchTextField);
    expect(searchTextFieldFinder, findsOneWidget);

    final double searchTextFieldHeight = tester.getSize(searchTextFieldFinder).height;
    await tester.tap(find.widgetWithText(CupertinoSearchTextField, 'Search'), warnIfMissed: false);

    final TestGesture scrollGesture1 = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await scrollGesture1.moveBy(const Offset(0, -scrollOffset));
    await scrollGesture1.up();
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final TestGesture scrollGesture2 = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await scrollGesture2.moveBy(Offset(0, scrollOffset - searchTextFieldHeight / 2));
    await scrollGesture2.up();
    await tester.pump();

    final Finder prefixIconFinder = find.descendant(
      of: searchTextFieldFinder,
      matching: find.byIcon(CupertinoIcons.search),
    );

    // The prefix icon has faded.
    expect(prefixIconFinder, findsOneWidget);
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: prefixIconFinder, matching: find.byType(Opacity)))
          .opacity,
      lessThan(1.0),
    );
  });

  testWidgets('Focused search field hides prefix in higher accessibility text scale modes', (
    WidgetTester tester,
  ) async {
    var scaleFactor = 3.0;
    const iconSize = 10.0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    late StateSetter setState;

    await tester.pumpWidget(
      CupertinoApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return MediaQuery.withClampedTextScaling(
              minScaleFactor: scaleFactor,
              maxScaleFactor: scaleFactor,
              child: CupertinoPageScaffold(
                child: Center(
                  child: CupertinoSearchTextField(
                    placeholder: 'Search',
                    focusNode: focusNode,
                    prefixIcon: const Icon(CupertinoIcons.add),
                    suffixIcon: const Icon(CupertinoIcons.xmark),
                    suffixMode: OverlayVisibilityMode.always,
                    itemSize: iconSize,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final Iterable<RichText> barItems = tester.widgetList<RichText>(
      find.descendant(of: find.byType(CupertinoSearchTextField), matching: find.byType(RichText)),
    );
    expect(barItems.length, greaterThan(0));

    for (final icon in <IconData>[CupertinoIcons.add, CupertinoIcons.xmark]) {
      expect(tester.getSize(find.byIcon(icon)), Size.square(scaleFactor * iconSize));
    }

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    // The prefix icon shrinks at higher accessibility text scale modes.
    expect(tester.getSize(find.byIcon(CupertinoIcons.add)), Size.zero);
    expect(tester.getSize(find.byIcon(CupertinoIcons.xmark)), Size.square(scaleFactor * iconSize));

    setState(() {
      scaleFactor = 2.9;
    });
    await tester.pumpAndSettle();

    // Below the threshold, the prefix icon is displayed.
    for (final icon in <IconData>[CupertinoIcons.add, CupertinoIcons.xmark]) {
      expect(tester.getSize(find.byIcon(icon)), Size.square(scaleFactor * iconSize));
    }
  });

  testWidgets('CupertinoSearchTextField does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    final controller = TextEditingController(text: 'X');
    addTearDown(tester.view.reset);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoSearchTextField(controller: controller)),
      ),
    );
    expect(tester.getSize(find.byType(CupertinoSearchTextField)), Size.zero);
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
  });
}
