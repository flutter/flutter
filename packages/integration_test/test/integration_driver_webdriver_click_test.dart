// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test_driver_extended.dart';
// package:webdriver is provided through package:flutter_driver, whose
// WebFlutterDriver.webDriver exposes these types.
// ignore: depend_on_referenced_packages
import 'package:webdriver/async_io.dart'
    show Mouse, MouseButton, MoveTargetOutOfBoundsException, WebDriver, WebElement;

/// Thrown by the fake drivers' `close` so that [integrationDriver] never
/// reaches its `exit` call and terminates the test process.
class _ExitPrevented implements Exception {
  const _ExitPrevented();
}

String _command(WebDriverCommandType type, [Map<String, dynamic> values = const {}]) {
  return Response.webDriverCommand(
    data: <String, dynamic>{...values, ...WebDriverCommand.typeToMap(type)},
  ).toJson();
}

String _click(double x, double y) =>
    _command(WebDriverCommandType.click, <String, dynamic>{'x': x, 'y': y});

/// A [FlutterDriver] that plays the in-browser side of the WebDriver command
/// handshake from [replies] and records everything the host driver asks of it.
class _ScriptedFlutterDriver extends Fake implements FlutterDriver {
  _ScriptedFlutterDriver(this.events, this.replies);

  final List<String> events;

  /// Replies to `requestData`, keyed by the message the host sends.
  final Map<String?, Future<String> Function()> replies;

  @override
  Future<String> requestData(String? message, {Duration? timeout}) {
    events.add('requestData($message)');
    final Future<String> Function()? reply = replies[message];
    if (reply == null) {
      throw StateError('No scripted reply for requestData($message)');
    }
    return reply();
  }

  @override
  Future<List<int>> screenshot({ScreenshotFormat format = ScreenshotFormat.png}) async {
    events.add('screenshot');
    return <int>[];
  }

  @override
  Future<void> close() async {
    events.add('close');
    throw const _ExitPrevented();
  }
}

class _ScriptedWebFlutterDriver extends _ScriptedFlutterDriver implements WebFlutterDriver {
  _ScriptedWebFlutterDriver(super.events, super.replies, this.webDriver);

  @override
  final WebDriver webDriver;
}

class _FakeWebDriver extends Fake implements WebDriver {
  _FakeWebDriver(this.mouse);

  @override
  final Mouse mouse;
}

class _RecordingMouse extends Fake implements Mouse {
  _RecordingMouse(this.events, {this.moveToError, this.clickError});

  final List<String> events;
  final Exception? moveToError;
  final Exception? clickError;

  @override
  Future<void> moveTo({
    WebElement? element,
    int? xOffset,
    int? yOffset,
    bool absolute = false,
  }) async {
    events.add(
      'moveTo(element: $element, xOffset: $xOffset, yOffset: $yOffset, absolute: $absolute)',
    );
    if (moveToError != null) {
      throw moveToError!;
    }
  }

  @override
  Future<void> click([MouseButton button = MouseButton.primary]) async {
    // MouseButton is a class without a toString, so name the button here.
    final buttonName = button == MouseButton.primary
        ? 'MouseButton.primary'
        : 'MouseButton(${button.value})';
    events.add('click($buttonName)');
    if (clickError != null) {
      throw clickError!;
    }
  }
}

