// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a CLI library; we use prints as part of the interface.
// ignore_for_file: avoid_print

/// @docImport 'integration_test.dart';
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

export 'package:flutter_driver/flutter_driver.dart' show testOutputsDirectory;

/// The callback type to handle [Response.data] after the test
/// succeeds.
typedef ResponseDataCallback = FutureOr<void> Function(Map<String, dynamic>?);

/// Writes a json-serializable data to
/// [testOutputsDirectory]/`testOutputFilename.json`.
///
/// This is the default `responseDataCallback` in [integrationDriver].
Future<void> writeResponseData(
  Map<String, dynamic>? data, {
  String testOutputFilename = 'integration_response_data',
  String? destinationDirectory,
}) async {
  destinationDirectory ??= testOutputsDirectory;
  await fs.directory(destinationDirectory).create(recursive: true);
  final File file = fs.file(path.join(destinationDirectory, '$testOutputFilename.json'));
  final String resultString = _encodeJson(data, true);
  await file.writeAsString(resultString);
}

/// Adaptor to run an integration test using `flutter drive`.
///
/// To an integration test `<test_name>.dart` using `flutter drive`, put a file named
/// `<test_name>_test.dart` in the app's `test_driver` directory:
///
/// ```dart
/// import 'dart:async';
///
/// import 'package:flutter_driver/flutter_driver.dart';
/// import 'package:integration_test/integration_test_driver_extended.dart';
///
/// Future<void> main() async {
///   final FlutterDriver driver = await FlutterDriver.connect();
///   await integrationDriver(
///     driver: driver,
///     onScreenshot: (String name, List<int> image, [Map<String, Object?>? args]) async {
///       return true;
///     },
///   );
/// }
/// ```
///
/// ## Parameters:
///
/// `driver` A custom driver. Defaults to `FlutterDriver.connect()`.
///
/// `onScreenshot` can be used to process the screenshots taken during the test.
/// An example could be that this callback compares the byte array against a baseline image,
/// and it returns `true` if both images are equal.
///
/// As a result, returning `false` from `onScreenshot` will make the test fail.
///
/// The in-browser test can also ask the driver to perform real WebDriver
/// pointer input by calling
/// [IntegrationTestWidgetsFlutterBinding.webDriverPointerActions] or
/// [IntegrationTestWidgetsFlutterBinding.webDriverClick]. Pointer actions
/// require `driver` to be a [WebFlutterDriver]. If it is not, the call fails in
/// the browser and this function throws a [StateError]. If WebDriver fails to
/// perform the actions, pressed mouse buttons are released, the call fails in
/// the browser, and the WebDriver exception is rethrown.
///
/// `responseDataCallback` is the handler for processing [Response.data].
/// The default value is `writeResponseData`.
///
/// `writeResponseOnFailure` determines whether the `responseDataCallback`
/// function will be called to process the [Response.data] when a test fails.
/// The default value is `false`.
Future<void> integrationDriver({
  FlutterDriver? driver,
  ScreenshotCallback? onScreenshot,
  ResponseDataCallback? responseDataCallback = writeResponseData,
  bool writeResponseOnFailure = false,
}) async {
  driver ??= await FlutterDriver.connect();
  // Test states that it's waiting on web driver commands.
  // [DriverTestMessage] is converted to string since json format causes an
  // error if it's used as a message for requestData.
  String jsonResponse = await driver.requestData(DriverTestMessage.pending().toString());

  final onScreenshotResults = <String, bool>{};
  final mouse = _W3cMouse();

  Response response = Response.fromJson(jsonResponse);

  // Until `integration_test` returns a [WebDriverCommandType.noop], keep
  // executing WebDriver commands.
  while (response.data != null &&
      response.data!['web_driver_command'] != null &&
      response.data!['web_driver_command'] != '${WebDriverCommandType.noop}') {
    final webDriverCommand = response.data!['web_driver_command'] as String?;
    if (webDriverCommand == '${WebDriverCommandType.screenshot}') {
      assert(onScreenshot != null, 'screenshot command requires an onScreenshot callback');
      // Use `driver.screenshot()` method to get a screenshot of the web page.
      final List<int> screenshotImage = await driver.screenshot();
      final screenshotName = response.data!['screenshot_name']! as String;
      final Map<String, Object?>? args = (response.data!['args'] as Map<String, Object?>?)
          ?.cast<String, Object?>();

      final bool screenshotSuccess = await onScreenshot!(screenshotName, screenshotImage, args);
      onScreenshotResults[screenshotName] = screenshotSuccess;
      if (screenshotSuccess) {
        jsonResponse = await driver.requestData(DriverTestMessage.complete().toString());
      } else {
        jsonResponse = await driver.requestData(DriverTestMessage.error().toString());
      }

      response = Response.fromJson(jsonResponse);
    } else if (webDriverCommand == '${WebDriverCommandType.pointerActions}') {
      if (driver is! WebFlutterDriver) {
        // Fail the in-browser `webDriverPointerActions` call instead of leaving
        // it waiting for a reply.
        try {
          await driver.requestData(DriverTestMessage.error().toString());
        } catch (_) {
          // Report the StateError below even if the app disconnected.
        }
        throw StateError(
          'webDriverPointerActions requires a WebFlutterDriver, but received ${driver.runtimeType}',
        );
      }
      try {
        final actions = <WebDriverPointerAction>[
          for (final Object? json in response.data!['actions']! as List<Object?>)
            WebDriverPointerAction.fromJson(
              (json! as Map<Object?, Object?>).cast<String, Object?>(),
            ),
        ];
        await driver.webDriver.postRequest('actions', mouse.actionsRequest(actions));
      } catch (_) {
        try {
          await driver.webDriver.deleteRequest('actions');
        } catch (_) {
          // Preserve the original WebDriver exception.
        }
        try {
          await driver.requestData(DriverTestMessage.error().toString());
        } catch (_) {
          // Preserve the original WebDriver exception if the app disconnected.
        }
        rethrow;
      }
      jsonResponse = await driver.requestData(DriverTestMessage.complete().toString());
      response = Response.fromJson(jsonResponse);
    } else if (webDriverCommand == '${WebDriverCommandType.ack}') {
      // Previous command completed ask for a new one.
      jsonResponse = await driver.requestData(DriverTestMessage.pending().toString());

      response = Response.fromJson(jsonResponse);
    } else {
      break;
    }
  }

  // If No-op command is sent, ask for the result of all tests.
  if (response.data != null &&
      response.data!['web_driver_command'] != null &&
      response.data!['web_driver_command'] == '${WebDriverCommandType.noop}') {
    jsonResponse = await driver.requestData(null);

    response = Response.fromJson(jsonResponse);
    print('result $jsonResponse');
  }

  if (response.data != null && response.data!['screenshots'] != null && onScreenshot != null) {
    final screenshots = response.data!['screenshots'] as List<dynamic>;
    final failures = <String>[];
    for (final dynamic screenshot in screenshots) {
      final data = screenshot as Map<String, dynamic>;
      final screenshotBytes = data['bytes'] as List<dynamic>;
      final screenshotName = data['screenshotName'] as String;

      var ok = false;
      try {
        ok =
            onScreenshotResults[screenshotName] ??
            await onScreenshot(screenshotName, screenshotBytes.cast<int>());
      } catch (exception) {
        throw StateError(
          'Screenshot failure:\n'
          'onScreenshot("$screenshotName", <bytes>) threw an exception: $exception',
        );
      }
      if (!ok) {
        failures.add(screenshotName);
      }
    }
    if (failures.isNotEmpty) {
      throw StateError('The following screenshot tests failed: ${failures.join(', ')}');
    }
  }

  await driver.close();

  if (response.allTestsPassed) {
    print('All tests passed.');
    if (responseDataCallback != null) {
      await responseDataCallback(response.data);
    }
    exit(0);
  } else {
    print('Failure Details:\n${response.formattedFailureDetails}');
    if (responseDataCallback != null && writeResponseOnFailure) {
      await responseDataCallback(response.data);
    }
    exit(1);
  }
}

