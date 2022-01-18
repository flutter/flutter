// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionContainer', () {
    testWidgets('works', (WidgetTester tester) async {
      final TestSelectionRegistrar registrar = TestSelectionRegistrar();
      final TestContainerDelegate delegate = TestContainerDelegate();
      await tester.pumpWidget(
        SelectionContainer(
          registrar: registrar,
          delegate: delegate,
          child: Column(
            children: const <Widget>[
              Text('column1', textDirection: TextDirection.ltr),
              Text('column2', textDirection: TextDirection.ltr),
              Text('column3', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      expect(registrar.selectables.length, 1);
      expect(delegate.selectables.length, 3);
    });

    testWidgets('disabled container', (WidgetTester tester) async {
      final TestSelectionRegistrar registrar = TestSelectionRegistrar();
      final TestContainerDelegate delegate = TestContainerDelegate();
      await tester.pumpWidget(
        SelectionContainer(
          registrar: registrar,
          delegate: delegate,
          child: SelectionRegistrarScope.disabled(
            child: Column(
              children: const <Widget>[
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

    testWidgets('selection container register itself if there is a selectable child', (WidgetTester tester) async {
      final TestSelectionRegistrar registrar = TestSelectionRegistrar();
      final TestContainerDelegate delegate = TestContainerDelegate();
      await tester.pumpWidget(
        SelectionContainer(
          registrar: registrar,
          delegate: delegate,
          child: Column(
          ),
        ),
      );
      expect(registrar.selectables.length, 0);

      await tester.pumpWidget(
        SelectionContainer(
          registrar: registrar,
          delegate: delegate,
          child: Column(
            children: const <Widget>[
              Text('column1', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      expect(registrar.selectables.length, 1);

      await tester.pumpWidget(
        SelectionContainer(
          registrar: registrar,
          delegate: delegate,
          child: Column(
          ),
        ),
      );
      expect(registrar.selectables.length, 0);
    });
  });
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
