import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useStreamController<int>();
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
        ' │ useStreamController: Instance of\n'
        // ignore: avoid_escaping_inner_quotes
        ' │   \'_AsyncBroadcastStreamController<int>\'\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useStreamController', () {
    testWidgets('keys', (tester) async {
      late StreamController<int> controller;

      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = useStreamController();
        return Container();
      }));

      final previous = controller;
      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = useStreamController(keys: []);
        return Container();
      }));

      expect(previous, isNot(controller));
    });
    testWidgets('basics', (tester) async {
      late StreamController<int> controller;

      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = useStreamController();
        return Container();
      }));

      expect(controller, isNot(isInstanceOf<SynchronousStreamController>()));
      expect(controller.onListen, isNull);
      expect(controller.onCancel, isNull);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      final previousController = controller;
      void onListen() {}
      void onCancel() {}
      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = useStreamController(
          sync: true,
          onCancel: onCancel,
          onListen: onListen,
        );
        return Container();
      }));

      expect(controller, previousController);
      expect(controller, isNot(isInstanceOf<SynchronousStreamController>()));
      expect(controller.onListen, onListen);
      expect(controller.onCancel, onCancel);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      await tester.pumpWidget(Container());

      expect(controller.isClosed, true);
    });
    testWidgets('sync', (tester) async {
      late StreamController<int> controller;

      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = useStreamController(sync: true);
        return Container();
      }));

      expect(controller, isInstanceOf<SynchronousStreamController>());
      expect(controller.onListen, isNull);
      expect(controller.onCancel, isNull);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      final previousController = controller;
      void onListen() {}
      void onCancel() {}
      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = useStreamController(
          onCancel: onCancel,
          onListen: onListen,
        );
        return Container();
      }));

      expect(controller, previousController);
      expect(controller, isInstanceOf<SynchronousStreamController>());
      expect(controller.onListen, onListen);
      expect(controller.onCancel, onCancel);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      await tester.pumpWidget(Container());

      expect(controller.isClosed, true);
    });
  });
}
