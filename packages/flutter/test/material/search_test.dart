// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Can open and close search', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();
    final List<String> selectedResults = <String>[];

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      results: selectedResults,
    ));

    // We are on the homepage
    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('HomeTitle'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);

    // Open search
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('HomeTitle'), findsNothing);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(selectedResults, hasLength(0));

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.focusNode.hasFocus, isTrue);

    // Close search
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('HomeTitle'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);
    expect(selectedResults, <String>['Result']);
  });

  testWidgets('Can close search with system back button to return null', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/18145

    final _TestSearchDelegate delegate = _TestSearchDelegate();
    final List<String> selectedResults = <String>[];

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      results: selectedResults,
    ));

    // We are on the homepage
    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('HomeTitle'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);

    // Open search
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('HomeTitle'), findsNothing);
    expect(find.text('Suggestions'), findsOneWidget);

    // Simulate system back button
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await BinaryMessages.handlePlatformMessage('flutter/navigation', message, (_) {});
    await tester.pumpAndSettle();

    expect(selectedResults, <void>[null]);

    // We are on the homepage again
    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('HomeTitle'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);

    // Open search again
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('HomeTitle'), findsNothing);
    expect(find.text('Suggestions'), findsOneWidget);
  });

  testWidgets('Requests suggestions', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(delegate.query, '');
    expect(delegate.querysForSuggestions.last, '');
    expect(delegate.querysForResults, hasLength(0));

    // Type W o w into search field
    delegate.querysForSuggestions.clear();
    await tester.enterText(find.byType(TextField), 'W');
    await tester.pumpAndSettle();
    expect(delegate.query, 'W');
    await tester.enterText(find.byType(TextField), 'Wo');
    await tester.pumpAndSettle();
    expect(delegate.query, 'Wo');
    await tester.enterText(find.byType(TextField), 'Wow');
    await tester.pumpAndSettle();
    expect(delegate.query, 'Wow');

    expect(delegate.querysForSuggestions, <String>['W', 'Wo', 'Wow']);
    expect(delegate.querysForResults, hasLength(0));
  });

  testWidgets('Shows Results and closes search', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();
    final List<String> selectedResults = <String>[];

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      results: selectedResults,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Wow');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suggestions'));
    await tester.pumpAndSettle();

    // We are on the results page for Wow
    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('HomeTitle'), findsNothing);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Results'), findsOneWidget);

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.focusNode.hasFocus, isFalse);
    expect(delegate.querysForResults, <String>['Wow']);

    // Close search
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('HomeTitle'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Results'), findsNothing);
    expect(selectedResults, <String>['Result']);
  });

  testWidgets('Can switch between results and suggestions',
      (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    // Showing suggestions
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Results'), findsNothing);

    // Typing query Wow
    delegate.querysForSuggestions.clear();
    await tester.enterText(find.byType(TextField), 'Wow');
    await tester.pumpAndSettle();

    expect(delegate.query, 'Wow');
    expect(delegate.querysForSuggestions, <String>['Wow']);
    expect(delegate.querysForResults, hasLength(0));

    await tester.tap(find.text('Suggestions'));
    await tester.pumpAndSettle();

    // Showing Results
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Results'), findsOneWidget);

    expect(delegate.query, 'Wow');
    expect(delegate.querysForSuggestions, <String>['Wow']);
    expect(delegate.querysForResults, <String>['Wow']);

    TextField textField = tester.widget(find.byType(TextField));
    expect(textField.focusNode.hasFocus, isFalse);

    // Taping search field to go back to suggestions
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    textField = tester.widget(find.byType(TextField));
    expect(textField.focusNode.hasFocus, isTrue);

    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Results'), findsNothing);
    expect(delegate.querysForSuggestions, <String>['Wow', 'Wow']);
    expect(delegate.querysForResults, <String>['Wow']);

    await tester.enterText(find.byType(TextField), 'Foo');
    await tester.pumpAndSettle();

    expect(delegate.query, 'Foo');
    expect(delegate.querysForSuggestions, <String>['Wow', 'Wow', 'Foo']);
    expect(delegate.querysForResults, <String>['Wow']);

    // Go to results again
    await tester.tap(find.text('Suggestions'));
    await tester.pumpAndSettle();

    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Results'), findsOneWidget);

    expect(delegate.query, 'Foo');
    expect(delegate.querysForSuggestions, <String>['Wow', 'Wow', 'Foo']);
    expect(delegate.querysForResults, <String>['Wow', 'Foo']);

    textField = tester.widget(find.byType(TextField));
    expect(textField.focusNode.hasFocus, isFalse);
  });

  testWidgets('Fresh search allways starts with empty query',
      (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(delegate.query, '');

    delegate.query = 'Foo';
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(delegate.query, '');
  });

  testWidgets('Initial queries are honored', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    expect(delegate.query, '');

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      passInInitialQuery: true,
      initialQuery: 'Foo',
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(delegate.query, 'Foo');
  });

  testWidgets('Initial query null re-used previous query', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    delegate.query = 'Foo';

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      passInInitialQuery: true,
      initialQuery: null,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(delegate.query, 'Foo');
  });

  testWidgets('Changing query shows up in search field', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      passInInitialQuery: true,
      initialQuery: null,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    delegate.query = 'Foo';

    expect(find.text('Foo'), findsOneWidget);
    expect(find.text('Bar'), findsNothing);

    delegate.query = 'Bar';

    expect(find.text('Foo'), findsNothing);
    expect(find.text('Bar'), findsOneWidget);
  });

  testWidgets('transitionAnimation runs while search fades in/out', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      passInInitialQuery: true,
      initialQuery: null,
    ));

    // runs while search fades in
    expect(delegate.transitionAnimation.status, AnimationStatus.dismissed);
    await tester.tap(find.byTooltip('Search'));
    expect(delegate.transitionAnimation.status, AnimationStatus.forward);
    await tester.pumpAndSettle();
    expect(delegate.transitionAnimation.status, AnimationStatus.completed);

    // does not run while switching to results
    await tester.tap(find.text('Suggestions'));
    expect(delegate.transitionAnimation.status, AnimationStatus.completed);
    await tester.pumpAndSettle();
    expect(delegate.transitionAnimation.status, AnimationStatus.completed);

    // runs while search fades out
    await tester.tap(find.byTooltip('Back'));
    expect(delegate.transitionAnimation.status, AnimationStatus.reverse);
    await tester.pumpAndSettle();
    expect(delegate.transitionAnimation.status, AnimationStatus.dismissed);
  });

  testWidgets('Closing nested search returns to search', (WidgetTester tester) async {
    final List<String> nestedSearchResults = <String>[];
    final _TestSearchDelegate nestedSearchDelegate = _TestSearchDelegate(
      suggestions: 'Nested Suggestions',
      result: 'Nested Result',
    );

    final List<String> selectedResults = <String>[];
    final _TestSearchDelegate delegate = _TestSearchDelegate(
      actions: <Widget>[
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              tooltip: 'Nested Search',
              icon: const Icon(Icons.search),
              onPressed: () async {
                final String result = await showSearch(
                  context: context,
                  delegate: nestedSearchDelegate,
                );
                nestedSearchResults.add(result);
              },
            );
          },
        )
      ],
    );

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      results: selectedResults,
    ));
    expect(find.text('HomeBody'), findsOneWidget);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Nested Suggestions'), findsNothing);

    await tester.tap(find.byTooltip('Nested Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Nested Suggestions'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(nestedSearchResults, <String>['Nested Result']);

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Nested Suggestions'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Nested Suggestions'), findsNothing);
    expect(selectedResults, <String>['Result']);
  });

  testWidgets('Closing search with nested search shown goes back to underlying route', (WidgetTester tester) async {
    _TestSearchDelegate delegate;
    final List<String> nestedSearchResults = <String>[];
    final _TestSearchDelegate nestedSearchDelegate = _TestSearchDelegate(
      suggestions: 'Nested Suggestions',
      result: 'Nested Result',
      actions: <Widget>[
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              tooltip: 'Close Search',
              icon: const Icon(Icons.close),
              onPressed: () async {
                delegate.close(context, 'Result Foo');
              },
            );
          },
        )
      ],
    );

    final List<String> selectedResults = <String>[];
    delegate = _TestSearchDelegate(
      actions: <Widget>[
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              tooltip: 'Nested Search',
              icon: const Icon(Icons.search),
              onPressed: () async {
                final String result = await showSearch(
                  context: context,
                  delegate: nestedSearchDelegate,
                );
                nestedSearchResults.add(result);
              },
            );
          },
        )
      ],
    );

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
      results: selectedResults,
    ));

    expect(find.text('HomeBody'), findsOneWidget);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Nested Suggestions'), findsNothing);

    await tester.tap(find.byTooltip('Nested Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Nested Suggestions'), findsOneWidget);

    await tester.tap(find.byTooltip('Close Search'));
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('Nested Suggestions'), findsNothing);
    expect(nestedSearchResults, <String>[null]);
    expect(selectedResults, <String>['Result Foo']);
  });

  testWidgets('keyboard show search button', (WidgetTester tester) async {
    final _TestSearchDelegate delegate = _TestSearchDelegate();

    await tester.pumpWidget(TestHomePage(
      delegate: delegate,
    ));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField));

    expect(tester.testTextInput.setClientArgs['inputAction'], TextInputAction.search.toString());
  });

  group('contributes semantics', () {
    TestSemantics buildExpected({String routeName}) {
      return TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              TestSemantics(
                id: 7,
                flags: <SemanticsFlag>[
                  SemanticsFlag.scopesRoute,
                  SemanticsFlag.namesRoute,
                ],
                label: routeName,
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    id: 9,
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 10,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.isButton,
                          SemanticsFlag.hasEnabledState,
                          SemanticsFlag.isEnabled,
                        ],
                        actions: <SemanticsAction>[SemanticsAction.tap],
                        label: 'Back',
                        textDirection: TextDirection.ltr,
                      ),
                      TestSemantics(
                        id: 11,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.isTextField,
                          SemanticsFlag.isFocused,
                          SemanticsFlag.isHeader,
                          SemanticsFlag.namesRoute,
                        ],
                        actions: <SemanticsAction>[
                          SemanticsAction.tap,
                          SemanticsAction.setSelection,
                          SemanticsAction.paste,
                        ],
                        label: 'Search',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  TestSemantics(
                    id: 8,
                    flags: <SemanticsFlag>[
                      SemanticsFlag.isButton,
                      SemanticsFlag.hasEnabledState,
                      SemanticsFlag.isEnabled,
                    ],
                    actions: <SemanticsAction>[SemanticsAction.tap],
                    label: 'Suggestions',
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('includes routeName on Android', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final _TestSearchDelegate delegate = _TestSearchDelegate();
      await tester.pumpWidget(TestHomePage(
        delegate: delegate,
      ));

      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();

      expect(semantics, hasSemantics(buildExpected(routeName: 'Search'),
          ignoreId: true, ignoreRect: true, ignoreTransform: true));

      semantics.dispose();
    });

    testWidgets('does not include routeName on iOS', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final SemanticsTester semantics = SemanticsTester(tester);
      final _TestSearchDelegate delegate = _TestSearchDelegate();
      await tester.pumpWidget(TestHomePage(
        delegate: delegate,
      ));

      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();

      expect(semantics, hasSemantics(buildExpected(routeName: ''),
          ignoreId: true, ignoreRect: true, ignoreTransform: true));

      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    });
  });
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({
    this.results,
    this.delegate,
    this.passInInitialQuery = false,
    this.initialQuery,
  });

  final List<String> results;
  final SearchDelegate<String> delegate;
  final bool passInInitialQuery;
  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('HomeTitle'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () async {
                  String selectedResult;
                  if (passInInitialQuery) {
                    selectedResult = await showSearch<String>(
                      context: context,
                      delegate: delegate,
                      query: initialQuery,
                    );
                  } else {
                    selectedResult = await showSearch<String>(
                      context: context,
                      delegate: delegate,
                    );
                  }
                  results?.add(selectedResult);
                },
              ),
            ],
          ),
          body: const Text('HomeBody'),
        );
      }),
    );
  }
}

class _TestSearchDelegate extends SearchDelegate<String> {

  _TestSearchDelegate({
    this.suggestions = 'Suggestions',
    this.result = 'Result',
    this.actions = const <Widget>[],
  });

  final String suggestions;
  final String result;
  final List<Widget> actions;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, result);
      },
    );
  }

  final List<String> querysForSuggestions = <String>[];
  final List<String> querysForResults = <String>[];

  @override
  Widget buildSuggestions(BuildContext context) {
    querysForSuggestions.add(query);
    return MaterialButton(
      onPressed: () {
        showResults(context);
      },
      child: Text(suggestions),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    querysForResults.add(query);
    return const Text('Results');
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return actions;
  }
}
