// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:meta/meta.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, SemanticsHandle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/error.dart';
import '../common/find.dart';
import '../common/frame_sync.dart';
import '../common/gesture.dart';
import '../common/health.dart';
import '../common/message.dart';
import '../common/render_tree.dart';
import '../common/request_data.dart';
import '../common/semantics.dart';
import '../common/text.dart';

const String _extensionMethodName = 'driver';
const String _extensionMethod = 'ext.flutter.$_extensionMethodName';

/// Signature for the handler passed to [enableFlutterDriverExtension].
///
/// Messages are described in string form and should return a [Future] which
/// eventually completes to a string response.
typedef DataHandler = Future<String> Function(String message);

class _DriverBinding extends BindingBase with ServicesBinding, SchedulerBinding, GestureBinding, PaintingBinding, SemanticsBinding, RendererBinding, WidgetsBinding {
  _DriverBinding(this._handler, this._silenceErrors);

  final DataHandler _handler;
  final bool _silenceErrors;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    final FlutterDriverExtension extension = FlutterDriverExtension(_handler, _silenceErrors);
    registerServiceExtension(
      name: _extensionMethodName,
      callback: extension.call,
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
///
/// Optionally you can pass a [DataHandler] callback. It will be called if the
/// test calls [FlutterDriver.requestData].
///
/// `slienceErrors` will prevent exceptions from being logged. This is useful
/// for tests where exceptions are expected. Defaults to false. Any errors
/// will still be returned in the `response` field of the result json along
/// with an `isError` boolean.
void enableFlutterDriverExtension({ DataHandler handler, bool silenceErrors = false }) {
  assert(WidgetsBinding.instance == null);
  _DriverBinding(handler, silenceErrors);
  assert(WidgetsBinding.instance is _DriverBinding);
}

/// Signature for functions that handle a command and return a result.
typedef CommandHandlerCallback = Future<Result> Function(Command c);

/// Signature for functions that deserialize a JSON map to a command object.
typedef CommandDeserializerCallback = Command Function(Map<String, String> params);

/// Signature for functions that run the given finder and return the [Element]
/// found, if any, or null otherwise.
typedef FinderConstructor = Finder Function(SerializableFinder finder);

/// The class that manages communication between a Flutter Driver test and the
/// application being remote-controlled, on the application side.
///
/// This is not normally used directly. It is instantiated automatically when
/// calling [enableFlutterDriverExtension].
@visibleForTesting
class FlutterDriverExtension {
  /// Creates an object to manage a Flutter Driver connection.
  FlutterDriverExtension(this._requestDataHandler, this._silenceErrors) {
    _testTextInput.register();

    _commandHandlers.addAll(<String, CommandHandlerCallback>{
      'get_health': _getHealth,
      'get_render_tree': _getRenderTree,
      'enter_text': _enterText,
      'get_text': _getText,
      'request_data': _requestData,
      'scroll': _scroll,
      'scrollIntoView': _scrollIntoView,
      'set_frame_sync': _setFrameSync,
      'set_semantics': _setSemantics,
      'set_text_entry_emulation': _setTextEntryEmulation,
      'tap': _tap,
      'waitFor': _waitFor,
      'waitForAbsent': _waitForAbsent,
      'waitUntilNoTransientCallbacks': _waitUntilNoTransientCallbacks,
      'get_semantics_id': _getSemanticsId,
    });

    _commandDeserializers.addAll(<String, CommandDeserializerCallback>{
      'get_health': (Map<String, String> params) => GetHealth.deserialize(params),
      'get_render_tree': (Map<String, String> params) => GetRenderTree.deserialize(params),
      'enter_text': (Map<String, String> params) => EnterText.deserialize(params),
      'get_text': (Map<String, String> params) => GetText.deserialize(params),
      'request_data': (Map<String, String> params) => RequestData.deserialize(params),
      'scroll': (Map<String, String> params) => Scroll.deserialize(params),
      'scrollIntoView': (Map<String, String> params) => ScrollIntoView.deserialize(params),
      'set_frame_sync': (Map<String, String> params) => SetFrameSync.deserialize(params),
      'set_semantics': (Map<String, String> params) => SetSemantics.deserialize(params),
      'set_text_entry_emulation': (Map<String, String> params) => SetTextEntryEmulation.deserialize(params),
      'tap': (Map<String, String> params) => Tap.deserialize(params),
      'waitFor': (Map<String, String> params) => WaitFor.deserialize(params),
      'waitForAbsent': (Map<String, String> params) => WaitForAbsent.deserialize(params),
      'waitUntilNoTransientCallbacks': (Map<String, String> params) => WaitUntilNoTransientCallbacks.deserialize(params),
      'get_semantics_id': (Map<String, String> params) => GetSemanticsId.deserialize(params),
    });

    _finders.addAll(<String, FinderConstructor>{
      'ByText': (SerializableFinder finder) => _createByTextFinder(finder),
      'ByTooltipMessage': (SerializableFinder finder) => _createByTooltipMessageFinder(finder),
      'ByValueKey': (SerializableFinder finder) => _createByValueKeyFinder(finder),
      'ByType': (SerializableFinder finder) => _createByTypeFinder(finder),
      'PageBack': (SerializableFinder finder) => _createPageBackFinder(),
    });
  }

  final TestTextInput _testTextInput = TestTextInput();

  final DataHandler _requestDataHandler;
  final bool _silenceErrors;

  static final Logger _log = Logger('FlutterDriverExtension');

  final WidgetController _prober = LiveWidgetController(WidgetsBinding.instance);
  final Map<String, CommandHandlerCallback> _commandHandlers = <String, CommandHandlerCallback>{};
  final Map<String, CommandDeserializerCallback> _commandDeserializers = <String, CommandDeserializerCallback>{};
  final Map<String, FinderConstructor> _finders = <String, FinderConstructor>{};

  /// With [_frameSync] enabled, Flutter Driver will wait to perform an action
  /// until there are no pending frames in the app under test.
  bool _frameSync = true;

  /// Processes a driver command configured by [params] and returns a result
  /// as an arbitrary JSON object.
  ///
  /// [params] must contain key "command" whose value is a string that
  /// identifies the kind of the command and its corresponding
  /// [CommandDeserializerCallback]. Other keys and values are specific to the
  /// concrete implementation of [Command] and [CommandDeserializerCallback].
  ///
  /// The returned JSON is command specific. Generally the caller deserializes
  /// the result into a subclass of [Result], but that's not strictly required.
  @visibleForTesting
  Future<Map<String, dynamic>> call(Map<String, String> params) async {
    final String commandKind = params['command'];
    try {
      final CommandHandlerCallback commandHandler = _commandHandlers[commandKind];
      final CommandDeserializerCallback commandDeserializer =
          _commandDeserializers[commandKind];
      if (commandHandler == null || commandDeserializer == null)
        throw 'Extension $_extensionMethod does not support command $commandKind';
      final Command command = commandDeserializer(params);
      final Result response = await commandHandler(command).timeout(command.timeout);
      return _makeResponse(response?.toJson());
    } on TimeoutException catch (error, stackTrace) {
      final String msg = 'Timeout while executing $commandKind: $error\n$stackTrace';
      _log.error(msg);
      return _makeResponse(msg, isError: true);
    } catch (error, stackTrace) {
      final String msg = 'Uncaught extension error while executing $commandKind: $error\n$stackTrace';
      if (!_silenceErrors)
        _log.error(msg);
      return _makeResponse(msg, isError: true);
    }
  }

  Map<String, dynamic> _makeResponse(dynamic response, {bool isError = false}) {
    return <String, dynamic>{
      'isError': isError,
      'response': response,
    };
  }

  Future<Health> _getHealth(Command command) async => Health(HealthStatus.ok);

  Future<RenderTree> _getRenderTree(Command command) async {
    return RenderTree(RendererBinding.instance?.renderView?.toStringDeep());
  }

  // Waits until at the end of a frame the provided [condition] is [true].
  Future<void> _waitUntilFrame(bool condition(), [Completer<void> completer]) {
    completer ??= Completer<void>();
    if (!condition()) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        _waitUntilFrame(condition, completer);
      });
    } else {
      completer.complete();
    }
    return completer.future;
  }

  /// Runs `finder` repeatedly until it finds one or more [Element]s.
  Future<Finder> _waitForElement(Finder finder) async {
    // TODO(mravn): This method depends on async execution. A refactoring
    // for sync-async semantics is tracked in https://github.com/flutter/flutter/issues/16801.
    await Future<void>.value(null);
    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    await _waitUntilFrame(() => finder.evaluate().isNotEmpty);

    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    return finder;
  }

  /// Runs `finder` repeatedly until it finds zero [Element]s.
  Future<Finder> _waitForAbsentElement(Finder finder) async {
    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    await _waitUntilFrame(() => finder.evaluate().isEmpty);

    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    return finder;
  }

  Finder _createByTextFinder(ByText arguments) {
    return find.text(arguments.text);
  }

  Finder _createByTooltipMessageFinder(ByTooltipMessage arguments) {
    return find.byElementPredicate((Element element) {
      final Widget widget = element.widget;
      if (widget is Tooltip)
        return widget.message == arguments.text;
      return false;
    }, description: 'widget with text tooltip "${arguments.text}"');
  }

  Finder _createByValueKeyFinder(ByValueKey arguments) {
    switch (arguments.keyValueType) {
      case 'int':
        return find.byKey(ValueKey<int>(arguments.keyValue));
      case 'String':
        return find.byKey(ValueKey<String>(arguments.keyValue));
      default:
        throw 'Unsupported ByValueKey type: ${arguments.keyValueType}';
    }
  }

  Finder _createByTypeFinder(ByType arguments) {
    return find.byElementPredicate((Element element) {
      return element.widget.runtimeType.toString() == arguments.type;
    }, description: 'widget with runtimeType "${arguments.type}"');
  }

  Finder _createPageBackFinder() {
    return find.byElementPredicate((Element element) {
      final Widget widget = element.widget;
      if (widget is Tooltip)
        return widget.message == 'Back';
      if (widget is CupertinoNavigationBarBackButton)
        return true;
      return false;
    }, description: 'Material or Cupertino back button');
  }

  Finder _createFinder(SerializableFinder finder) {
    final FinderConstructor constructor = _finders[finder.finderType];

    if (constructor == null)
      throw 'Unsupported finder type: ${finder.finderType}';

    return constructor(finder);
  }

  Future<TapResult> _tap(Command command) async {
    final Tap tapCommand = command;
    final Finder computedFinder = await _waitForElement(
      _createFinder(tapCommand.finder).hitTestable()
    );
    await _prober.tap(computedFinder);
    return TapResult();
  }

  Future<WaitForResult> _waitFor(Command command) async {
    final WaitFor waitForCommand = command;
    await _waitForElement(_createFinder(waitForCommand.finder));
    return WaitForResult();
  }

  Future<WaitForAbsentResult> _waitForAbsent(Command command) async {
    final WaitForAbsent waitForAbsentCommand = command;
    await _waitForAbsentElement(_createFinder(waitForAbsentCommand.finder));
    return WaitForAbsentResult();
  }

  Future<Result> _waitUntilNoTransientCallbacks(Command command) async {
    if (SchedulerBinding.instance.transientCallbackCount != 0)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);
    return null;
  }

  Future<GetSemanticsIdResult> _getSemanticsId(Command command) async {
    final GetSemanticsId semanticsCommand = command;
    final Finder target = await _waitForElement(_createFinder(semanticsCommand.finder));
    final Element element = target.evaluate().single;
    RenderObject renderObject = element.renderObject;
    SemanticsNode node;
    while (renderObject != null && node == null) {
      node = renderObject.debugSemantics;
      renderObject = renderObject.parent;
    }
    if (node == null)
      throw StateError('No semantics data found');
    return GetSemanticsIdResult(node.id);
  }

  Future<ScrollResult> _scroll(Command command) async {
    final Scroll scrollCommand = command;
    final Finder target = await _waitForElement(_createFinder(scrollCommand.finder));
    final int totalMoves = scrollCommand.duration.inMicroseconds * scrollCommand.frequency ~/ Duration.microsecondsPerSecond;
    final Offset delta = Offset(scrollCommand.dx, scrollCommand.dy) / totalMoves.toDouble();
    final Duration pause = scrollCommand.duration ~/ totalMoves;
    final Offset startLocation = _prober.getCenter(target);
    Offset currentLocation = startLocation;
    final TestPointer pointer = TestPointer(1);
    final HitTestResult hitTest = HitTestResult();

    _prober.binding.hitTest(hitTest, startLocation);
    _prober.binding.dispatchEvent(pointer.down(startLocation), hitTest);
    await Future<void>.value(); // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves += 1) {
      currentLocation = currentLocation + delta;
      _prober.binding.dispatchEvent(pointer.move(currentLocation), hitTest);
      await Future<void>.delayed(pause);
    }
    _prober.binding.dispatchEvent(pointer.up(), hitTest);

    return ScrollResult();
  }

  Future<ScrollResult> _scrollIntoView(Command command) async {
    final ScrollIntoView scrollIntoViewCommand = command;
    final Finder target = await _waitForElement(_createFinder(scrollIntoViewCommand.finder));
    await Scrollable.ensureVisible(target.evaluate().single, duration: const Duration(milliseconds: 100), alignment: scrollIntoViewCommand.alignment ?? 0.0);
    return ScrollResult();
  }

  Future<GetTextResult> _getText(Command command) async {
    final GetText getTextCommand = command;
    final Finder target = await _waitForElement(_createFinder(getTextCommand.finder));
    // TODO(yjbanov): support more ways to read text
    final Text text = target.evaluate().single.widget;
    return GetTextResult(text.data);
  }

  Future<SetTextEntryEmulationResult> _setTextEntryEmulation(Command command) async {
    final SetTextEntryEmulation setTextEntryEmulationCommand = command;
    if (setTextEntryEmulationCommand.enabled) {
      _testTextInput.register();
    } else {
      _testTextInput.unregister();
    }
    return SetTextEntryEmulationResult();
  }

  Future<EnterTextResult> _enterText(Command command) async {
    if (!_testTextInput.isRegistered) {
      throw 'Unable to fulfill `FlutterDriver.enterText`. Text emulation is '
            'disabled. You can enable it using `FlutterDriver.setTextEntryEmulation`.';
    }
    final EnterText enterTextCommand = command;
    _testTextInput.enterText(enterTextCommand.text);
    return EnterTextResult();
  }

  Future<RequestDataResult> _requestData(Command command) async {
    final RequestData requestDataCommand = command;
    return RequestDataResult(_requestDataHandler == null ? 'No requestData Extension registered' : await _requestDataHandler(requestDataCommand.message));
  }

  Future<SetFrameSyncResult> _setFrameSync(Command command) async {
    final SetFrameSync setFrameSyncCommand = command;
    _frameSync = setFrameSyncCommand.enabled;
    return SetFrameSyncResult();
  }

  SemanticsHandle _semantics;
  bool get _semanticsIsEnabled => RendererBinding.instance.pipelineOwner.semanticsOwner != null;

  Future<SetSemanticsResult> _setSemantics(Command command) async {
    final SetSemantics setSemanticsCommand = command;
    final bool semanticsWasEnabled = _semanticsIsEnabled;
    if (setSemanticsCommand.enabled && _semantics == null) {
      _semantics = RendererBinding.instance.pipelineOwner.ensureSemantics();
      if (!semanticsWasEnabled) {
        // wait for the first frame where semantics is enabled.
        final Completer<void> completer = Completer<void>();
        SchedulerBinding.instance.addPostFrameCallback((Duration d) {
          completer.complete();
        });
        await completer.future;
      }
    } else if (!setSemanticsCommand.enabled && _semantics != null) {
      _semantics.dispose();
      _semantics = null;
    }
    return SetSemanticsResult(semanticsWasEnabled != _semanticsIsEnabled);
  }
}
