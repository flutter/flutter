// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter_driver/flutter_driver.dart';
///
/// @docImport 'integration_test.dart';
/// @docImport 'integration_test_driver_extended.dart';
library;

import 'dart:async';
import 'dart:convert';

/// A callback to use with [integrationDriver].
///
/// The callback receives the name of screenshot passed to `binding.takeScreenshot(<name>)`,
/// a PNG byte buffer representing the screenshot, and an optional `Map` of arguments.
///
/// The callback returns `true` if the test passes or `false` otherwise.
///
/// You can use this callback to store the bytes locally in a file or upload them to a service
/// that compares the image against a gold or baseline version.
///
/// The optional `Map` of arguments can be passed from the
/// `binding.takeScreenshot(<name>, <args>)` callsite in the integration test,
/// and then the arguments can be used in the `onScreenshot` handler that is defined by
/// the Flutter driver. This `Map` should only contain values that can be serialized
/// to JSON.
///
/// Since the function is executed on the host driving the test, you can access any environment
/// variable from it.
typedef ScreenshotCallback = Future<bool> Function(
  String name,
  List<int> image, [
  Map<String, Object?>? args,
]);

/// Classes shared between `integration_test.dart` and `flutter drive` based
/// adaptor (ex: `integration_test_driver.dart`).

/// An object sent from integration_test back to the Flutter Driver in response to
/// `request_data` command.
class Response {
  /// Constructor to use for positive response.
  Response.allTestsPassed({this.data}) : _allTestsPassed = true, _failureDetails = null;

  /// Constructor for failure response.
  Response.someTestsFailed(this._failureDetails, {this.data}) : _allTestsPassed = false;

  /// Constructor for failure response.
  Response.toolException({String? ex})
    : _allTestsPassed = false,
      _failureDetails = <Failure>[Failure('ToolException', ex)];

  /// Constructor for web driver commands response.
  Response.webDriverCommand({this.data}) : _allTestsPassed = false, _failureDetails = null;

  final List<Failure>? _failureDetails;

  final bool _allTestsPassed;

  /// The extra information to be added along side the test result.
  Map<String, dynamic>? data;

  /// Whether the test ran successfully or not.
  bool get allTestsPassed => _allTestsPassed;

  /// If the result are failures get the formatted details.
  String get formattedFailureDetails => _allTestsPassed ? '' : formatFailures(_failureDetails!);

  /// Failure details as a list.
  List<Failure>? get failureDetails => _failureDetails;

  /// Serializes this message to a JSON map.
  String toJson() => json.encode(<String, dynamic>{
    'result': allTestsPassed.toString(),
    'failureDetails': _failureDetailsAsString(),
    'data': ?data,
  });

  /// Deserializes the result from JSON.
  static Response fromJson(String source) {
    final responseJson = json.decode(source) as Map<String, dynamic>;
    if ((responseJson['result'] as String?) == 'true') {
      return Response.allTestsPassed(data: responseJson['data'] as Map<String, dynamic>?);
    } else {
      return Response.someTestsFailed(
        _failureDetailsFromJson(responseJson['failureDetails'] as List<dynamic>),
        data: responseJson['data'] as Map<String, dynamic>?,
      );
    }
  }

  /// Method for formatting the test failures' details.
  String formatFailures(List<Failure> failureDetails) {
    if (failureDetails.isEmpty) {
      return '';
    }

    final sb = StringBuffer();
    var failureCount = 1;
    for (final failure in failureDetails) {
      sb.writeln('Failure in method: ${failure.methodName}');
      sb.writeln(failure.details);
      sb.writeln('end of failure $failureCount\n\n');
      failureCount++;
    }
    return sb.toString();
  }

  /// Create a list of Strings from [_failureDetails].
  List<String> _failureDetailsAsString() {
    return <String>[
      if (_failureDetails != null)
        for (final Failure failure in _failureDetails) failure.toJson(),
    ];
  }

