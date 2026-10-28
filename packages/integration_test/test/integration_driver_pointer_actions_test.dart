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
import 'package:webdriver/async_io.dart' show MoveTargetOutOfBoundsException, WebDriver;

void main() {
  group('integrationDriver handling webDriverPointerActions', () {
    test('sends one W3C perform-actions request with rounded viewport moves, timed moves subdivided into steps, and pauses', () async {
      final app = _FakeApp(
        sequences: const <List<WebDriverPointerAction>>[
          <WebDriverPointerAction>[
            // The first move has no known start position, so it is sent as is.
            WebDriverPointerAction.move(10.4, 20.6, duration: Duration(milliseconds: 300)),
            WebDriverPointerAction.down(),
            // Moves from (10, 21) to (50, 61) in ceil(50 / 16) = 4 steps.
            WebDriverPointerAction.move(50.4, 60.6, duration: Duration(milliseconds: 50)),
            WebDriverPointerAction.up(),
            WebDriverPointerAction.pause(Duration(milliseconds: 100)),
          ],
        ],
      );
      final webDriver = _FakeWebDriver();

      await _runIntegrationDriver(_FakeWebFlutterDriver(app, webDriver));

      expect(webDriver.postRequests, <Map<String, Object?>>[
        <String, Object?>{
          'command': 'actions',
          'params': <String, Object?>{
            'actions': <Map<String, Object?>>[
              <String, Object?>{
                'type': 'pointer',
                'id': 'integration_test_mouse',
                'parameters': <String, Object?>{'pointerType': 'mouse'},
                'actions': <Map<String, Object?>>[
                  <String, Object?>{
                    'type': 'pointerMove',
                    'origin': 'viewport',
                    'x': 10,
                    'y': 21,
                    'duration': 300,
                  },
                  <String, Object?>{'type': 'pointerDown', 'button': 0},
                  _pointerMove(20, 31, 12),
                  _pointerMove(30, 41, 13),
                  _pointerMove(40, 51, 12),
                  _pointerMove(50, 61, 13),
                  <String, Object?>{'type': 'pointerUp', 'button': 0},
                  <String, Object?>{'type': 'pause', 'duration': 100},
                ],
              },
            ],
          },
        },
      ]);
      expect(webDriver.deleteRequests, isEmpty);
      expect(app.replies, <String>['complete']);
    });

    test(
      'performs multiple sequences in order and accepts integer or double move coordinates',
      () async {
        // Apps compiled with dart2js encode a double such as 30.0 as `30`,
        // which the host decodes as an int.
        final app = _FakeApp(
          rawSequences: const <List<Map<String, Object?>>>[
            <Map<String, Object?>>[
              <String, Object?>{'type': 'pointerMove', 'x': 30, 'y': 40, 'duration': 0},
              <String, Object?>{'type': 'pointerDown', 'button': 0},
              <String, Object?>{'type': 'pointerUp', 'button': 0},
            ],
            <Map<String, Object?>>[
              <String, Object?>{'type': 'pointerMove', 'x': 300.0, 'y': 400.0, 'duration': 0},
              <String, Object?>{'type': 'pointerDown', 'button': 2},
              <String, Object?>{'type': 'pointerUp', 'button': 2},
            ],
          ],
        );
        final webDriver = _FakeWebDriver();

        await _runIntegrationDriver(_FakeWebFlutterDriver(app, webDriver));

        expect(webDriver.postRequests, <Map<String, Object?>>[
          <String, Object?>{
            'command': 'actions',
            'params': <String, Object?>{
              'actions': <Map<String, Object?>>[
                <String, Object?>{
                  'type': 'pointer',
                  'id': 'integration_test_mouse',
                  'parameters': <String, Object?>{'pointerType': 'mouse'},
                  'actions': <Map<String, Object?>>[
                    <String, Object?>{
                      'type': 'pointerMove',
                      'origin': 'viewport',
                      'x': 30,
                      'y': 40,
                      'duration': 0,
                    },
                    <String, Object?>{'type': 'pointerDown', 'button': 0},
                    <String, Object?>{'type': 'pointerUp', 'button': 0},
                  ],
                },
              ],
            },
          },
          <String, Object?>{
            'command': 'actions',
            'params': <String, Object?>{
              'actions': <Map<String, Object?>>[
                <String, Object?>{
                  'type': 'pointer',
                  'id': 'integration_test_mouse',
                  'parameters': <String, Object?>{'pointerType': 'mouse'},
                  'actions': <Map<String, Object?>>[
                    <String, Object?>{
                      'type': 'pointerMove',
                      'origin': 'viewport',
                      'x': 300,
                      'y': 400,
                      'duration': 0,
                    },
                    <String, Object?>{'type': 'pointerDown', 'button': 2},
                    <String, Object?>{'type': 'pointerUp', 'button': 2},
                  ],
                },
              ],
            },
          },
        ]);
        expect(app.replies, <String>['complete', 'complete']);
      },
    );

    test('subdivides a timed move starting from the last move of an earlier request', () async {
      final app = _FakeApp(
        sequences: const <List<WebDriverPointerAction>>[
          <WebDriverPointerAction>[WebDriverPointerAction.move(0, 0)],
          <WebDriverPointerAction>[
            WebDriverPointerAction.down(),
            WebDriverPointerAction.move(100, 0, duration: Duration(milliseconds: 32)),
            WebDriverPointerAction.up(),
          ],
        ],
      );
      final webDriver = _FakeWebDriver();

      await _runIntegrationDriver(_FakeWebFlutterDriver(app, webDriver));

      expect(webDriver.postRequests, <Map<String, Object?>>[
        _performActionsRequest(<Map<String, Object?>>[_pointerMove(0, 0, 0)]),
        _performActionsRequest(<Map<String, Object?>>[
          <String, Object?>{'type': 'pointerDown', 'button': 0},
          _pointerMove(50, 0, 16),
          _pointerMove(100, 0, 16),
          <String, Object?>{'type': 'pointerUp', 'button': 0},
        ]),
      ]);
      expect(app.replies, <String>['complete', 'complete']);
    });

    test('subdivides a timed move into at most one step per 16 ms and per pixel', () async {
      const cases =
          <
            ({
              String description,
              (double, double) start,
              (double, double) target,
              int milliseconds,
              List<(int, int, int)> steps,
            })
          >[
            (
              description: 'step count capped by distance',
              start: (0, 0),
              target: (3, 0),
              milliseconds: 300,
              steps: <(int, int, int)>[(1, 0, 100), (2, 0, 100), (3, 0, 100)],
            ),
            (
              description: 'zero distance',
              start: (5, 5),
              target: (5, 5),
              milliseconds: 300,
              steps: <(int, int, int)>[(5, 5, 300)],
            ),
            (
              description: 'duration shorter than one step',
              start: (0, 0),
              target: (100, 0),
              milliseconds: 10,
              steps: <(int, int, int)>[(100, 0, 10)],
            ),
            (
              description: 'diagonal move toward the origin',
              start: (100, 100),
              target: (68, 84),
              milliseconds: 32,
              steps: <(int, int, int)>[(84, 92, 16), (68, 84, 16)],
            ),
            (
              description: 'half-pixel step position rounds half away from zero',
              start: (10, 0),
              target: (7, 0),
              milliseconds: 32,
              steps: <(int, int, int)>[(9, 0, 16), (7, 0, 16)],
            ),
            (
              description: 'fractional start and target round before interpolating',
              // Interpolates from (1, 0) to (4, 0), so the midpoint 2.5 rounds
              // to 3, not to the unrounded midpoint 2.1 or a truncated 2.
              start: (0.6, 0),
              target: (3.6, 0),
              milliseconds: 32,
              steps: <(int, int, int)>[(3, 0, 16), (4, 0, 16)],
            ),
          ];

      for (final testCase in cases) {
        final app = _FakeApp(
          sequences: <List<WebDriverPointerAction>>[
            <WebDriverPointerAction>[
              WebDriverPointerAction.move(testCase.start.$1, testCase.start.$2),
              WebDriverPointerAction.move(
                testCase.target.$1,
                testCase.target.$2,
                duration: Duration(milliseconds: testCase.milliseconds),
              ),
            ],
          ],
        );
        final webDriver = _FakeWebDriver();

        await _runIntegrationDriver(_FakeWebFlutterDriver(app, webDriver));

        expect(webDriver.postRequests, <Map<String, Object?>>[
          _performActionsRequest(<Map<String, Object?>>[
            _pointerMove(testCase.start.$1.round(), testCase.start.$2.round(), 0),
            for (final (int x, int y, int duration) in testCase.steps) _pointerMove(x, y, duration),
          ]),
        ], reason: testCase.description);
      }
    });

    test('starts each timed move where the previous subdivided move ended, across pauses, downs, and ups', () async {
      final app = _FakeApp(
        sequences: const <List<WebDriverPointerAction>>[
          <WebDriverPointerAction>[
            WebDriverPointerAction.move(0, 0),
            WebDriverPointerAction.down(),
            WebDriverPointerAction.move(32, 0, duration: Duration(milliseconds: 32)),
            WebDriverPointerAction.pause(Duration(milliseconds: 50)),
            WebDriverPointerAction.up(),
            WebDriverPointerAction.move(32, 32, duration: Duration(milliseconds: 32)),
          ],
        ],
      );
      final webDriver = _FakeWebDriver();

      await _runIntegrationDriver(_FakeWebFlutterDriver(app, webDriver));

      expect(webDriver.postRequests, <Map<String, Object?>>[
        _performActionsRequest(<Map<String, Object?>>[
          _pointerMove(0, 0, 0),
          <String, Object?>{'type': 'pointerDown', 'button': 0},
          _pointerMove(16, 0, 16),
          _pointerMove(32, 0, 16),
          <String, Object?>{'type': 'pause', 'duration': 50},
          <String, Object?>{'type': 'pointerUp', 'button': 0},
          _pointerMove(32, 16, 16),
          _pointerMove(32, 32, 16),
        ]),
      ]);
    });

    test('does not split the first timed move of a later integrationDriver call', () async {
      final firstWebDriver = _FakeWebDriver();
      await _runIntegrationDriver(
        _FakeWebFlutterDriver(
          _FakeApp(
            sequences: const <List<WebDriverPointerAction>>[
              <WebDriverPointerAction>[WebDriverPointerAction.move(0, 0)],
            ],
          ),
          firstWebDriver,
        ),
      );
      final secondWebDriver = _FakeWebDriver();

      await _runIntegrationDriver(
        _FakeWebFlutterDriver(
          _FakeApp(
            sequences: const <List<WebDriverPointerAction>>[
              <WebDriverPointerAction>[
                WebDriverPointerAction.move(100, 0, duration: Duration(milliseconds: 32)),
              ],
            ],
          ),
          secondWebDriver,
        ),
      );

      expect(firstWebDriver.postRequests, <Map<String, Object?>>[
        _performActionsRequest(<Map<String, Object?>>[_pointerMove(0, 0, 0)]),
      ]);
      expect(secondWebDriver.postRequests, <Map<String, Object?>>[
        _performActionsRequest(<Map<String, Object?>>[_pointerMove(100, 0, 32)]),
      ]);
    });

    test('fails in the app and throws StateError if the driver is not a WebFlutterDriver', () async {
      final app = _FakeApp(
        sequences: const <List<WebDriverPointerAction>>[
          <WebDriverPointerAction>[WebDriverPointerAction.move(10, 20)],
        ],
      );

      await expectLater(
        integrationDriver(driver: _FakeFlutterDriver(app), responseDataCallback: null),
        throwsA(
          isStateError.having(
            (StateError error) => error.message,
            'message',
            'webDriverPointerActions requires a WebFlutterDriver, but received _FakeFlutterDriver',
          ),
        ),
      );
      expect(app.replies, <String>['error']);
    });

    test('throws StateError if the driver is not a WebFlutterDriver even when the app disconnected', () async {
      final app = _FakeApp(
        sequences: const <List<WebDriverPointerAction>>[
          <WebDriverPointerAction>[WebDriverPointerAction.move(10, 20)],
        ],
        disconnectsOnError: true,
      );

      await expectLater(
        integrationDriver(driver: _FakeFlutterDriver(app), responseDataCallback: null),
        throwsA(
          isStateError.having(
            (StateError error) => error.message,
            'message',
            'webDriverPointerActions requires a WebFlutterDriver, but received _FakeFlutterDriver',
          ),
        ),
      );
    });

    test(
      'releases actions, fails the command in the app, and rethrows if WebDriver fails',
      () async {
        final eventLog = <String>[];
        final app = _FakeApp(
          sequences: const <List<WebDriverPointerAction>>[
            <WebDriverPointerAction>[
              WebDriverPointerAction.move(10, 20),
              WebDriverPointerAction.down(),
              WebDriverPointerAction.move(9999, 9999),
            ],
          ],
          eventLog: eventLog,
        );
        const error = MoveTargetOutOfBoundsException(400, 'move target out of bounds');
        final webDriver = _FakeWebDriver(postError: error, eventLog: eventLog);

        await expectLater(
          integrationDriver(
            driver: _FakeWebFlutterDriver(app, webDriver),
            responseDataCallback: null,
          ),
          throwsA(same(error)),
        );
        expect(webDriver.deleteRequests, <String>['actions']);
        expect(app.replies, <String>['error']);
        expect(eventLog, <String>['post:actions', 'delete:actions', 'reply:error']);
      },
    );

    test(
      'rethrows the original WebDriver error even if releasing actions or notifying the app throws',
      () async {
        final app = _FakeApp(
          sequences: const <List<WebDriverPointerAction>>[
            <WebDriverPointerAction>[WebDriverPointerAction.move(10, 20)],
          ],
          disconnectsOnError: true,
        );
        const error = MoveTargetOutOfBoundsException(400, 'move target out of bounds');
        final webDriver = _FakeWebDriver(
          postError: error,
          deleteError: const SocketException('webdriver session closed'),
        );

        await expectLater(
          integrationDriver(
            driver: _FakeWebFlutterDriver(app, webDriver),
            responseDataCallback: null,
          ),
          throwsA(same(error)),
        );
        expect(webDriver.deleteRequests, <String>['actions']);
      },
    );

    test('releases actions, fails the command in the app, and throws FormatException without posting when action JSON is malformed', () async {
      final app = _FakeApp(
        rawSequences: const <List<Map<String, Object?>>>[
          <Map<String, Object?>>[
            <String, Object?>{'type': 'pointerMove', 'x': 'bad', 'y': 20, 'duration': 0},
          ],
        ],
      );
      final webDriver = _FakeWebDriver();

      await expectLater(
        integrationDriver(
          driver: _FakeWebFlutterDriver(app, webDriver),
          responseDataCallback: null,
        ),
        throwsFormatException,
      );
      expect(webDriver.postRequests, isEmpty);
      expect(webDriver.deleteRequests, <String>['actions']);
      expect(app.replies, <String>['error']);
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

/// The W3C perform-actions request [integrationDriver] posts for a pointer
/// action sequence that it serialized to [actions].
Map<String, Object?> _performActionsRequest(List<Map<String, Object?>> actions) {
  return <String, Object?>{
    'command': 'actions',
    'params': <String, Object?>{
      'actions': <Map<String, Object?>>[
        <String, Object?>{
          'type': 'pointer',
          'id': 'integration_test_mouse',
          'parameters': <String, Object?>{'pointerType': 'mouse'},
          'actions': actions,
        },
      ],
    },
  };
}

/// A serialized W3C `pointerMove` action to viewport position ([x], [y]).
Map<String, Object?> _pointerMove(int x, int y, int duration) {
  return <String, Object?>{
    'type': 'pointerMove',
    'origin': 'viewport',
    'x': x,
    'y': y,
    'duration': duration,
  };
}

/// Plays the in-browser test, which asks [integrationDriver] for pointer
/// action sequences.
///
/// The host and the app talk through [FlutterDriver.requestData]:
///
///  1. The host sends `pending` to ask for the app's next command. The app
///     replies with a `pointerActions` command for the next sequence it was
///     created with, or, once all sequences are done, with a `noop` command.
///  2. After performing the sequence, the host sends `complete`, or `error` if
///     it could not perform it. The app records this in [replies], which is
///     what makes the app's `webDriverPointerActions` call complete or fail,
///     and replies `ack`.
///  3. After the `noop` command, the host sends `null` to ask for the test
///     results, and the app replies that all tests passed.
class _FakeApp {
  _FakeApp({
    List<List<WebDriverPointerAction>> sequences = const <List<WebDriverPointerAction>>[],
    List<List<Map<String, Object?>>>? rawSequences,
    this.disconnectsOnError = false,
    this.eventLog,
  }) : _commands = Queue<Map<String, dynamic>>.of(
         rawSequences != null
             ? <Map<String, dynamic>>[
                 for (final List<Map<String, Object?>> raw in rawSequences)
                   <String, dynamic>{'actions': raw},
               ]
             : <Map<String, dynamic>>[
                 for (final List<WebDriverPointerAction> sequence in sequences)
                   WebDriverCommand.pointerActions(sequence).values,
               ],
       );

  final Queue<Map<String, dynamic>> _commands;

  /// Whether the app disconnects instead of receiving an `error` reply.
  final bool disconnectsOnError;

  /// Optional shared event log to verify ordering across host operations.
  final List<String>? eventLog;

  /// The host's reply to each command, in order.
  final List<String> replies = <String>[];

  Future<String> respondTo(String? message) async {
    switch (message) {
      case 'pending':
        if (_commands.isEmpty) {
          return _webDriverCommand(WebDriverCommandType.noop);
        }
        return _webDriverCommand(WebDriverCommandType.pointerActions, _commands.removeFirst());
      case 'complete' || 'error':
        eventLog?.add('reply:$message');
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

/// A [WebFlutterDriver] connected to [app], backed by [webDriver].
class _FakeWebFlutterDriver extends _FakeFlutterDriver implements WebFlutterDriver {
  _FakeWebFlutterDriver(super.app, this.webDriver);

  @override
  final WebDriver webDriver;
}

/// A WebDriver session that records `postRequest` and `deleteRequest` calls.
class _FakeWebDriver extends Fake implements WebDriver {
  _FakeWebDriver({this.postError, this.deleteError, this.eventLog});

  final Exception? postError;
  final Exception? deleteError;
  final List<String>? eventLog;

  final List<Map<String, Object?>> postRequests = <Map<String, Object?>>[];
  final List<String> deleteRequests = <String>[];

  @override
  Future<dynamic> postRequest(String command, [Object? params]) async {
    eventLog?.add('post:$command');
    if (postError != null) {
      throw postError!;
    }
    postRequests.add(<String, Object?>{'command': command, 'params': params});
    return null;
  }

  @override
  Future<dynamic> deleteRequest(String command) async {
    eventLog?.add('delete:$command');
    deleteRequests.add(command);
    if (deleteError != null) {
      throw deleteError!;
    }
    return null;
  }
}