/// About one frame at 60 Hz, the time between interpolated mouse moves.
const int _w3cMouseMoveStepMilliseconds = 16;

/// Builds W3C perform-actions requests for the WebDriver mouse, remembering
/// where the previous request left the mouse.
///
/// ChromeDriver performs a W3C `pointerMove` with a non-zero duration by
/// dispatching a single `mousemove` at the end of the move instead of moving
/// the mouse gradually as the W3C spec describes. To make every browser see
/// intermediate events, each timed move is split into straight-line steps of
/// about [_w3cMouseMoveStepMilliseconds] each, starting from the last position
/// the mouse was moved to. The first move, whose start position is unknown, is
/// not split.
class _W3cMouse {
  /// The rounded viewport position of the last move, or null before any move.
  (int, int)? _position;

  /// Returns the request body that performs [actions].
  Map<String, Object?> actionsRequest(List<WebDriverPointerAction> actions) {
    return <String, Object?>{
      'actions': <Map<String, Object?>>[
        <String, Object?>{
          'type': 'pointer',
          'id': 'integration_test_mouse',
          'parameters': <String, Object?>{'pointerType': 'mouse'},
          'actions': <Map<String, Object?>>[
            for (final WebDriverPointerAction action in actions)
              if (action.type == WebDriverPointerActionType.move)
                ..._move(action)
              else
                action.toJson(),
          ],
        },
      ],
    };
  }

  List<Map<String, Object?>> _move(WebDriverPointerAction action) {
    final (int, int)? start = _position;
    final (int, int) target = (action.x!.round(), action.y!.round());
    final int milliseconds = action.duration!.inMilliseconds;
    _position = target;
    if (milliseconds == 0 || start == null) {
      return <Map<String, Object?>>[_pointerMove(target.$1, target.$2, milliseconds)];
    }
    final int dx = target.$1 - start.$1;
    final int dy = target.$2 - start.$2;
    final int steps = math.max(
      1,
      math.min((milliseconds / _w3cMouseMoveStepMilliseconds).ceil(), math.max(dx.abs(), dy.abs())),
    );
    return <Map<String, Object?>>[
      for (int i = 1; i <= steps; i++)
        _pointerMove(
          (start.$1 + dx * i / steps).round(),
          (start.$2 + dy * i / steps).round(),
          milliseconds * i ~/ steps - milliseconds * (i - 1) ~/ steps,
        ),
    ];
  }

  static Map<String, Object?> _pointerMove(int x, int y, int milliseconds) {
    return <String, Object?>{
      'type': 'pointerMove',
      'origin': 'viewport',
      'x': x,
      'y': y,
      'duration': milliseconds,
    };
  }
}

const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

String _encodeJson(Map<String, dynamic>? jsonObject, bool pretty) {
  return pretty ? _prettyEncoder.convert(jsonObject) : json.encode(jsonObject);
}