  /// Creates a [Failure] list using a json response.
  static List<Failure> _failureDetailsFromJson(List<dynamic> list) {
    return list.map((dynamic s) {
      return Failure.fromJsonString(s as String);
    }).toList();
  }
}

/// Representing a failure includes the method name and the failure details.
class Failure {
  /// Constructor requiring all fields during initialization.
  Failure(this.methodName, this.details);

  /// The name of the test method which failed.
  final String methodName;

  /// The details of the failure such as stack trace.
  final String? details;

  /// Serializes the object to JSON.
  String toJson() {
    return json.encode(<String, String?>{'methodName': methodName, 'details': details});
  }

  @override
  String toString() => toJson();

  /// Decode a JSON string to create a Failure object.
  static Failure fromJsonString(String jsonString) {
    final failure = json.decode(jsonString) as Map<String, dynamic>;
    return Failure(failure['methodName'] as String, failure['details'] as String?);
  }
}

/// Message used to communicate between app side tests and driver tests.
///
/// Not all `integration_tests` use this message. They are only used when app
/// side tests are sending [WebDriverCommand]s to the driver side.
///
/// These messages are used for the handshake since they carry information on
/// the driver side test such as: status pending or tests failed.
class DriverTestMessage {
  /// When tests are failed on the driver side.
  DriverTestMessage.error() : _isSuccess = false, _isPending = false;

  /// When driver side is waiting on [WebDriverCommand]s to be sent from the
  /// app side.
  DriverTestMessage.pending() : _isSuccess = false, _isPending = true;

  /// When driver side successfully completed executing the [WebDriverCommand].
  DriverTestMessage.complete() : _isSuccess = true, _isPending = false;

  final bool _isSuccess;
  final bool _isPending;

  // /// Status of this message.
  // ///
  // /// The status will be use to notify `integration_test` of driver side's
  // /// state.
  // String get status => _status;

  /// Has the command completed successfully by the driver.
  bool get isSuccess => _isSuccess;

  /// Is the driver waiting for a command.
  bool get isPending => _isPending;

  /// Depending on the values of [isPending] and [isSuccess], returns a string
  /// to represent the [DriverTestMessage].
  ///
  /// Used as an alternative method to converting the object to json since
  /// [RequestData] is only accepting string as `message`.
  @override
  String toString() {
    if (isPending) {
      return 'pending';
    } else if (isSuccess) {
      return 'complete';
    } else {
      return 'error';
    }
  }

  /// Return a DriverTestMessage depending on `status`.
  static DriverTestMessage fromString(String status) {
    return switch (status) {
      'error' => DriverTestMessage.error(),
      'pending' => DriverTestMessage.pending(),
      'complete' => DriverTestMessage.complete(),
      _ => throw StateError('This type of status does not exist: $status'),
    };
  }
}

/// A mouse button for [WebDriverPointerAction.down] and
/// [WebDriverPointerAction.up].
///
/// See: https://www.w3.org/TR/webdriver/#dfn-process-a-pointer-up-or-pointer-down-action
enum WebDriverMouseButton {
  /// The primary mouse button (typically the left button), W3C button `0`.
  primary(0),

  /// The middle mouse button (typically the wheel button), W3C button `1`.
  middle(1),

  /// The secondary mouse button (typically the right button), W3C button `2`.
  secondary(2);

  const WebDriverMouseButton(this.w3cButton);

  /// The W3C WebDriver button index (`0`, `1`, or `2`).
  ///
  /// Note that these are 0-based W3C WebDriver button indexes, not Flutter's
  /// `kPrimaryButton`-style bit flags (where `1` is the primary button, which
  /// WebDriver interprets as the [middle] button).
  final int w3cButton;
}

