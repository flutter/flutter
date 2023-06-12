import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TypeMatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:nested/nested.dart';

import 'common.dart';

void main() {
  testWidgets('insert widgets in natural order', (tester) async {
    await tester.pumpWidget(
      Nested(
        children: [
          MySizedBox(height: 0),
          MySizedBox(height: 1),
        ],
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('foo'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 0),
        isA<MySizedBox>().having((s) => s.height, 'height', 1),
      ]),
    );

    await tester.pumpWidget(
      Nested(
        children: [
          MySizedBox(height: 10),
          MySizedBox(height: 11),
        ],
        child: const Text('bar', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('bar'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 10),
        isA<MySizedBox>().having((s) => s.height, 'height', 11),
      ]),
    );
  });
  testWidgets('nested inside nested', (tester) async {
    await tester.pumpWidget(Nested(
      children: [
        MySizedBox(height: 0),
        Nested(
          children: [
            MySizedBox(height: 1),
            MySizedBox(height: 2),
          ],
        ),
        MySizedBox(height: 3),
      ],
      child: const Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 0),
        isA<MySizedBox>().having((s) => s.height, 'height', 1),
        isA<MySizedBox>().having((s) => s.height, 'height', 2),
        isA<MySizedBox>().having((s) => s.height, 'height', 3),
      ]),
    );

    await tester.pumpWidget(Nested(
      children: [
        MySizedBox(height: 10),
        Nested(
          children: [
            MySizedBox(height: 11),
            MySizedBox(height: 12),
          ],
        ),
        MySizedBox(height: 13),
      ],
      child: const Text('bar', textDirection: TextDirection.ltr),
    ));

    expect(find.text('bar'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 10),
        isA<MySizedBox>().having((s) => s.height, 'height', 11),
        isA<MySizedBox>().having((s) => s.height, 'height', 12),
        isA<MySizedBox>().having((s) => s.height, 'height', 13),
      ]),
    );
  });

  test('children is required', () {
    expect(
      () => Nested(
        children: [],
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
      throwsAssertionError,
    );

    Nested(
      children: [MySizedBox()],
      child: const Text('foo', textDirection: TextDirection.ltr),
    );
  });

  testWidgets('no unnecessary rebuild #2', (tester) async {
    var buildCount = 0;
    final child = Nested(
      children: [
        MySizedBox(didBuild: (_, __) => buildCount++),
      ],
      child: Container(),
    );

    await tester.pumpWidget(child);

    expect(buildCount, equals(1));
    await tester.pumpWidget(child);

    expect(buildCount, equals(1));
  });

  testWidgets(
    'a node change rebuilds only that node',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);

      var buildCount2 = 0;
      final second = SingleChildBuilder(
        builder: (_, child) {
          buildCount2++;
          return child!;
        },
      );

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
            SingleChildBuilder(
              builder: (_, __) =>
                  const Text('foo', textDirection: TextDirection.ltr),
            ),
          ],
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
            SingleChildBuilder(
              builder: (_, __) =>
                  const Text('bar', textDirection: TextDirection.ltr),
            )
          ],
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('bar'), findsOneWidget);
    },
  );
  testWidgets(
    'child change rebuilds last node',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);

      var buildCount2 = 0;
      final second = SingleChildBuilder(
        builder: (_, child) {
          buildCount2++;
          return child!;
        },
      );

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [first, second],
          child: const Text('bar', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(2));
      expect(find.text('bar'), findsOneWidget);
    },
  );

  testWidgets(
    'if only one node, the previous and next nodes may not rebuild',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);
      var buildCount2 = 0;
      var buildCount3 = 0;
      final third = MySizedBox(didBuild: (_, __) => buildCount3++);

      final child = const Text('foo', textDirection: TextDirection.ltr);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            MySizedBox(
              didBuild: (_, __) => buildCount2++,
            ),
            third,
          ],
          child: child,
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(buildCount3, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            MySizedBox(
              didBuild: (_, __) => buildCount2++,
            ),
            third,
          ],
          child: child,
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(2));
      expect(buildCount3, equals(1));
      expect(find.text('foo'), findsOneWidget);
    },
  );

  testWidgets(
    'if child changes, rebuild the previous widget',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);
      var buildCount2 = 0;
      final second = MySizedBox(didBuild: (_, __) => buildCount2++);

      await tester.pumpWidget(
        Nested(
          children: [first, second],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
          ],
          child: const Text('bar', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(2));
      expect(find.text('bar'), findsOneWidget);
    },
  );

  testWidgets('last node receives child directly', (tester) async {
    Widget? child;
    BuildContext? context;

    await tester.pumpWidget(
      Nested(
        children: [
          SingleChildBuilder(
            builder: (ctx, c) {
              context = ctx;
              child = c;
              return Container();
            },
          )
        ],
        child: null,
      ),
    );

    expect(context, isNotNull);
    expect(child, isNull);

    final container = Container();

    await tester.pumpWidget(
      Nested(
        children: [
          SingleChildBuilder(
            builder: (ctx, c) {
              context = ctx;
              return (child = c)!;
            },
          )
        ],
        child: container,
      ),
    );

    expect(context, isNotNull);
    expect(child, equals(container));
  });
  // TODO: assert keys order preserved (reorder unsupported)
  // TODO: nodes can be added optionally using [if] (_Hook takes a globalKey on the child's key)
  // TODO: a nested node moves to a new Nested

  testWidgets('SingleChildBuilder can be used alone', (tester) async {
    Widget? child;
    BuildContext? context;
    var container = Container();

    await tester.pumpWidget(
      SingleChildBuilder(
        builder: (ctx, c) {
          context = ctx;
          child = c;
          return c!;
        },
        child: container,
      ),
    );

    expect(child, equals(container));
    expect(context, equals(tester.element(find.byType(SingleChildBuilder))));

    container = Container();

    await tester.pumpWidget(
      SingleChildBuilder(
        builder: (ctx, c) {
          context = ctx;
          child = c;
          return c!;
        },
        child: container,
      ),
    );

    expect(child, equals(container));
    expect(context, equals(tester.element(find.byType(SingleChildBuilder))));
  });
  testWidgets('SingleChildWidget can be used by itself', (tester) async {
    await tester.pumpWidget(
      MySizedBox(
        height: 42,
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('foo'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((e) => e.height, 'height', equals(42)),
      ]),
    );
  });
  testWidgets('SingleChildStatefulWidget can be used alone', (tester) async {
    Widget? child;
    BuildContext? context;

    final text = const Text('foo', textDirection: TextDirection.ltr);

    await tester.pumpWidget(
      MyStateful(
        didBuild: (ctx, c) {
          child = c;
          context = ctx;
        },
        child: text,
      ),
    );

    expect(find.text('foo'), findsOneWidget);
    expect(context, equals(tester.element(find.byType(MyStateful))));
    expect(child, equals(text));
  });
  testWidgets('SingleChildStatefulWidget can be used in nested',
      (tester) async {
    Widget? child;
    BuildContext? context;

    final text = const Text('foo', textDirection: TextDirection.ltr);

    await tester.pumpWidget(
      Nested(
        children: [
          MyStateful(
            didBuild: (ctx, c) {
              child = c;
              context = ctx;
            },
          ),
        ],
        child: text,
      ),
    );

    expect(find.text('foo'), findsOneWidget);
    expect(context, equals(tester.element(find.byType(MyStateful))));
    expect(child, equals(text));
  });
  testWidgets(
      'SingleChildStatelessWidget can be used as mixin instead of base class',
      (tester) async {
    await tester.pumpWidget(
      Nested(
        children: [
          ConcreteStateless(height: 24),
        ],
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    expect(
      find.byType(ConcreteStateless),
      matchesInOrder([
        isA<BaseStateless>().having((s) => s.height, 'height', 24),
      ]),
    );

    await tester.pumpWidget(
      ConcreteStateless(
        height: 24,
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    expect(
      find.byType(ConcreteStateless),
      matchesInOrder([
        isA<BaseStateless>().having((s) => s.height, 'height', 24),
      ]),
    );
  });
  testWidgets('SingleChildInheritedElementMixin', (tester) async {
    await tester.pumpWidget(
      Nested(
        children: [
          MyInherited(
            height: 24,
            child: const SizedBox.shrink(),
          ),
        ],
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    expect(
      find.byType(MyInherited),
      matchesInOrder([
        isA<MyInherited>().having((s) => s.height, 'height', 24),
      ]),
    );

    await tester.pumpWidget(
      MyInherited(
        height: 24,
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    expect(
      find.byType(MyInherited),
      matchesInOrder([
        isA<MyInherited>().having((s) => s.height, 'height', 24),
      ]),
    );
  });
  testWidgets('Nested with globalKeys', (tester) async {
    final firstKey = GlobalKey(debugLabel: 'first');
    final secondKey = GlobalKey(debugLabel: 'second');

    await tester.pumpWidget(
      Nested(
        children: [
          MyStateful(key: firstKey),
          MyStateful(key: secondKey),
        ],
        child: Container(),
      ),
    );

    // debugDumpApp();

    expect(
      find.byType(MyStateful),
      matchesInOrder([
        isA<MyStateful>().having((s) => s.key, 'key', firstKey),
        isA<MyStateful>().having((s) => s.key, 'key', secondKey),
      ]),
    );

    await tester.pumpWidget(
      Nested(
        children: [
          MyStateful(key: secondKey, didInit: () => throw Error()),
          MyStateful(key: firstKey, didInit: () => throw Error()),
        ],
        child: Container(),
      ),
    );

    // print('\n\n');

    //   debugDumpApp();

    expect(
      find.byType(MyStateful),
      matchesInOrder([
        isA<MyStateful>().having((s) => s.key, 'key', secondKey),
        isA<MyStateful>().having((s) => s.key, 'key', firstKey),
      ]),
    );
  });
  testWidgets(
      'SingleChildStatefulWidget can be used as mixin instead of base class',
      (tester) async {
    await tester.pumpWidget(
      Nested(
        children: [
          ConcreteStateful(height: 24),
        ],
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    expect(
      find
          .byType(ConcreteStateful)
          .evaluate()
          .map((e) => (e as StatefulElement).state),
      matchesInOrder([
        isA<_BaseStatefulState>()
            .having((s) => s.widget.height, 'widget.height', 24)
            .having((s) => s.width, 'width', 48),
      ]),
    );

    await tester.pumpWidget(
      ConcreteStateful(
        height: 24,
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    expect(
      find
          .byType(ConcreteStateful)
          .evaluate()
          .map((e) => (e as StatefulElement).state),
      matchesInOrder([
        isA<_BaseStatefulState>()
            .having((s) => s.widget.height, 'widget.height', 24)
            .having((s) => s.width, 'width', 48),
      ]),
    );
  });
}

class MyStateful extends SingleChildStatefulWidget {
  const MyStateful({Key? key, this.didBuild, this.didInit, Widget? child})
      : super(key: key, child: child);

  final void Function(BuildContext, Widget?)? didBuild;
  final void Function()? didInit;

  @override
  _MyStatefulState createState() => _MyStatefulState();
}

class _MyStatefulState extends SingleChildState<MyStateful> {
  @override
  void initState() {
    super.initState();
    widget.didInit?.call();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    widget.didBuild?.call(context, child);
    return child!;
  }
}

class MySizedBox extends SingleChildStatelessWidget {
  MySizedBox({Key? key, this.didBuild, this.height, Widget? child})
      : super(key: key, child: child);

  final double? height;

  final void Function(BuildContext context, Widget? child)? didBuild;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    didBuild?.call(context, child);
    return child!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('height', height));
  }
}

class MyInherited extends InheritedWidget implements SingleChildWidget {
  MyInherited({Key? key, this.height, required Widget child})
      : super(key: key, child: child);

  final double? height;

  @override
  MyInheritedElement createElement() => MyInheritedElement(this);

  @override
  bool updateShouldNotify(MyInherited oldWidget) {
    return height != oldWidget.height;
  }
}

class MyInheritedElement extends InheritedElement
    with SingleChildWidgetElementMixin, SingleChildInheritedElementMixin {
  MyInheritedElement(MyInherited widget) : super(widget);

  @override
  MyInherited get widget => super.widget as MyInherited;
}

abstract class BaseStateless extends StatelessWidget {
  const BaseStateless({Key? key, this.height}) : super(key: key);

  final double? height;
}

class ConcreteStateless extends BaseStateless
    with SingleChildStatelessWidgetMixin {
  ConcreteStateless({Key? key, this.child, double? height})
      : super(key: key, height: height);

  @override
  final Widget? child;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return Container(
      height: height,
      child: child,
    );
  }
}

abstract class BaseStateful extends StatefulWidget {
  const BaseStateful({Key? key, required this.height}) : super(key: key);

  final double height;
  @override
  _BaseStatefulState createState() => _BaseStatefulState();

  Widget build(BuildContext context);
}

class _BaseStatefulState extends State<BaseStateful> {
  double? width;

  @override
  void initState() {
    super.initState();
    width = widget.height * 2;
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

class ConcreteStateful extends BaseStateful
    with SingleChildStatefulWidgetMixin {
  ConcreteStateful({Key? key, required double height, this.child})
      : super(key: key, height: height);

  @override
  final Widget? child;

  @override
  Widget build(BuildContext context) => throw Error();

  @override
  _ConcreteStatefulState createState() => _ConcreteStatefulState();
}

class _ConcreteStatefulState extends _BaseStatefulState
    with SingleChildStateMixin {
  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return SizedBox(height: widget.height, width: width, child: child);
  }
}
