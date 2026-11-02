// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/src/callback.dart' as driver_actions;

/// A [CallbackManager] subclass written before `pointerActions` existed,
/// overriding only the members that were abstract at that time.
class _PreexistingCallbackManager extends CallbackManager {
  @override
  Future<Map<String, dynamic>> callback(
    Map<String, String> params,
    IntegrationTestResults testRunner,
  ) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> takeScreenshot(
    String screenshot, [
    Map<String, Object?>? args,
  ]) async => <String, dynamic>{};

  @override
  Future<void> convertFlutterSurfaceToImage() async {}

  @override
  void cleanup() {}
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WebDriverPointerAction', () {
    test('round-trips every action kind through toJson and fromJson', () {
      const cases = <(WebDriverPointerAction, Map<String, Object?>)>[
        (
          WebDriverPointerAction.move(12.5, 34.25),
          <String, Object?>{'type': 'pointerMove', 'x': 12.5, 'y': 34.25, 'duration': 0},
        ),
        (
          WebDriverPointerAction.move(10, 20, duration: Duration(milliseconds: 300)),
          <String, Object?>{'type': 'pointerMove', 'x': 10.0, 'y': 20.0, 'duration': 300},
        ),
        (WebDriverPointerAction.down(), <String, Object?>{'type': 'pointerDown', 'button': 0}),
        (
          WebDriverPointerAction.down(button: WebDriverMouseButton.middle),
          <String, Object?>{'type': 'pointerDown', 'button': 1},
        ),
        (
          WebDriverPointerAction.down(button: WebDriverMouseButton.secondary),
          <String, Object?>{'type': 'pointerDown', 'button': 2},
        ),
        (WebDriverPointerAction.up(), <String, Object?>{'type': 'pointerUp', 'button': 0}),
        (
          WebDriverPointerAction.up(button: WebDriverMouseButton.middle),
          <String, Object?>{'type': 'pointerUp', 'button': 1},
        ),
        (
          WebDriverPointerAction.up(button: WebDriverMouseButton.secondary),
          <String, Object?>{'type': 'pointerUp', 'button': 2},
        ),
        (
          WebDriverPointerAction.pause(Duration(milliseconds: 150)),
          <String, Object?>{'type': 'pause', 'duration': 150},
        ),
      ];

      for (final (WebDriverPointerAction action, Map<String, Object?> json) in cases) {
        expect(action.toJson(), json);
        final decoded = WebDriverPointerAction.fromJson(json);
        expect(decoded, action);
        expect(decoded.hashCode, action.hashCode);
      }
    });

    test('fromJson accepts integer move coordinates', () {
      // Apps compiled with dart2js encode whole-number doubles such as 30.0 as
      // `30`, which the host decodes as an int.
      final decoded = WebDriverPointerAction.fromJson(const <String, Object?>{
        'type': 'pointerMove',
        'x': 30,
        'y': 40,
        'duration': 0,
      });

      expect(decoded, const WebDriverPointerAction.move(30, 40));
    });

    test('fromJson throws FormatException on unknown type or malformed fields', () {
      for (final invalid in const <Map<String, Object?>>[
        <String, Object?>{},
        <String, Object?>{'type': null},
        <String, Object?>{'type': 'wheel'},
        <String, Object?>{'type': 'pointerMove', 'x': 10},
        <String, Object?>{'type': 'pointerMove', 'x': 10, 'y': 20},
        <String, Object?>{'type': 'pointerMove', 'x': '10', 'y': 20, 'duration': 0},
        <String, Object?>{'type': 'pointerMove', 'x': 10, 'y': null, 'duration': 0},
        <String, Object?>{'type': 'pointerMove', 'x': 10, 'y': 20, 'duration': '0'},
        <String, Object?>{'type': 'pointerDown'},
        <String, Object?>{'type': 'pointerDown', 'button': -1},
        <String, Object?>{'type': 'pointerDown', 'button': 99},
        <String, Object?>{'type': 'pointerDown', 'button': 1.5},
        <String, Object?>{'type': 'pointerDown', 'button': 'primary'},
        <String, Object?>{'type': 'pointerUp'},
        <String, Object?>{'type': 'pointerUp', 'button': 3},
        <String, Object?>{'type': 'pointerUp', 'button': 'secondary'},
        <String, Object?>{'type': 'pause'},
        <String, Object?>{'type': 'pause', 'duration': null},
        <String, Object?>{'type': 'pause', 'duration': '100'},
      ]) {
        expect(() => WebDriverPointerAction.fromJson(invalid), throwsFormatException);
      }
    });

