// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, SemanticsHandle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'error.dart';
import 'find.dart';
import 'frame_sync.dart';
import 'gesture.dart';
import 'health.dart';
import 'message.dart';
import 'render_tree.dart';
import 'semantics.dart';

const String _extensionMethodName = 'driver';
const String _extensionMethod = 'ext.flutter.$_extensionMethodName';

class _DriverBinding extends WidgetsFlutterBinding { // TODO(ianh): refactor so we're not extending a concrete binding
  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    final FlutterDriverExtension extension = new FlutterDriverExtension();
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

/// Signature for functions that handle a command and return a result.
typedef Future<Result> CommandHandlerCallback(Command c);

/// Signature for functions that deserialize a JSON map to a command object.
typedef Command CommandDeserializerCallback(Map<String, String> params);

/// Signature for functions that run the given finder and return the [Element]
/// found, if any, or null otherwise.
typedef Finder FinderConstructor(SerializableFinder finder);

@visibleForTesting
class FlutterDriverExtension {
  static final Logger _log = new Logger('FlutterDriverExtension');

  FlutterDriverExtension() {
    _commandHandlers.addAll(<String, CommandHandlerCallback>{
      'get_health': _getHealth,
      'get_render_tree': _getRenderTree,
      'tap': _tap,
      'get_text': _getText,
      'set_frame_sync': _setFrameSync,
      'set_semantics': _setSemantics,
      'scroll': _scroll,
      'scrollIntoView': _scrollIntoView,
      'waitFor': _waitFor,
      'waitUntilNoTransientCallbacks': _waitUntilNoTransientCallbacks,
    });

    _commandDeserializers.addAll(<String, CommandDeserializerCallback>{
      'get_health': (Map<String, String> params) => new GetHealth.deserialize(params),
      'get_render_tree': (Map<String, String> params) => new GetRenderTree.deserialize(params),
      'tap': (Map<String, String> params) => new Tap.deserialize(params),
      'get_text': (Map<String, String> params) => new GetText.deserialize(params),
      'set_frame_sync': (Map<String, String> params) => new SetFrameSync.deserialize(params),
      'set_semantics': (Map<String, String> params) => new SetSemantics.deserialize(params),
      'scroll': (Map<String, String> params) => new Scroll.deserialize(params),
      'scrollIntoView': (Map<String, String> params) => new ScrollIntoView.deserialize(params),
      'waitFor': (Map<String, String> params) => new WaitFor.deserialize(params),
      'waitUntilNoTransientCallbacks': (Map<String, String> params) => new WaitUntilNoTransientCallbacks.deserialize(params),
    });

    _finders.addAll(<String, FinderConstructor>{
      'ByText': _createByTextFinder,
      'ByTooltipMessage': _createByTooltipMessageFinder,
      'ByValueKey': _createByValueKeyFinder,
    });
  }

  final WidgetController _prober = new WidgetController(WidgetsBinding.instance);
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
      _log.error(msg);
      return _makeResponse(msg, isError: true);
    }
  }

  Map<String, dynamic> _makeResponse(dynamic response, {bool isError: false}) {
    return <String, dynamic>{
      'isError': isError,
      'response': response,
    };
  }

  Future<Health> _getHealth(Command command) async => new Health(HealthStatus.ok);

  Future<RenderTree> _getRenderTree(Command command) async {
    return new RenderTree(RendererBinding.instance?.renderView?.toStringDeep());
  }

  // Waits until at the end of a frame the provided [condition] is [true].
  Future<Null> _waitUntilFrame(bool condition(), [Completer<Null> completer]) {
    completer ??= new Completer<Null>();
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
    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    await _waitUntilFrame(() => finder.precache());

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
        return find.byKey(new ValueKey<int>(arguments.keyValue));
      case 'String':
        return find.byKey(new ValueKey<String>(arguments.keyValue));
      default:
        throw 'Unsupported ByValueKey type: ${arguments.keyValueType}';
    }
  }

  Finder _createFinder(SerializableFinder finder) {
    final FinderConstructor constructor = _finders[finder.finderType];

    if (constructor == null)
      throw 'Unsupported finder type: ${finder.finderType}';

    return constructor(finder);
  }

  Future<TapResult> _tap(Command command) async {
    final Tap tapCommand = command;
    await _prober.tap(await _waitForElement(_createFinder(tapCommand.finder)));
    return new TapResult();
  }

  Future<WaitForResult> _waitFor(Command command) async {
    final WaitFor waitForCommand = command;
    if ((await _waitForElement(_createFinder(waitForCommand.finder))).evaluate().isNotEmpty)
      return new WaitForResult();
    else
      return null;
  }

  Future<Null> _waitUntilNoTransientCallbacks(Command command) async {
    if (SchedulerBinding.instance.transientCallbackCount != 0)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);
  }

  Future<ScrollResult> _scroll(Command command) async {
    final Scroll scrollCommand = command;
    final Finder target = await _waitForElement(_createFinder(scrollCommand.finder));
    final int totalMoves = scrollCommand.duration.inMicroseconds * scrollCommand.frequency ~/ Duration.MICROSECONDS_PER_SECOND;
    final Offset delta = new Offset(scrollCommand.dx, scrollCommand.dy) / totalMoves.toDouble();
    final Duration pause = scrollCommand.duration ~/ totalMoves;
    final Offset startLocation = _prober.getCenter(target);
    Offset currentLocation = startLocation;
    final TestPointer pointer = new TestPointer(1);
    final HitTestResult hitTest = new HitTestResult();

    _prober.binding.hitTest(hitTest, startLocation);
    _prober.binding.dispatchEvent(pointer.down(startLocation), hitTest);
    await new Future<Null>.value();  // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves++) {
      currentLocation = currentLocation + delta;
      _prober.binding.dispatchEvent(pointer.move(currentLocation), hitTest);
      await new Future<Null>.delayed(pause);
    }
    _prober.binding.dispatchEvent(pointer.up(), hitTest);

    return new ScrollResult();
  }

  Future<ScrollResult> _scrollIntoView(Command command) async {
    final ScrollIntoView scrollIntoViewCommand = command;
    final Finder target = await _waitForElement(_createFinder(scrollIntoViewCommand.finder));
    await Scrollable.ensureVisible(target.evaluate().single, duration: const Duration(milliseconds: 100), alignment: scrollIntoViewCommand.alignment ?? 0.0);
    return new ScrollResult();
  }

  Future<GetTextResult> _getText(Command command) async {
    final GetText getTextCommand = command;
    final Finder target = await _waitForElement(_createFinder(getTextCommand.finder));
    // TODO(yjbanov): support more ways to read text
    final Text text = target.evaluate().single.widget;
    return new GetTextResult(text.data);
  }

  Future<SetFrameSyncResult> _setFrameSync(Command command) async {
    final SetFrameSync setFrameSyncCommand = command;
    _frameSync = setFrameSyncCommand.enabled;
    return new SetFrameSyncResult();
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
        final Completer<Null> completer = new Completer<Null>();
        SchedulerBinding.instance.addPostFrameCallback((Duration d) {
          completer.complete();
        });
        await completer.future;
      }
    } else if (!setSemanticsCommand.enabled && _semantics != null) {
      _semantics.dispose();
      _semantics = null;
    }
    return new SetSemanticsResult(semanticsWasEnabled != _semanticsIsEnabled);
  }
}
