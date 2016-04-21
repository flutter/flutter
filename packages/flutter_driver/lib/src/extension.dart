// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/src/instrumentation.dart';
import 'package:flutter_test/src/test_pointer.dart';

import 'error.dart';
import 'find.dart';
import 'gesture.dart';
import 'health.dart';
import 'message.dart';

const String _extensionMethodName = 'driver';
const String _extensionMethod = 'ext.flutter.$_extensionMethodName';
const Duration _kDefaultTimeout = const Duration(seconds: 5);

class _DriverBinding extends WidgetFlutterBinding { // TODO(ianh): refactor so we're not extending a concrete binding
  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    FlutterDriverExtension extension = new FlutterDriverExtension();
    registerServiceExtension(
      name: _extensionMethodName,
      callback: extension.call
    );
  }
}

/// Enables Flutter Driver VM service extension.
///
/// This extension is required for tests that use `package:flutter_driver` to
/// drive applications from a separate process.
///
/// Call this function prior to running your application, e.g. before you call
/// `runApp`.
void enableFlutterDriverExtension() {
  assert(Widgeteer.instance == null);
  new _DriverBinding();
  assert(Widgeteer.instance is _DriverBinding);
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
    _commandHandlers.addAll(<String, CommandHandlerCallback>{
      'get_health': getHealth,
      'tap': tap,
      'get_text': getText,
      'scroll': scroll,
      'waitFor': waitFor,
    });

    _commandDeserializers.addAll(<String, CommandDeserializerCallback>{
      'get_health': GetHealth.deserialize,
      'tap': Tap.deserialize,
      'get_text': GetText.deserialize,
      'scroll': Scroll.deserialize,
      'waitFor': WaitFor.deserialize,
    });

    _finders.addAll(<String, FinderCallback>{
      'ByValueKey': _findByValueKey,
      'ByTooltipMessage': _findByTooltipMessage,
      'ByText': _findByText,
    });
  }

  final Instrumentation prober = new Instrumentation();
  final Map<String, CommandHandlerCallback> _commandHandlers = <String, CommandHandlerCallback>{};
  final Map<String, CommandDeserializerCallback> _commandDeserializers = <String, CommandDeserializerCallback>{};
  final Map<String, FinderCallback> _finders = <String, FinderCallback>{};

  Future<Map<String, dynamic>> call(Map<String, String> params) async {
    try {
      String commandKind = params['command'];
      CommandHandlerCallback commandHandler = _commandHandlers[commandKind];
      CommandDeserializerCallback commandDeserializer =
          _commandDeserializers[commandKind];
      if (commandHandler == null || commandDeserializer == null)
        throw 'Extension $_extensionMethod does not support command $commandKind';
      Command command = commandDeserializer(params);
      return (await commandHandler(command)).toJson();
    } catch (error, stackTrace) {
      _log.error('Uncaught extension error: $error\n$stackTrace');
      rethrow;
    }
  }

  Stream<Duration> _onFrameReadyStream;
  Stream<Duration> get _onFrameReady {
    if (_onFrameReadyStream == null) {
      // Lazy-initialize the frame callback because the renderer is not yet
      // available at the time the extension is registered.
      StreamController<Duration> frameReadyController = new StreamController<Duration>.broadcast(sync: true);
      Scheduler.instance.addPersistentFrameCallback((Duration timestamp) {
        frameReadyController.add(timestamp);
      });
      _onFrameReadyStream = frameReadyController.stream;
    }
    return _onFrameReadyStream;
  }

  Future<Health> getHealth(GetHealth command) async => new Health(HealthStatus.ok);

  /// Runs [locator] repeatedly until it finds an [Element] or times out.
  Future<Element> _waitForElement(String descriptionGetter(), Element locator()) async {
    // Short-circuit if the element is already on the UI
    Element element = locator();
    if (element != null) {
      return element;
    }

    // No element yet, so we retry on frames rendered in the future.
    Completer<Element> completer = new Completer<Element>();
    StreamSubscription<Duration> subscription;

    Timer timeout = new Timer(_kDefaultTimeout, () {
      subscription.cancel();
      completer.completeError('Timed out waiting for ${descriptionGetter()}');
    });

    subscription = _onFrameReady.listen((Duration duration) {
      Element element = locator();
      if (element != null) {
        subscription.cancel();
        timeout.cancel();
        completer.complete(element);
      }
    });

    return completer.future;
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

  Future<WaitForResult> waitFor(WaitFor command) async {
    if (await _runFinder(command.finder) != null)
      return new WaitForResult();
    else
      return null;
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
    prober.binding.dispatchEvent(pointer.down(startLocation), hitTest);
    await new Future<Null>.value();  // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves++) {
      currentLocation = currentLocation + delta;
      prober.binding.dispatchEvent(pointer.move(currentLocation), hitTest);
      await new Future<Null>.delayed(pause);
    }
    prober.binding.dispatchEvent(pointer.up(), hitTest);

    return new ScrollResult();
  }

  Future<GetTextResult> getText(GetText command) async {
    Element target = await _runFinder(command.finder);
    // TODO(yjbanov): support more ways to read text
    Text text = target.widget;
    return new GetTextResult(text.data);
  }
}
