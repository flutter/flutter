// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'error.dart';
import 'find.dart';
import 'gesture.dart';
import 'health.dart';
import 'input.dart';
import 'message.dart';

const String _extensionMethodName = 'driver';
const String _extensionMethod = 'ext.flutter.$_extensionMethodName';
const Duration _kDefaultTimeout = const Duration(seconds: 5);

class _DriverBinding extends WidgetsFlutterBinding { // TODO(ianh): refactor so we're not extending a concrete binding
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
  assert(WidgetsBinding.instance == null);
  new _DriverBinding();
  assert(WidgetsBinding.instance is _DriverBinding);
}

/// Handles a command and returns a result.
typedef Future<Result> CommandHandlerCallback(Command c);

/// Deserializes JSON map to a command object.
typedef Command CommandDeserializerCallback(Map<String, String> params);

/// Runs the finder and returns the [Element] found, or `null`.
typedef Finder FinderConstructor(SerializableFinder finder);

class FlutterDriverExtension {
  static final Logger _log = new Logger('FlutterDriverExtension');

  FlutterDriverExtension() {
    _commandHandlers.addAll(<String, CommandHandlerCallback>{
      'get_health': _getHealth,
      'tap': _tap,
      'get_text': _getText,
      'scroll': _scroll,
      'scrollIntoView': _scrollIntoView,
      'setInputText': _setInputText,
      'submitInputText': _submitInputText,
      'waitFor': _waitFor,
    });

    _commandDeserializers.addAll(<String, CommandDeserializerCallback>{
      'get_health': GetHealth.deserialize,
      'tap': Tap.deserialize,
      'get_text': GetText.deserialize,
      'scroll': Scroll.deserialize,
      'scrollIntoView': ScrollIntoView.deserialize,
      'setInputText': SetInputText.deserialize,
      'submitInputText': SubmitInputText.deserialize,
      'waitFor': WaitFor.deserialize,
    });

    _finders.addAll(<String, FinderConstructor>{
      'ByText': _createByTextFinder,
      'ByTooltipMessage': _createByTooltipMessageFinder,
      'ByValueKey': _createByValueKeyFinder,
    });
  }

  final WidgetController prober = new WidgetController(WidgetsBinding.instance);
  final Map<String, CommandHandlerCallback> _commandHandlers = <String, CommandHandlerCallback>{};
  final Map<String, CommandDeserializerCallback> _commandDeserializers = <String, CommandDeserializerCallback>{};
  final Map<String, FinderConstructor> _finders = <String, FinderConstructor>{};

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
      SchedulerBinding.instance.addPersistentFrameCallback((Duration timestamp) {
        frameReadyController.add(timestamp);
      });
      _onFrameReadyStream = frameReadyController.stream;
    }
    return _onFrameReadyStream;
  }

  Future<Health> _getHealth(Command command) async => new Health(HealthStatus.ok);

  /// Runs `finder` repeatedly until it finds one or more [Element]s, or times out.
  ///
  /// The timeout is five seconds.
  Future<Finder> _waitForElement(Finder finder) {
    // Short-circuit if the element is already on the UI
    if (finder.precache())
      return new Future<Finder>.value(finder);

    // No element yet, so we retry on frames rendered in the future.
    Completer<Finder> completer = new Completer<Finder>();
    StreamSubscription<Duration> subscription;

    Timer timeout = new Timer(_kDefaultTimeout, () {
      subscription.cancel();
      completer.completeError('Timed out waiting for ${finder.description}');
    });

    subscription = _onFrameReady.listen((Duration duration) {
      if (finder.precache()) {
        subscription.cancel();
        timeout.cancel();
        completer.complete(finder);
      }
    });

    return completer.future;
  }

  Finder _createByTextFinder(ByText arguments) {
    return find.text(arguments.text);
  }

  Finder _createByTooltipMessageFinder(ByTooltipMessage arguments) {
    return find.byElementPredicate((Element element) {
      Widget widget = element.widget;
      if (widget is Tooltip)
        return widget.message == arguments.text;
      return false;
    }, description: 'widget with text tooltip "${arguments.text}"');
  }

  Finder _createByValueKeyFinder(ByValueKey arguments) {
    return find.byKey(new ValueKey<dynamic>(arguments.keyValue));
  }

  Finder _createFinder(SerializableFinder finder) {
    FinderConstructor constructor = _finders[finder.finderType];

    if (constructor == null)
      throw 'Unsupported finder type: ${finder.finderType}';

    return constructor(finder);
  }

  Future<TapResult> _tap(Command command) async {
    Tap tapCommand = command;
    await prober.tap(await _waitForElement(_createFinder(tapCommand.finder)));
    return new TapResult();
  }

  Future<WaitForResult> _waitFor(Command command) async {
    WaitFor waitForCommand = command;
    if ((await _waitForElement(_createFinder(waitForCommand.finder))).evaluate().isNotEmpty)
      return new WaitForResult();
    else
      return null;
  }

  Future<ScrollResult> _scroll(Command command) async {
    Scroll scrollCommand = command;
    Finder target = await _waitForElement(_createFinder(scrollCommand.finder));
    final int totalMoves = scrollCommand.duration.inMicroseconds * scrollCommand.frequency ~/ Duration.MICROSECONDS_PER_SECOND;
    Offset delta = new Offset(scrollCommand.dx, scrollCommand.dy) / totalMoves.toDouble();
    Duration pause = scrollCommand.duration ~/ totalMoves;
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

  Future<ScrollResult> _scrollIntoView(Command command) async {
    ScrollIntoView scrollIntoViewCommand = command;
    Finder target = await _waitForElement(_createFinder(scrollIntoViewCommand.finder));
    await Scrollable.ensureVisible(target.evaluate().single);
    return new ScrollResult();
  }

  Future<SetInputTextResult> _setInputText(Command command) async {
    SetInputText setInputTextCommand = command;
    Finder target = await _waitForElement(_createFinder(setInputTextCommand.finder));
    Input input = target.evaluate().single.widget;
    input.onChanged(new InputValue(text: setInputTextCommand.text));
    return new SetInputTextResult();
  }

  Future<SubmitInputTextResult> _submitInputText(Command command) async {
    SubmitInputText submitInputTextCommand = command;
    Finder target = await _waitForElement(_createFinder(submitInputTextCommand.finder));
    Input input = target.evaluate().single.widget;
    input.onSubmitted(input.value);
    return new SubmitInputTextResult(input.value.text);
  }

  Future<GetTextResult> _getText(Command command) async {
    GetText getTextCommand = command;
    Finder target = await _waitForElement(_createFinder(getTextCommand.finder));
    // TODO(yjbanov): support more ways to read text
    Text text = target.evaluate().single.widget;
    return new GetTextResult(text.data);
  }
}