/// A single step in a WebDriver pointer action sequence.
///
/// Pass a list of [WebDriverPointerAction]s to
/// [IntegrationTestWidgetsFlutterBinding.webDriverPointerActions] to perform a
/// sequence of real browser mouse actions (such as hovers, clicks, or drags)
/// through WebDriver.
///
/// Create actions with the [WebDriverPointerAction.move],
/// [WebDriverPointerAction.down], [WebDriverPointerAction.up], and
/// [WebDriverPointerAction.pause] constructors.
///
/// See: https://www.w3.org/TR/webdriver/#actions
sealed class WebDriverPointerAction {
  /// Abstract const constructor. This constructor enables subclasses to
  /// provide const constructors so that they can be used in const
  /// expressions.
  const WebDriverPointerAction();

  /// Creates a pointer action that moves the mouse to ([x], [y]).
  ///
  /// See [WebDriverPointerMove.new].
  const factory WebDriverPointerAction.move(double x, double y, {Duration duration}) =
      WebDriverPointerMove;

  /// Creates a pointer action that presses [button], which defaults to
  /// [WebDriverMouseButton.primary].
  ///
  /// See [WebDriverPointerDown.new].
  const factory WebDriverPointerAction.down({WebDriverMouseButton button}) = WebDriverPointerDown;

  /// Creates a pointer action that releases [button], which defaults to
  /// [WebDriverMouseButton.primary].
  ///
  /// See [WebDriverPointerUp.new].
  const factory WebDriverPointerAction.up({WebDriverMouseButton button}) = WebDriverPointerUp;

  /// Creates a pointer action that waits for [duration].
  ///
  /// See [WebDriverPointerPause.new].
  const factory WebDriverPointerAction.pause(Duration duration) = WebDriverPointerPause;

  /// Deserializes a [WebDriverPointerAction] from the JSON map produced by
  /// [toJson].
  ///
  /// Throws a [FormatException] if [json] has an unknown `type` or is missing
  /// or has mistyped fields for that type.
  factory WebDriverPointerAction.fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'pointerMove' => switch (json) {
        {'x': final num x, 'y': final num y, 'duration': final num duration} =>
          WebDriverPointerMove(
            x.toDouble(),
            y.toDouble(),
            duration: Duration(milliseconds: duration.toInt()),
          ),
        _ => throw FormatException('Invalid pointerMove WebDriverPointerAction JSON: $json'),
      },
      'pointerDown' => WebDriverPointerDown(button: _buttonFromJson(json['button'])),
      'pointerUp' => WebDriverPointerUp(button: _buttonFromJson(json['button'])),
      'pause' => switch (json) {
        {'duration': final num duration} => WebDriverPointerPause(
          Duration(milliseconds: duration.toInt()),
        ),
        _ => throw FormatException('Invalid pause WebDriverPointerAction JSON: $json'),
      },
      _ => throw FormatException('Unknown WebDriverPointerAction type in JSON: $json'),
    };
  }

  static WebDriverMouseButton _buttonFromJson(Object? value) {
    return switch (value) {
      0 => WebDriverMouseButton.primary,
      1 => WebDriverMouseButton.middle,
      2 => WebDriverMouseButton.secondary,
      _ => throw FormatException('Invalid WebDriverMouseButton value: $value'),
    };
  }

  /// Serializes this action to a JSON-compatible map.
  Map<String, Object?> toJson();
}

/// A [WebDriverPointerAction] that moves the mouse to ([x], [y]).
///
/// Usually created with [WebDriverPointerAction.move].
final class WebDriverPointerMove extends WebDriverPointerAction {
  /// Creates a pointer action that moves the mouse to ([x], [y]).
  ///
  /// With a non-zero [duration], the mouse moves to ([x], [y]) over
  /// [duration], and the browser dispatches intermediate `pointermove` events
  /// along the way. [duration] is truncated to whole milliseconds. See
  /// [integrationDriver] for how the host driver performs timed moves.
  ///
  /// WebDriver positions the mouse at whole CSS pixels, so the host driver
  /// rounds the viewport position to the nearest pixel.
  ///
  /// {@template flutter.integration_test.WebDriverPointerAction.coordinates}
  /// When passed to
  /// [IntegrationTestWidgetsFlutterBinding.webDriverPointerActions], move
  /// positions are logical positions in the target `FlutterView`. In
  /// [WebDriverCommand.pointerActions], [CallbackManager.pointerActions], and
  /// on the host driver, they are in CSS pixels relative to the top-left
  /// corner of the browser viewport.
  /// {@endtemplate}
  const WebDriverPointerMove(this.x, this.y, {this.duration = Duration.zero});