    test('equality, hashCode, and toString distinguish action types and fields', () {
      const moveA = WebDriverPointerAction.move(10, 20);
      const moveDifferentX = WebDriverPointerAction.move(11, 20);
      const moveDifferentY = WebDriverPointerAction.move(10, 21);
      const moveDifferentDuration = WebDriverPointerAction.move(
        10,
        20,
        duration: Duration(milliseconds: 50),
      );
      const downPrimary = WebDriverPointerAction.down();
      const downSecondary = WebDriverPointerAction.down(button: WebDriverMouseButton.secondary);
      const upPrimary = WebDriverPointerAction.up();
      const pauseZero = WebDriverPointerAction.pause(Duration.zero);

      expect(moveA, isNot(moveDifferentX));
      expect(moveA, isNot(moveDifferentY));
      expect(moveA, isNot(moveDifferentDuration));
      expect(downPrimary, isNot(downSecondary));
      expect(downPrimary, isNot(upPrimary));
      expect(const WebDriverPointerAction.move(0, 0), isNot(pauseZero));

      expect(
        moveDifferentDuration.toString(),
        'WebDriverPointerAction.move(10.0, 20.0, duration: 0:00:00.050000)',
      );
      expect(
        downSecondary.toString(),
        'WebDriverPointerAction.down(button: WebDriverMouseButton.secondary)',
      );
      expect(
        upPrimary.toString(),
        'WebDriverPointerAction.up(button: WebDriverMouseButton.primary)',
      );
      expect(pauseZero.toString(), 'WebDriverPointerAction.pause(0:00:00.000000)');
    });

