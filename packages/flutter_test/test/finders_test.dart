// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('image', () {
    testWidgets('finds Image widgets', (final WidgetTester tester) async {
      await tester
          .pumpWidget(_boilerplate(Image(image: FileImage(File('test')))));
      expect(find.image(FileImage(File('test'))), findsOneWidget);
    });

    testWidgets('finds Button widgets with Image', (final WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(ElevatedButton(
        onPressed: null,
        child: Image(image: FileImage(File('test'))),
      )));
      expect(find.widgetWithImage(ElevatedButton, FileImage(File('test'))),
          findsOneWidget);
    });
  });

  group('text', () {
    testWidgets('finds Text widgets', (final WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(
        const Text('test'),
      ));
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('finds Text.rich widgets', (final WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(const Text.rich(
        TextSpan(
          text: 't',
          children: <TextSpan>[
            TextSpan(text: 'e'),
            TextSpan(text: 'st'),
          ],
        ),
      )));

      expect(find.text('test'), findsOneWidget);
    });

    group('findRichText', () {
      testWidgets('finds RichText widgets when enabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(RichText(
          text: const TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
            ],
          ),
        )));

        expect(find.text('test', findRichText: true), findsOneWidget);
      });

      testWidgets('finds Text widgets once when enabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(const Text('test2')));

        expect(find.text('test2', findRichText: true), findsOneWidget);
      });

      testWidgets('does not find RichText widgets when disabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(RichText(
          text: const TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
            ],
          ),
        )));

        expect(find.text('test'), findsNothing);
      });

      testWidgets(
          'does not find Text and RichText separated by semantics widgets twice',
          (final WidgetTester tester) async {
        // If rich: true found both Text and RichText, this would find two widgets.
        await tester.pumpWidget(_boilerplate(
          const Text('test', semanticsLabel: 'foo'),
        ));

        expect(find.text('test'), findsOneWidget);
      });

      testWidgets('finds Text.rich widgets when enabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(const Text.rich(
          TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
              TextSpan(text: '3'),
            ],
          ),
        )));

        expect(find.text('test3', findRichText: true), findsOneWidget);
      });

      testWidgets('finds Text.rich widgets when disabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(const Text.rich(
          TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
              TextSpan(text: '3'),
            ],
          ),
        )));

        expect(find.text('test3'), findsOneWidget);
      });
    });
  });

  group('textContaining', () {
    testWidgets('finds Text widgets', (final WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(
        const Text('this is a test'),
      ));
      expect(find.textContaining(RegExp(r'test')), findsOneWidget);
      expect(find.textContaining('test'), findsOneWidget);
      expect(find.textContaining('a'), findsOneWidget);
      expect(find.textContaining('s'), findsOneWidget);
    });

    testWidgets('finds Text.rich widgets', (final WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(const Text.rich(
        TextSpan(
          text: 'this',
          children: <TextSpan>[
            TextSpan(text: 'is'),
            TextSpan(text: 'a'),
            TextSpan(text: 'test'),
          ],
        ),
      )));

      expect(find.textContaining(RegExp(r'isatest')), findsOneWidget);
      expect(find.textContaining('isatest'), findsOneWidget);
    });

    testWidgets('finds EditableText widgets', (final WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _boilerplate(TextField(
            controller: TextEditingController()..text = 'this is test',
          )),
        ),
      ));

      expect(find.textContaining(RegExp(r'test')), findsOneWidget);
      expect(find.textContaining('test'), findsOneWidget);
    });

    group('findRichText', () {
      testWidgets('finds RichText widgets when enabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(RichText(
          text: const TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
            ],
          ),
        )));

        expect(find.textContaining('te', findRichText: true), findsOneWidget);
      });

      testWidgets('finds Text widgets once when enabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(const Text('test2')));

        expect(find.textContaining('tes', findRichText: true), findsOneWidget);
      });

      testWidgets('does not find RichText widgets when disabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(RichText(
          text: const TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
            ],
          ),
        )));

        expect(find.textContaining('te'), findsNothing);
      });

      testWidgets(
          'does not find Text and RichText separated by semantics widgets twice',
          (final WidgetTester tester) async {
        // If rich: true found both Text and RichText, this would find two widgets.
        await tester.pumpWidget(_boilerplate(
          const Text('test', semanticsLabel: 'foo'),
        ));

        expect(find.textContaining('tes'), findsOneWidget);
      });

      testWidgets('finds Text.rich widgets when enabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(const Text.rich(
          TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
              TextSpan(text: '3'),
            ],
          ),
        )));

        expect(find.textContaining('t3', findRichText: true), findsOneWidget);
      });

      testWidgets('finds Text.rich widgets when disabled',
          (final WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(const Text.rich(
          TextSpan(
            text: 't',
            children: <TextSpan>[
              TextSpan(text: 'est'),
              TextSpan(text: '3'),
            ],
          ),
        )));

        expect(find.textContaining('t3'), findsOneWidget);
      });
    });
  });

  group('semantics', () {
    testWidgets('Throws StateError if semantics are not enabled',
        (final WidgetTester tester) async {
      expect(() => find.bySemanticsLabel('Add'), throwsStateError);
    }, semanticsEnabled: false);

    testWidgets('finds Semantically labeled widgets',
        (final WidgetTester tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(_boilerplate(
        Semantics(
          label: 'Add',
          button: true,
          child: const TextButton(
            onPressed: null,
            child: Text('+'),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('Add'), findsOneWidget);
      semanticsHandle.dispose();
    });

    testWidgets('finds Semantically labeled widgets by RegExp',
        (final WidgetTester tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(_boilerplate(
        Semantics(
          container: true,
          child: const Row(children: <Widget>[
            Text('Hello'),
            Text('World'),
          ]),
        ),
      ));
      expect(find.bySemanticsLabel('Hello'), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Hello')), findsOneWidget);
      semanticsHandle.dispose();
    });

    testWidgets('finds Semantically labeled widgets without explicit Semantics',
        (final WidgetTester tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      await tester
          .pumpWidget(_boilerplate(const SimpleCustomSemanticsWidget('Foo')));
      expect(find.bySemanticsLabel('Foo'), findsOneWidget);
      semanticsHandle.dispose();
    });
  });

  group('hitTestable', () {
    testWidgets('excludes non-hit-testable widgets',
        (final WidgetTester tester) async {
      await tester.pumpWidget(
        _boilerplate(IndexedStack(
          sizing: StackFit.expand,
          children: <Widget>[
            GestureDetector(
              key: const ValueKey<int>(0),
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const SizedBox.expand(),
            ),
            GestureDetector(
              key: const ValueKey<int>(1),
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const SizedBox.expand(),
            ),
          ],
        )),
      );
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(GestureDetector, skipOffstage: false), findsNWidgets(2));
      final Finder hitTestable = find.byType(GestureDetector, skipOffstage: false).hitTestable();
      expect(hitTestable, findsOneWidget);
      expect(tester.widget(hitTestable).key, const ValueKey<int>(0));
    });
  });

  testWidgets('ChainedFinders chain properly', (final WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    await tester.pumpWidget(
      _boilerplate(Column(
        children: <Widget>[
          Container(
            key: key1,
            child: const Text('1'),
          ),
          const Text('2'),
        ],
      )),
    );

    // Get the text back. By correctly chaining the descendant finder's
    // candidates, it should find 1 instead of 2. If the _LastFinder wasn't
    // correctly chained after the descendant's candidates, the last element
    // with a Text widget would have been 2.
    final Text text = find
        .descendant(
          of: find.byKey(key1),
          matching: find.byType(Text),
        )
        .last
        .evaluate()
        .single
        .widget as Text;

    expect(text.data, '1');
  });

  testWidgets('finds multiple subtypes', (final WidgetTester tester) async {
    await tester.pumpWidget(_boilerplate(
      Row(children: <Widget>[
        const Column(children: <Widget>[
          Text('Hello'),
          Text('World'),
        ]),
        Column(children: <Widget>[
          Image(image: FileImage(File('test'))),
        ]),
        const Column(children: <Widget>[
          SimpleGenericWidget<int>(child: Text('one')),
          SimpleGenericWidget<double>(child: Text('pi')),
          SimpleGenericWidget<String>(child: Text('two')),
        ]),
      ]),
    ));

    expect(find.bySubtype<Row>(), findsOneWidget);
    expect(find.bySubtype<Column>(), findsNWidgets(3));
    // Finds both rows and columns.
    expect(find.bySubtype<Flex>(), findsNWidgets(4));

    // Finds only the requested generic subtypes.
    expect(find.bySubtype<SimpleGenericWidget<int>>(), findsOneWidget);
    expect(find.bySubtype<SimpleGenericWidget<num>>(), findsNWidgets(2));
    expect(find.bySubtype<SimpleGenericWidget<Object>>(), findsNWidgets(3));

    // Finds all widgets.
    final int totalWidgetCount =
        find.byWidgetPredicate((final _) => true).evaluate().length;
    expect(find.bySubtype<Widget>(), findsNWidgets(totalWidgetCount));
  });
}

Widget _boilerplate(final Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}

class SimpleCustomSemanticsWidget extends LeafRenderObjectWidget {
  const SimpleCustomSemanticsWidget(this.label, {super.key});

  final String label;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      SimpleCustomSemanticsRenderObject(label);
}

class SimpleCustomSemanticsRenderObject extends RenderBox {
  SimpleCustomSemanticsRenderObject(this.label);

  final String label;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(final BoxConstraints constraints) {
    return constraints.smallest;
  }

  @override
  void describeSemanticsConfiguration(final SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..label = label
      ..textDirection = TextDirection.ltr;
  }
}

class SimpleGenericWidget<T> extends StatelessWidget {
  const SimpleGenericWidget({required final Widget child, super.key})
      : _child = child;

  final Widget _child;

  @override
  Widget build(final BuildContext context) {
    return _child;
  }
}