  /// Target horizontal coordinate.
  ///
  /// {@macro flutter.integration_test.WebDriverPointerAction.coordinates}
  final double x;

  /// Target vertical coordinate.
  ///
  /// {@macro flutter.integration_test.WebDriverPointerAction.coordinates}
  final double y;

  /// How long the move to ([x], [y]) takes.
  final Duration duration;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': 'pointerMove',
      'x': x,
      'y': y,
      'duration': duration.inMilliseconds,
    };
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  bool operator ==(Object other) {
    return other is WebDriverPointerMove &&
        other.x == x &&
        other.y == y &&
        other.duration == duration;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  int get hashCode => Object.hash(WebDriverPointerMove, x, y, duration);

  @override
  String toString() => 'WebDriverPointerAction.move($x, $y, duration: $duration)';
}

/// A [WebDriverPointerAction] that presses a mouse [button].
///
/// Usually created with [WebDriverPointerAction.down].
final class WebDriverPointerDown extends WebDriverPointerAction {
  /// Creates a pointer action that presses [button].
  const WebDriverPointerDown({this.button = WebDriverMouseButton.primary});

  /// The mouse button to press.
  final WebDriverMouseButton button;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'type': 'pointerDown', 'button': button.w3cButton};
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  bool operator ==(Object other) {
    return other is WebDriverPointerDown && other.button == button;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  int get hashCode => Object.hash(WebDriverPointerDown, button);

  @override
  String toString() => 'WebDriverPointerAction.down(button: $button)';
}

/// A [WebDriverPointerAction] that releases a mouse [button].
///
/// Usually created with [WebDriverPointerAction.up].
final class WebDriverPointerUp extends WebDriverPointerAction {
  /// Creates a pointer action that releases [button].
  const WebDriverPointerUp({this.button = WebDriverMouseButton.primary});

  /// The mouse button to release.
  final WebDriverMouseButton button;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'type': 'pointerUp', 'button': button.w3cButton};
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  bool operator ==(Object other) {
    return other is WebDriverPointerUp && other.button == button;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  int get hashCode => Object.hash(WebDriverPointerUp, button);

  @override
  String toString() => 'WebDriverPointerAction.up(button: $button)';
}

/// A [WebDriverPointerAction] that waits for [duration] before the next
/// action.
///
/// Usually created with [WebDriverPointerAction.pause].
final class WebDriverPointerPause extends WebDriverPointerAction {
  /// Creates a pointer action that waits for [duration].
  ///
  /// [duration] is truncated to whole milliseconds.
  const WebDriverPointerPause(this.duration);

  /// How long to wait.
  final Duration duration;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'type': 'pause', 'duration': duration.inMilliseconds};
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  bool operator ==(Object other) {
    return other is WebDriverPointerPause && other.duration == duration;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, common.dart stays dependency-free (no package:meta).
  int get hashCode => Object.hash(WebDriverPointerPause, duration);

  @override
  String toString() => 'WebDriverPointerAction.pause($duration)';
}

/// Types of different WebDriver commands that can be used in web integration
/// tests.
///
/// These commands are either commands that WebDriver can execute or used
/// for the communication between `integration_test` and the driver test.
enum WebDriverCommandType {
  /// Acknowledgement for the previously sent message.
  ack,

  /// No further WebDriver commands is requested by the app-side tests.
  noop,

  /// Asking WebDriver to take a screenshot of the Web page.
  screenshot,

  /// Asking WebDriver to perform a sequence of real pointer actions in the
  /// browser viewport.
  ///
  /// See [IntegrationTestWidgetsFlutterBinding.webDriverPointerActions].
  pointerActions,
}