    test('constructors create the matching subtype with non-nullable fields', () {
      String describe(WebDriverPointerAction action) {
        return switch (action) {
          WebDriverPointerMove(:final double x, :final double y, :final Duration duration) =>
            'move $x,$y ${duration.inMilliseconds}',
          WebDriverPointerDown(:final WebDriverMouseButton button) => 'down ${button.w3cButton}',
          WebDriverPointerUp(:final WebDriverMouseButton button) => 'up ${button.w3cButton}',
          WebDriverPointerPause(:final Duration duration) => 'pause ${duration.inMilliseconds}',
        };
      }

      expect(const WebDriverPointerAction.move(1, 2), isA<WebDriverPointerMove>());
      expect(const WebDriverPointerAction.down(), isA<WebDriverPointerDown>());
      expect(const WebDriverPointerAction.up(), isA<WebDriverPointerUp>());
      expect(const WebDriverPointerAction.pause(Duration.zero), isA<WebDriverPointerPause>());

      expect(describe(const WebDriverPointerAction.move(1, 2)), 'move 1.0,2.0 0');
      expect(
        describe(const WebDriverPointerAction.move(1, 2, duration: Duration(milliseconds: 7))),
        'move 1.0,2.0 7',
      );
      expect(describe(const WebDriverPointerAction.down()), 'down 0');
      expect(
        describe(const WebDriverPointerAction.up(button: WebDriverMouseButton.secondary)),
        'up 2',
      );
      expect(describe(const WebDriverPointerAction.pause(Duration(milliseconds: 9))), 'pause 9');

      // The factory constructors and the subtype constructors are
      // interchangeable.
      expect(const WebDriverPointerAction.move(1, 2), const WebDriverPointerMove(1, 2));
      expect(const WebDriverPointerAction.down(), const WebDriverPointerDown());
      expect(const WebDriverPointerAction.up(), const WebDriverPointerUp());
      expect(
        const WebDriverPointerAction.pause(Duration.zero),
        const WebDriverPointerPause(Duration.zero),
      );
    });
  });

  group('WebDriverCommand.pointerActions', () {
    test('carries the pointerActions type and serialized actions', () {
      const actions = <WebDriverPointerAction>[
        WebDriverPointerAction.move(12.5, 34.25, duration: Duration(milliseconds: 250)),
        WebDriverPointerAction.down(),
        WebDriverPointerAction.up(),
      ];
      final command = WebDriverCommand.pointerActions(actions);

      expect(command.type, WebDriverCommandType.pointerActions);
      expect(command.values, <String, dynamic>{
        'actions': <Map<String, Object?>>[
          <String, Object?>{'type': 'pointerMove', 'x': 12.5, 'y': 34.25, 'duration': 250},
          <String, Object?>{'type': 'pointerDown', 'button': 0},
          <String, Object?>{'type': 'pointerUp', 'button': 0},
        ],
      });
    });

    test('snapshots the action list at construction time', () {
      final actions = <WebDriverPointerAction>[
        const WebDriverPointerAction.move(1, 2),
        const WebDriverPointerAction.down(),
      ];
      final command = WebDriverCommand.pointerActions(actions);

      actions
        ..clear()
        ..add(const WebDriverPointerAction.up(button: WebDriverMouseButton.secondary));

      expect(command.values, <String, dynamic>{
        'actions': <Map<String, Object?>>[
          <String, Object?>{'type': 'pointerMove', 'x': 1.0, 'y': 2.0, 'duration': 0},
          <String, Object?>{'type': 'pointerDown', 'button': 0},
        ],
      });
    });

    test('serializes to the web_driver_command message the host driver reads', () {
      const actions = <WebDriverPointerAction>[
        WebDriverPointerAction.move(12.5, 34.25),
        WebDriverPointerAction.down(button: WebDriverMouseButton.secondary),
        WebDriverPointerAction.pause(Duration(milliseconds: 50)),
        WebDriverPointerAction.up(button: WebDriverMouseButton.secondary),
      ];
      final command = WebDriverCommand.pointerActions(actions);
      final data = Map<String, dynamic>.of(command.values)
        ..addAll(WebDriverCommand.typeToMap(command.type));

      final Response received = Response.fromJson(Response.webDriverCommand(data: data).toJson());

      expect(received.data, <String, dynamic>{
        'actions': <Map<String, Object?>>[
          <String, Object?>{'type': 'pointerMove', 'x': 12.5, 'y': 34.25, 'duration': 0},
          <String, Object?>{'type': 'pointerDown', 'button': 2},
          <String, Object?>{'type': 'pause', 'duration': 50},
          <String, Object?>{'type': 'pointerUp', 'button': 2},
        ],
        'web_driver_command': 'WebDriverCommandType.pointerActions',
      });
    });
  });

  group('CallbackManager.pointerActions', () {
    test('defaults to UnsupportedError for implementations that predate it', () async {
      final CallbackManager manager = _PreexistingCallbackManager();

      await expectLater(
        () => manager.pointerActions(const <WebDriverPointerAction>[
          WebDriverPointerAction.move(1, 2),
        ]),
        throwsUnsupportedError,
      );
    });

    test('throws UnsupportedError off the web', () async {
      await expectLater(
        () => driver_actions.callbackManager.pointerActions(const <WebDriverPointerAction>[
          WebDriverPointerAction.move(1, 2),
        ]),
        throwsA(
          isUnsupportedError.having(
            (UnsupportedError error) => error.message,
            'message',
            'webDriverPointerActions is only supported on the web',
          ),
        ),
      );
    });
  });

  testWidgets('webDriverPointerActions and webDriverClick throw UnsupportedError off the web', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox.expand());

    await expectLater(
      () => binding.webDriverPointerActions(const <WebDriverPointerAction>[
        WebDriverPointerAction.move(1, 2),
      ]),
      throwsA(
        isUnsupportedError.having(
          (UnsupportedError error) => error.message,
          'message',
          contains('webDriverPointerActions'),
        ),
      ),
    );

    await expectLater(
      () => binding.webDriverClick(Offset.zero),
      throwsA(
        isUnsupportedError.having(
          (UnsupportedError error) => error.message,
          'message',
          contains('webDriverPointerActions'),
        ),
      ),
    );
  });

  testWidgets(
    'webDriverPointerActions rejects empty sequences, non-finite coordinates, and negative durations',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.expand());

      for (final invalidActions in <List<WebDriverPointerAction>>[
        const <WebDriverPointerAction>[],
        const <WebDriverPointerAction>[WebDriverPointerAction.move(double.nan, 0)],
        const <WebDriverPointerAction>[WebDriverPointerAction.move(0, double.infinity)],
        const <WebDriverPointerAction>[WebDriverPointerAction.move(double.negativeInfinity, 0)],
        const <WebDriverPointerAction>[
          WebDriverPointerAction.move(0, 0, duration: Duration(milliseconds: -1)),
        ],
        const <WebDriverPointerAction>[WebDriverPointerAction.pause(Duration(milliseconds: -1))],
      ]) {
        await expectLater(
          () => binding.webDriverPointerActions(invalidActions),
          throwsArgumentError,
        );
      }

      for (final position in const <Offset>[
        Offset.infinite,
        Offset(double.nan, 0),
        Offset(0, double.negativeInfinity),
      ]) {
        await expectLater(() => binding.webDriverClick(position), throwsArgumentError);
      }
    },
  );

  testWidgets(
    'webDriverPointerActions validates all actions in a sequence before invoking callbackManager',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.expand());

      // A valid leading action followed by a malformed trailing action must still
      // fail fast with ArgumentError rather than reaching callbackManager
      // (which throws UnsupportedError off the web).
      for (final sequenceWithTrailingInvalidAction in const <List<WebDriverPointerAction>>[
        <WebDriverPointerAction>[
          WebDriverPointerAction.move(10, 20),
          WebDriverPointerAction.down(),
          WebDriverPointerAction.move(10, double.nan),
        ],
        <WebDriverPointerAction>[
          WebDriverPointerAction.move(10, 20),
          WebDriverPointerAction.down(),
          WebDriverPointerAction.pause(Duration(milliseconds: -5)),
        ],
      ]) {
        await expectLater(
          () =>
              binding.webDriverPointerActions(sequenceWithTrailingInvalidAction, view: tester.view),
          throwsArgumentError,
        );
      }

      // Finite zero and negative coordinates with an explicit view pass argument
      // validation and reach callbackManager.
      await expectLater(
        () => binding.webDriverPointerActions(const <WebDriverPointerAction>[
          WebDriverPointerAction.move(-10, 0),
        ], view: tester.view),
        throwsUnsupportedError,
      );
    },
  );
}