void main() {
  final String ack = _command(WebDriverCommandType.ack);
  final String noop = _command(WebDriverCommandType.noop);
  final String allTestsPassed = Response.allTestsPassed().toJson();

  test(
    'click performs an absolute WebDriver mouse move and click, then replies complete',
    () async {
      final events = <String>[];
      final driver = _ScriptedWebFlutterDriver(events, <String?, Future<String> Function()>{
        'pending': () async => events.contains('requestData(complete)') ? noop : _click(10.4, 20.6),
        'complete': () async => ack,
        null: () async => allTestsPassed,
      }, _FakeWebDriver(_RecordingMouse(events)));

      await expectLater(
        integrationDriver(driver: driver, responseDataCallback: null),
        throwsA(isA<_ExitPrevented>()),
      );

      expect(events, <String>[
        'requestData(pending)',
        'moveTo(element: null, xOffset: 10, yOffset: 21, absolute: true)',
        'click(MouseButton.primary)',
        'requestData(complete)',
        'requestData(pending)',
        'requestData(null)',
        'close',
      ]);
      expect(events, isNot(contains('screenshot')));
    },
  );

  test('clicks with integer coordinates, as JSON-encoded by dart2js, run in order', () async {
    // dart2js encodes integral doubles such as 30.0 as `30`, which the host
    // decodes as an int rather than a double.
    final events = <String>[];
    final commands = <String>[
      _command(WebDriverCommandType.click, <String, dynamic>{'x': 30, 'y': 0}),
      _click(7.5, 8.25),
      noop,
    ];
    final driver = _ScriptedWebFlutterDriver(events, <String?, Future<String> Function()>{
      'pending': () async => commands.removeAt(0),
      'complete': () async => ack,
      null: () async => allTestsPassed,
    }, _FakeWebDriver(_RecordingMouse(events)));

    await expectLater(
      integrationDriver(driver: driver, responseDataCallback: null),
      throwsA(isA<_ExitPrevented>()),
    );

    expect(events, <String>[
      'requestData(pending)',
      'moveTo(element: null, xOffset: 30, yOffset: 0, absolute: true)',
      'click(MouseButton.primary)',
      'requestData(complete)',
      'requestData(pending)',
      'moveTo(element: null, xOffset: 8, yOffset: 8, absolute: true)',
      'click(MouseButton.primary)',
      'requestData(complete)',
      'requestData(pending)',
      'requestData(null)',
      'close',
    ]);
  });

  test(
    'click on a driver that is not a WebFlutterDriver replies error and throws StateError',
    () async {
      final events = <String>[];
      final driver = _ScriptedFlutterDriver(events, <String?, Future<String> Function()>{
        'pending': () async => _click(10, 20),
        'error': () async => ack,
      });

      await expectLater(
        integrationDriver(driver: driver, responseDataCallback: null),
        throwsA(
          isStateError.having(
            (StateError error) => error.message,
            'message',
            'webDriverClick requires a WebFlutterDriver, but received _ScriptedFlutterDriver',
          ),
        ),
      );

      expect(events, <String>['requestData(pending)', 'requestData(error)']);
    },
  );

  group('click when WebDriver throws replies error, then rethrows the WebDriver exception', () {
    const outOfBounds = MoveTargetOutOfBoundsException(400, 'move target out of bounds');

    for (final (String name, _RecordingMouse Function(List<String>) mouse, List<String> mouseEvents)
        in <(String, _RecordingMouse Function(List<String>), List<String>)>[
          (
            'from moveTo',
            (List<String> events) => _RecordingMouse(events, moveToError: outOfBounds),
            <String>['moveTo(element: null, xOffset: 5000, yOffset: 5000, absolute: true)'],
          ),
          (
            'from click',
            (List<String> events) => _RecordingMouse(events, clickError: outOfBounds),
            <String>[
              'moveTo(element: null, xOffset: 5000, yOffset: 5000, absolute: true)',
              'click(MouseButton.primary)',
            ],
          ),
        ]) {
      test(name, () async {
        final events = <String>[];
        final driver = _ScriptedWebFlutterDriver(events, <String?, Future<String> Function()>{
          'pending': () async => _click(5000, 5000),
          'error': () async => ack,
        }, _FakeWebDriver(mouse(events)));

        await expectLater(
          integrationDriver(driver: driver, responseDataCallback: null),
          throwsA(same(outOfBounds)),
        );

        expect(events, <String>['requestData(pending)', ...mouseEvents, 'requestData(error)']);
      });
    }

    test('even when replying error fails because the app disconnected', () async {
      final events = <String>[];
      final driver = _ScriptedWebFlutterDriver(events, <String?, Future<String> Function()>{
        'pending': () async => _click(5000, 5000),
        'error': () async => throw const SocketException('app disconnected'),
      }, _FakeWebDriver(_RecordingMouse(events, moveToError: outOfBounds)));

      await expectLater(
        integrationDriver(driver: driver, responseDataCallback: null),
        throwsA(same(outOfBounds)),
      );

      expect(events, <String>[
        'requestData(pending)',
        'moveTo(element: null, xOffset: 5000, yOffset: 5000, absolute: true)',
        'requestData(error)',
      ]);
    });
  });
}