/// Command for WebDriver to execute.
///
/// Only works on Web when tests are run via `flutter driver` command.
///
/// See: https://www.w3.org/TR/webdriver/
class WebDriverCommand {
  /// Constructor for [WebDriverCommandType.noop] command.
  WebDriverCommand.noop() : type = WebDriverCommandType.noop, values = <String, dynamic>{};

  /// Constructor for [WebDriverCommandType.noop] screenshot.
  WebDriverCommand.screenshot(String screenshotName, [Map<String, Object?>? args])
    : type = WebDriverCommandType.screenshot,
      values = <String, dynamic>{'screenshot_name': screenshotName, 'args': ?args};

  /// Constructor for [WebDriverCommandType.pointerActions] command.
  ///
  /// Move coordinates in [actions] are in CSS pixels relative to the top-left
  /// corner of the browser viewport.
  WebDriverCommand.pointerActions(List<WebDriverPointerAction> actions)
    : type = WebDriverCommandType.pointerActions,
      values = <String, dynamic>{
        'actions': <Map<String, Object?>>[
          for (final WebDriverPointerAction action in actions) action.toJson(),
        ],
      };

  /// Type of the [WebDriverCommand].
  ///
  /// The commands that trigger a WebDriver API are `screenshot` and
  /// `pointerActions`.
  ///
  /// There are also `ack` and `noop` commands defined to manage the handshake
  /// during the communication.
  final WebDriverCommandType type;

  /// Used for adding extra values to the commands such as file name for
  /// `screenshot` or the serialized action list for `pointerActions`.
  final Map<String, dynamic> values;

  /// Util method for converting [WebDriverCommandType] to a map entry.
  ///
  /// Used for converting messages to json format.
  static Map<String, dynamic> typeToMap(WebDriverCommandType type) => <String, dynamic>{
    'web_driver_command': '$type',
  };
}

/// Template methods each class that responses the driver side inputs must
/// implement.
///
/// Depending on the platform the communication between `integration_tests` and
/// the `driver_tests` can be different.
abstract class CallbackManager {
  /// The callback function to response the driver side input.
  Future<Map<String, dynamic>> callback(
    Map<String, String> params,
    IntegrationTestResults testRunner,
  );

  /// Takes a screenshot of the application.
  /// Returns the data that is sent back to the host.
  Future<Map<String, dynamic>> takeScreenshot(String screenshot, [Map<String, Object?>? args]);

  /// Android only. Converts the Flutter surface to an image view.
  Future<void> convertFlutterSurfaceToImage();

  /// Web only. Asks the driver to perform a sequence of real pointer [actions]
  /// in the browser viewport.
  ///
  /// Move coordinates in [actions] are in CSS pixels relative to the top-left
  /// corner of the browser viewport.
  ///
  /// Completes once the driver has performed the actions, and completes with an
  /// error if the driver failed to perform them.
  ///
  /// The default implementation completes with an [UnsupportedError].
  Future<void> pointerActions(List<WebDriverPointerAction> actions) async {
    throw UnsupportedError('pointerActions is not supported by $runtimeType');
  }

  /// Cleanup and completers or locks used during the communication.
  void cleanup();
}

/// Interface that surfaces test results of integration tests.
///
/// Implemented by [IntegrationTestWidgetsFlutterBinding]s.
///
/// Any class which needs to access the test results but do not want to create
/// a cyclic dependency [IntegrationTestWidgetsFlutterBinding]s can use this
/// interface. Example [CallbackManager].
abstract class IntegrationTestResults {
  /// Stores failure details.
  ///
  /// Failed test method's names used as key.
  List<Failure> get failureMethodsDetails;

  /// The extra data for the reported result.
  Map<String, dynamic>? get reportData;

  /// Whether all the test methods completed successfully.
  ///
  /// Completes when the tests have finished. The boolean value will be true if
  /// all tests have passed, and false otherwise.
  Completer<bool> get allTestsPassed;
}
