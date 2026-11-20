// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpContainer(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(TestWidgetsApp(home: child));
  }

  testWidgets('updates its registrar and delegate based on the number of selectables', (
    WidgetTester tester,
  ) async {
    final registrar = TestSelectionRegistrar();
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);

    await pumpContainer(
      tester,
      SelectionContainer(
        registrar: registrar,
        delegate: delegate,
        child: const Column(
          children: <Widget>[
            Text('column1', textDirection: TextDirection.ltr),
            Text('column2', textDirection: TextDirection.ltr),
            Text('column3', textDirection: TextDirection.ltr),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(registrar.selectables.length, 1);
    expect(delegate.selectables.length, 3);
  });

  testWidgets('disabled container', (WidgetTester tester) async {
    final registrar = TestSelectionRegistrar();
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);

    await pumpContainer(
      tester,
      SelectionContainer(
        registrar: registrar,
        delegate: delegate,
        child: const SelectionContainer.disabled(
          child: Column(
            children: <Widget>[
              Text('column1', textDirection: TextDirection.ltr),
              Text('column2', textDirection: TextDirection.ltr),
              Text('column3', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      ),
    );
    expect(registrar.selectables.length, 0);
    expect(delegate.selectables.length, 0);
  });

  testWidgets('Swapping out container delegate does not crash', (WidgetTester tester) async {
    final registrar = TestSelectionRegistrar();
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);
    final childDelegate = TestContainerDelegate();
    addTearDown(childDelegate.dispose);

    await pumpContainer(
      tester,
      SelectionContainer(
        registrar: registrar,
        delegate: delegate,
        child: Builder(
          builder: (BuildContext context) {
            return SelectionContainer(
              registrar: SelectionContainer.maybeOf(context),
              delegate: childDelegate,
              child: const Text('dummy'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(registrar.selectables.length, 1);
    expect(delegate.value.hasContent, isTrue);

    final newDelegate = TestContainerDelegate();
    addTearDown(newDelegate.dispose);

    await pumpContainer(
      tester,
      SelectionContainer(
        registrar: registrar,
        delegate: delegate,
        child: Builder(
          builder: (BuildContext context) {
            return SelectionContainer(
              registrar: SelectionContainer.maybeOf(context),
              delegate: newDelegate,
              child: const Text('dummy'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(registrar.selectables.length, 1);
    expect(delegate.value.hasContent, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Can update within one frame', (WidgetTester tester) async {
    final registrar = TestSelectionRegistrar();
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);
    final childDelegate = TestContainerDelegate();
    addTearDown(childDelegate.dispose);

    await pumpContainer(
      tester,
      SelectionContainer(
        registrar: registrar,
        delegate: delegate,
        child: Builder(
          builder: (BuildContext context) {
            return SelectionContainer(
              registrar: SelectionContainer.maybeOf(context),
              delegate: childDelegate,
              child: const Text('dummy'), // The [Text] widget has an internal [SelectionContainer].
            );
          },
        ),
      ),
    );
    await tester.pump();
    // Should finish update after flushing the micro tasks.
    await tester.idle();
    expect(registrar.selectables.length, 1);
    expect(delegate.value.hasContent, isTrue);
  });

  testWidgets('selection container registers itself if there is a selectable child', (
    WidgetTester tester,
  ) async {
    final registrar = TestSelectionRegistrar();
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);

    await pumpContainer(
      tester,
      SelectionContainer(registrar: registrar, delegate: delegate, child: const Column()),
    );
    expect(registrar.selectables.length, 0);

    await pumpContainer(
      tester,
      SelectionContainer(
        registrar: registrar,
        delegate: delegate,
        child: const Column(children: <Widget>[Text('column1', textDirection: TextDirection.ltr)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(registrar.selectables.length, 1);

    await pumpContainer(
      tester,
      SelectionContainer(registrar: registrar, delegate: delegate, child: const Column()),
    );
    await tester.pumpAndSettle();
    expect(registrar.selectables.length, 0);
  });

  testWidgets('selection container gets registrar from context if not provided', (
    WidgetTester tester,
  ) async {
    final registrar = TestSelectionRegistrar();
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);

    await pumpContainer(
      tester,
      SelectionRegistrarScope(
        registrar: registrar,
        child: SelectionContainer(
          delegate: delegate,
          child: const Column(
            children: <Widget>[Text('column1', textDirection: TextDirection.ltr)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(registrar.selectables.length, 1);
  });

  testWidgets('SelectionContainer does not crash at zero area', (WidgetTester tester) async {
    final delegate = TestContainerDelegate();
    addTearDown(delegate.dispose);
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Center(
          child: SizedBox.shrink(
            child: SelectionContainer(delegate: delegate, child: const Placeholder()),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SelectionContainer)), Size.zero);
  });

  testWidgets(
    'clearing the selection does not crash when a nested container unregisters during the clear',
    (WidgetTester tester) async {
      final delegate = StaticSelectionContainerDelegate();
      addTearDown(delegate.dispose);
      final childDelegate = StaticSelectionContainerDelegate();
      addTearDown(childDelegate.dispose);

      Widget buildContainer({required bool showNestedText}) {
        return SelectionContainer(
          delegate: delegate,
          child: Column(
            children: <Widget>[
              const Text('first', textDirection: TextDirection.ltr),
              SelectionContainer(
                delegate: childDelegate,
                child: showNestedText
                    ? const Text('nested', textDirection: TextDirection.ltr)
                    : const SizedBox.shrink(),
              ),
              const Text('last', textDirection: TextDirection.ltr),
            ],
          ),
        );
      }

      await pumpContainer(tester, buildContainer(showNestedText: true));
      await tester.pump();
      await tester.idle();
      // first, the nested container, last.
      expect(delegate.selectables.length, 3);

      // Removing the nested text leaves the nested container empty, but the
      // nested container only finds out that it has no content when its
      // scheduled update runs after this frame. A clear dispatched before that
      // makes the nested container recompute its geometry, see that it has no
      // content and remove itself from the parent while the parent is still
      // iterating its selectables.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        delegate.dispatchSelectionEvent(const ClearSelectionEvent());
      });
      await pumpContainer(tester, buildContainer(showNestedText: false));
      await tester.idle();

      expect(tester.takeException(), isNull);
      // first, last.
      expect(delegate.selectables.length, 2);
    },
  );
}

class TestContainerDelegate extends MultiSelectableSelectionContainerDelegate {
  @override
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event) {
    throw UnimplementedError();
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    throw UnimplementedError();
  }
}

class TestSelectionRegistrar extends SelectionRegistrar {
  final Set<Selectable> selectables = <Selectable>{};

  @override
  void add(Selectable selectable) => selectables.add(selectable);

  @override
  void remove(Selectable selectable) => selectables.remove(selectable);
}
