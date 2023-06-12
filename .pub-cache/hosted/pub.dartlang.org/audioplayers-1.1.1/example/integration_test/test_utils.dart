import 'dart:async';
import 'package:audioplayers_example/components/tgl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterUtils on WidgetTester {
  // Add [stackTrace] to work around https://github.com/flutter/flutter/issues/89138
  Future<void> waitFor(
    Future<void> Function() testExpectation, {
    Duration? timeout = const Duration(seconds: 15),
    Duration? pollInterval = const Duration(milliseconds: 500),
    String? stackTrace,
  }) async =>
      _waitUntil(
        (setFailureMessage) async {
          try {
            await pump();
            await testExpectation();
            return true;
          } on TestFailure catch (e) {
            setFailureMessage(e.message ?? '');
            return false;
          }
        },
        timeout: timeout,
        pollInterval: pollInterval,
        stackTrace: stackTrace,
      );

  /// Waits until the [condition] returns true
  /// Will raise a complete with a [TimeoutException] if the
  /// condition does not return true with the timeout period.
  /// Copied from: https://github.com/jonsamwell/flutter_gherkin/blob/02a4af91d7a2512e0a4540b9b1ab13e36d5c6f37/lib/src/flutter/utils/driver_utils.dart#L86
  Future<void> _waitUntil(
    Future<bool> Function(void Function(String message) setFailureMessage)
        condition, {
    Duration? timeout = const Duration(seconds: 15),
    Duration? pollInterval = const Duration(milliseconds: 500),
    String? stackTrace,
  }) async {
    var firstFailureMsg = '';
    var lastFailureMsg = 'same as first failure';
    void setFailureMessage(String message) {
      if (firstFailureMsg.isEmpty) {
        firstFailureMsg = message;
      } else {
        lastFailureMsg = message;
      }
    }

    try {
      await Future.microtask(
        () async {
          final completer = Completer<void>();
          final maxAttempts =
              (timeout!.inMilliseconds / pollInterval!.inMilliseconds).round();
          var attempts = 0;

          while (attempts < maxAttempts) {
            final result = await condition(setFailureMessage);
            if (result) {
              completer.complete();
              break;
            } else {
              await Future<void>.delayed(pollInterval);
            }
            attempts++;
          }
        },
      ).timeout(
        timeout!,
      );
    } on TimeoutException catch (e) {
      throw Exception(
        '''$e

Stacktrace: 
$stackTrace
First Failure: 
$firstFailureMsg
Last Failure: 
$lastFailureMsg''',
      );
    }
  }

  Future<void> scrollTo(Key widgetKey) async {
    await dragUntilVisible(
      find.byKey(widgetKey),
      find.byType(SingleChildScrollView).first,
      const Offset(0, 100),
    );
    await pumpAndSettle();
  }
}

void expectWidgetHasText(
  Key key, {
  required Matcher matcher,
  bool skipOffstage = true,
}) {
  final widget =
      find.byKey(key, skipOffstage: skipOffstage).evaluate().single.widget;
  if (widget is Text) {
    expect(widget.data, matcher);
  } else {
    throw 'Widget with key $key is not a Widget of type "Text"';
  }
}

void expectWidgetHasDuration(
  Key key, {
  required dynamic matcher,
  bool skipOffstage = true,
}) {
  final widget =
      find.byKey(key, skipOffstage: skipOffstage).evaluate().single.widget;
  if (widget is Text) {
    final regexp = RegExp(r'\d+:\d{2}:\d{2}.\d{6}');
    final match = regexp.firstMatch(widget.data ?? '');
    final duration = _parseDuration(match?.group(0));
    expect(duration, matcher);
  } else {
    throw 'Widget with key $key is not a Widget of type "Text"';
  }
}

/// Parse Duration string to Duration
Duration? _parseDuration(String? s) {
  if (s == null || s.isEmpty) {
    return null;
  }
  var hours = 0, minutes = 0, micros = 0;
  final parts = s.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}

void expectEnumToggleHasSelected(
  Key key, {
  required Matcher matcher,
  bool skipOffstage = true,
}) {
  final widget =
      find.byKey(key, skipOffstage: skipOffstage).evaluate().single.widget;
  if (widget is EnumTgl) {
    expect(widget.selected, matcher);
  } else {
    throw 'Widget with key $key is not a Widget of type "Text"';
  }
}
