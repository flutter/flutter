// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test_driver_extended.dart';
// package:flutter_driver does not re-export package:webdriver, but
// WebFlutterDriver.webDriver returns its WebDriver, so faking a
// WebFlutterDriver needs these types.
// ignore: depend_on_referenced_packages
import 'package:webdriver/async_io.dart'
    show Mouse, MouseButton, MoveTargetOutOfBoundsException, WebDriver, WebElement;

void main() {
  group('integrationDriver handling webDriverClick', () {
    test('performs a WebDriver click at the position the app asked for', () async {
      final app = _FakeApp(clicks: <(num, num)>[(10, 20)]);
      final mouse = _FakeMouse();

      await _runIntegrationDriver(_FakeWebFlutterDriver(app, mouse));

      expect(mouse.clicks, <(int, int)>[(10, 20)]);
      expect(app.replies, <String>['complete']);
    });

    test('performs each click at its own position, in the order the app asked', () async {
      final app = _FakeApp(clicks: <(num, num)>[(10, 20), (300, 400)]);
      // The fake mouse, like WebDriver, moves relative to the pointer unless
      // asked for an absolute move, so this also checks that each click moves
      // the pointer to an absolute position.
      final mouse = _FakeMouse();

      await _runIntegrationDriver(_FakeWebFlutterDriver(app, mouse));

      expect(mouse.clicks, <(int, int)>[(10, 20), (300, 400)]);
      expect(app.replies, <String>['complete', 'complete']);
    });

    test(
      'rounds positions to whole CSS pixels, since WebDriver only moves by whole pixels',
      () async {
        final app = _FakeApp(clicks: <(num, num)>[(10.4, 20.6)]);
        final mouse = _FakeMouse();

        await _runIntegrationDriver(_FakeWebFlutterDriver(app, mouse));

        expect(mouse.clicks, <(int, int)>[(10, 21)]);
      },
    );

    test('accepts positions sent as JSON integers or as JSON doubles', () async {
      // Apps compiled with dart2js encode a double such as 30.0 as `30`, which
      // the host decodes as an int.
      final app = _FakeApp(clicks: <(num, num)>[(30, 0), (30.0, 0.0)]);
      final mouse = _FakeMouse();

      await _runIntegrationDriver(_FakeWebFlutterDriver(app, mouse));

      expect(mouse.clicks, <(int, int)>[(30, 0), (30, 0)]);
    });

    test('fails the click in the app and throws if the driver is not a WebFlutterDriver', () async {
      final app = _FakeApp(clicks: <(num, num)>[(10, 20)]);

      await expectLater(
        integrationDriver(driver: _FakeFlutterDriver(app), responseDataCallback: null),
        throwsA(
          isStateError.having(
            (StateError error) => error.message,
            'message',
            'webDriverClick requires a WebFlutterDriver, but received _FakeFlutterDriver',
          ),
        ),
      );
      expect(app.replies, <String>['error']);
    });

    test('fails the click in the app and rethrows if WebDriver cannot click', () async {
      final app = _FakeApp(clicks: <(num, num)>[(10, 20)]);
      const error = MoveTargetOutOfBoundsException(400, 'move target out of bounds');
      final mouse = _FakeMouse(moveToError: error);

      await expectLater(
        integrationDriver(driver: _FakeWebFlutterDriver(app, mouse), responseDataCallback: null),
        throwsA(same(error)),
      );
      expect(mouse.clicks, isEmpty);
      expect(app.replies, <String>['error']);
    });

    test('rethrows the WebDriver error even if the app disconnected before it was told', () async {
      final app = _FakeApp(clicks: <(num, num)>[(10, 20)], disconnectsOnError: true);
      const error = MoveTargetOutOfBoundsException(400, 'move target out of bounds');
      final mouse = _FakeMouse(moveToError: error);

      await expectLater(
        integrationDriver(driver: _FakeWebFlutterDriver(app, mouse), responseDataCallback: null),
        throwsA(same(error)),
      );
    });
  });
}

/// Runs [integrationDriver] with [driver] until all of the app's tests passed.
///
/// [integrationDriver] ends by calling `exit`, which would end this test
/// process, so the fake drivers throw [_DriverClosed] when [integrationDriver]
/// closes them just before that.
Future<void> _runIntegrationDriver(FlutterDriver driver) async {
  await expectLater(
    integrationDriver(driver: driver, responseDataCallback: null),
    throwsA(isA<_DriverClosed>()),
  );
}

