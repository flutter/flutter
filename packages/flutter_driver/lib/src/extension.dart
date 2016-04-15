// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/src/instrumentation.dart';
import 'package:flutter_test/src/test_pointer.dart';

import 'error.dart';
import 'find.dart';
import 'gesture.dart';
import 'health.dart';
import 'message.dart';
import 'retry.dart';

const String _extensionMethod = 'ext.flutter_driver';
const Duration _kDefaultTimeout = const Duration(seconds: 5);
const Duration _kDefaultPauseBetweenRetries = const Duration(milliseconds: 160);

bool _flutterDriverExtensionEnabled = false;

/// Enables Flutter Driver VM service extension.
///
/// This extension is required for tests that use `package:flutter_driver` to
/// drive applications from a separate process.
///
/// Call this function prior to running your application, e.g. before you call
/// `runApp`.
void enableFlutterDriverExtension() {
  if (_flutterDriverExtensionEnabled)
    return;
  FlutterDriverExtension extension = new FlutterDriverExtension();
  registerExtension(_extensionMethod, (String methodName, Map<String, String> params) {
    return extension.call(params);
  });
  _flutterDriverExtensionEnabled = true;
}

/// Handles a command and returns a result.
typedef Future<Result> CommandHandlerCallback(Command c);

/// Deserializes JSON map to a command object.
typedef Command CommandDeserializerCallback(Map<String, String> params);

/// Runs the finder and returns the [Element] found, or `null`.
typedef Future<Element> FinderCallback(SerializableFinder finder);

class FlutterDriverExtension {
  static final Logger _log = new Logger('FlutterDriverExtension');

  FlutterDriverExtension() {
    _commandHandlers = <String, CommandHandlerCallback>{
      'get_health': getHealth,
      'tap': tap,
      'get_text': getText,
      'scroll': scroll,
    };

    _commandDeserializers = <String, CommandDeserializerCallback>{
      'get_health': GetHealth.deserialize,
      'tap': Tap.deserialize,
      'get_text': GetText.deserialize,
      'scroll': Scroll.deserialize,
    };

    _finders = <String, FinderCallback>{
      'ByValueKey': _findByValueKey,
      'ByTooltipMessage': _findByTooltipMessage,
      'ByText': _findByText,
    };
  }

  final Instrumentation prober = new Instrumentation();

  Map<String, CommandHandlerCallback> _commandHandlers;
  Map<String, CommandDeserializerCallback> _commandDeserializers;
  Map<String, FinderCallback> _finders;

  Future<ServiceExtensionResponse> call(Map<String, String> params) async {
    try {
      String commandKind = params['command'];
      CommandHandlerCallback commandHandler = _commandHandlers[commandKind];
      CommandDeserializerCallback commandDeserializer =
          _commandDeserializers[commandKind];

      if (commandHandler == null || commandDeserializer == null) {
        return new ServiceExtensionResponse.error(
          ServiceExtensionResponse.invalidParams,
          'Extension $_extensionMethod does not support command $commandKind'
        );
      }

      Command command = commandDeserializer(params);
      return commandHandler(command).then((Result result) {
        return new ServiceExtensionResponse.result(JSON.encode(result.toJson()));
      }, onError: (Object e, Object s) {
        _log.warning('$e:\n$s');
        return new ServiceExtensionResponse.error(ServiceExtensionResponse.extensionError, '$e');
      });
    } catch(error, stackTrace) {
      String message = 'Uncaught extension error: $error\n$stackTrace';
      _log.error(message);
      return new ServiceExtensionResponse.error(
        ServiceExtensionResponse.extensionError, message);
    }
  }

  Future<Health> getHealth(GetHealth command) async => new Health(HealthStatus.ok);

  /// Runs object [finder] repeatedly until it finds an [Element].
  Future<Element> _waitForElement(String descriptionGetter(), Element locator()) {
    return retry(locator, _kDefaultTimeout, _kDefaultPauseBetweenRetries, predicate: (dynamic object) {
      return object != null;
    }).catchError((Object error, Object stackTrace) {
      _log.warning('Timed out waiting for ${descriptionGetter()}');
      return null;
    });
  }

  Future<Element> _findByValueKey(ByValueKey byKey) async {
    return _waitForElement(
      () => 'element with key "${byKey.keyValue}" of type ${byKey.keyValueType}',
      () {
        return prober.findElementByKey(new ValueKey<dynamic>(byKey.keyValue));
      }
    );
  }

  Future<Element> _findByTooltipMessage(ByTooltipMessage byTooltipMessage) async {
    return _waitForElement(
      () => 'tooltip with message "${byTooltipMessage.text}" on it',
      () {
        return prober.findElement((Element element) {
          Widget widget = element.widget;

          if (widget is Tooltip)
            return widget.message == byTooltipMessage.text;

          return false;
        });
      }
    );
  }

  Future<Element> _findByText(ByText byText) async {
    return await _waitForElement(
      () => 'text "${byText.text}"',
      () {
        return prober.findText(byText.text);
      });
  }

  Future<Element> _runFinder(SerializableFinder finder) {
    FinderCallback cb = _finders[finder.finderType];

    if (cb == null)
      throw 'Unsupported finder type: ${finder.finderType}';

    return cb(finder);
  }

  Future<TapResult> tap(Tap command) async {
    Element target = await _runFinder(command.finder);
    prober.tap(target);
    return new TapResult();
  }

  Future<ScrollResult> scroll(Scroll command) async {
    Element target = await _runFinder(command.finder);
    final int totalMoves = command.duration.inMicroseconds * command.frequency ~/ Duration.MICROSECONDS_PER_SECOND;
    Offset delta = new Offset(command.dx, command.dy) / totalMoves.toDouble();
    Duration pause = command.duration ~/ totalMoves;
    Point startLocation = prober.getCenter(target);
    Point currentLocation = startLocation;
    TestPointer pointer = new TestPointer(1);
    HitTestResult hitTest = new HitTestResult();

    prober.binding.hitTest(hitTest, startLocation);
    prober.dispatchEvent(pointer.down(startLocation), hitTest);
    await new Future<Null>.value();  // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves++) {
      currentLocation = currentLocation + delta;
      prober.dispatchEvent(pointer.move(currentLocation), hitTest);
      await new Future<Null>.delayed(pause);
    }
    prober.dispatchEvent(pointer.up(), hitTest);

    return new ScrollResult();
  }

  Future<GetTextResult> getText(GetText command) async {
    Element target = await _runFinder(command.finder);
    // TODO(yjbanov): support more ways to read text
    Text text = target.widget;
    return new GetTextResult(text.data);
  }
}
