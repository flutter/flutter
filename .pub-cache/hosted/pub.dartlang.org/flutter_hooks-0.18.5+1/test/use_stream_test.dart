// ignore_for_file: close_sinks

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

/// port of [StreamBuilder]
///
void main() {
  testWidgets('debugFillProperties', (tester) async {
    final stream = Stream.value(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useStream(stream, initialData: 42);
        return const SizedBox();
      }),
    );

    await tester.pump();

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useStream: AsyncSnapshot<int>(ConnectionState.done, 42, null,\n'
        ' │   null)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('default preserve state, changing stream keeps previous value',
      (tester) async {
    late AsyncSnapshot<int>? value;
    Widget Function(BuildContext) builder(Stream<int> stream) {
      return (context) {
        value = useStream(stream);
        return Container();
      };
    }

    var stream = Stream.fromFuture(Future.value(0));
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, null);
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, 0);

    stream = Stream.fromFuture(Future.value(42));
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, 0);
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, 42);
  });
  testWidgets('If preserveState == false, changing stream resets value',
      (tester) async {
    late AsyncSnapshot<int>? value;
    Widget Function(BuildContext) builder(Stream<int> stream) {
      return (context) {
        value = useStream(stream, preserveState: false);
        return Container();
      };
    }

    var stream = Stream.fromFuture(Future.value(0));
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, null);
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, 0);

    stream = Stream.fromFuture(Future.value(42));
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, null);
    await tester.pumpWidget(HookBuilder(builder: builder(stream)));
    expect(value!.data, 42);
  });

  Widget Function(BuildContext) snapshotText(Stream<String> stream,
      {String? initialData}) {
    return (context) {
      final snapshot = useStream(stream, initialData: initialData ?? '');
      return Text(snapshot.toString(), textDirection: TextDirection.ltr);
    };
  }

  testWidgets('gracefully handles transition to other stream', (tester) async {
    final controllerA = StreamController<String>();
    final controllerB = StreamController<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controllerA.stream)));
    expect(
        find.text(
          'AsyncSnapshot<String>(ConnectionState.waiting, , null, null)',
        ),
        findsOneWidget);
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controllerB.stream)));
    controllerB.add('B');
    controllerA.add('A');
    await eventFiring(tester);
    expect(
        find.text(
            'AsyncSnapshot<String>(ConnectionState.active, B, null, null)'),
        findsOneWidget);
  });
  testWidgets('tracks events and errors of stream until completion',
      (tester) async {
    final controller = StreamController<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controller.stream)));
    expect(
        find.text(
          'AsyncSnapshot<String>(ConnectionState.waiting, , null, null)',
        ),
        findsOneWidget);
    controller
      ..add('1')
      ..add('2');
    await eventFiring(tester);
    expect(
        find.text(
          'AsyncSnapshot<String>(ConnectionState.active, 2, null, null)',
        ),
        findsOneWidget);
    controller
      ..add('3')
      ..addError('bad', StackTrace.fromString('stackTrace'));

    await eventFiring(tester);

    expect(
      find.text(
        'AsyncSnapshot<String>(ConnectionState.active, null, bad, stackTrace)',
      ),
      findsOneWidget,
    );

    controller.add('4');
    await controller.close();
    await eventFiring(tester);

    expect(
      find.text('AsyncSnapshot<String>(ConnectionState.done, 4, null, null)'),
      findsOneWidget,
    );
  });
  testWidgets('runs the builder using given initial data', (tester) async {
    final controller = StreamController<String>();
    await tester.pumpWidget(
      HookBuilder(
        builder: snapshotText(controller.stream, initialData: 'I'),
      ),
    );

    expect(
      find.text(
          'AsyncSnapshot<String>(ConnectionState.waiting, I, null, null)'),
      findsOneWidget,
    );
  });
  testWidgets('ignores initialData when reconfiguring', (tester) async {
    await tester.pumpWidget(
      HookBuilder(
        builder: snapshotText(const Stream.empty(), initialData: 'I'),
      ),
    );

    expect(
      find.text(
          'AsyncSnapshot<String>(ConnectionState.waiting, I, null, null)'),
      findsOneWidget,
    );

    final controller = StreamController<String>();

    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(controller.stream, initialData: 'Ignored'),
    ));

    expect(
      find.text(
        'AsyncSnapshot<String>(ConnectionState.waiting, I, null, null)',
      ),
      findsOneWidget,
    );
  });
}

Future<void> eventFiring(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}