class _DriverClosed implements Exception {
  const _DriverClosed();
}

/// Plays the in-browser test, which asks [integrationDriver] for clicks.
///
/// The host and the app talk through [FlutterDriver.requestData]:
///
///  1. The host sends `pending` to ask for the app's next command. The app
///     replies with a click command for the next position it was created
///     with, or, once all clicks are done, with a `noop` command.
///  2. After performing a click, the host sends `complete`, or `error` if it
///     could not perform it. The app records this in [replies], which is what
///     makes the app's `webDriverClick` call complete or fail, and replies
///     `ack`.
///  3. After the `noop` command, the host sends `null` to ask for the test
///     results, and the app replies that all tests passed.
class _FakeApp {
  _FakeApp({required List<(num, num)> clicks, this.disconnectsOnError = false})
    : _clicks = Queue<(num, num)>.of(clicks);

  /// The positions, in viewport CSS pixels, that the app asks to click.
  final Queue<(num, num)> _clicks;

  /// Whether the app disconnects instead of receiving an `error` reply.
  final bool disconnectsOnError;

  /// The host's reply to each click, in order.
  final List<String> replies = <String>[];

  Future<String> respondTo(String? message) async {
    switch (message) {
      case 'pending':
        if (_clicks.isEmpty) {
          return _webDriverCommand(WebDriverCommandType.noop);
        }
        final (num x, num y) = _clicks.removeFirst();
        return _webDriverCommand(WebDriverCommandType.click, <String, dynamic>{'x': x, 'y': y});
      case 'complete' || 'error':
        if (message == 'error' && disconnectsOnError) {
          throw const SocketException('app disconnected');
        }
        replies.add(message!);
        return _webDriverCommand(WebDriverCommandType.ack);
      case null:
        return Response.allTestsPassed().toJson();
    }
    throw StateError('Unexpected message from the host: $message');
  }

  static String _webDriverCommand(
    WebDriverCommandType type, [
    Map<String, dynamic> values = const <String, dynamic>{},
  ]) {
    return Response.webDriverCommand(
      data: <String, dynamic>{...values, ...WebDriverCommand.typeToMap(type)},
    ).toJson();
  }
}

/// A [FlutterDriver] connected to [app], without WebDriver access.
class _FakeFlutterDriver extends Fake implements FlutterDriver {
  _FakeFlutterDriver(this.app);

  final _FakeApp app;

  @override
  Future<String> requestData(String? message, {Duration? timeout}) => app.respondTo(message);

  @override
  Future<void> close() async => throw const _DriverClosed();
}

/// A [WebFlutterDriver] connected to [app], whose WebDriver session clicks
/// with the given mouse.
class _FakeWebFlutterDriver extends _FakeFlutterDriver implements WebFlutterDriver {
  _FakeWebFlutterDriver(super.app, _FakeMouse mouse) : webDriver = _FakeWebDriver(mouse);

  @override
  final WebDriver webDriver;
}

/// A WebDriver session whose only faked member is [mouse].
class _FakeWebDriver extends Fake implements WebDriver {
  _FakeWebDriver(this.mouse);

  @override
  final Mouse mouse;
}

/// A WebDriver mouse that records the pointer position of each click.
class _FakeMouse extends Fake implements Mouse {
  _FakeMouse({this.moveToError});

  /// If non-null, thrown by [moveTo] instead of moving the pointer.
  final Exception? moveToError;

  /// The pointer position, in viewport CSS pixels, of each primary click.
  final List<(int, int)> clicks = <(int, int)>[];

  (int, int) _pointer = (0, 0);

  @override
  Future<void> moveTo({
    WebElement? element,
    int? xOffset,
    int? yOffset,
    bool absolute = false,
  }) async {
    if (moveToError != null) {
      throw moveToError!;
    }
    if (element != null) {
      throw UnimplementedError('Moving relative to an element is not faked.');
    }
    final (int x, int y) = (xOffset ?? 0, yOffset ?? 0);
    // As in WebDriver, an absolute move is relative to the viewport origin,
    // and any other move is relative to the current pointer position.
    _pointer = absolute ? (x, y) : (_pointer.$1 + x, _pointer.$2 + y);
  }

  @override
  Future<void> click([MouseButton button = MouseButton.primary]) async {
    if (button != MouseButton.primary) {
      throw UnimplementedError('Only primary clicks are faked.');
    }
    clicks.add(_pointer);
  }
}
