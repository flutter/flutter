// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, SemanticsHandle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/diagnostics_tree.dart';
import '../common/error.dart';
import '../common/find.dart';
import '../common/frame_sync.dart';
import '../common/geometry.dart';
import '../common/gesture.dart';
import '../common/health.dart';
import '../common/layer_tree.dart';
import '../common/message.dart';
import '../common/render_tree.dart';
import '../common/request_data.dart';
import '../common/semantics.dart';
import '../common/text.dart';
import '../common/wait.dart';
import '_extension_io.dart' if (dart.library.html) '_extension_web.dart';
import 'wait_conditions.dart';

const String _extensionMethodName = 'driver';
const String _extensionMethod = 'ext.flutter.$_extensionMethodName';

/// Signature for the handler passed to [enableFlutterDriverExtension].
///
/// Messages are described in string form and should return a [Future] which
/// eventually completes to a string response.
typedef DataHandler = Future<String> Function(String message);

class _DriverBinding extends BindingBase with SchedulerBinding, ServicesBinding, GestureBinding, PaintingBinding, SemanticsBinding, RendererBinding, WidgetsBinding {
  _DriverBinding(this._handler, this._silenceErrors, this.finders);

  final DataHandler _handler;
  final bool _silenceErrors;
  final List<FinderExtension> finders;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    final FlutterDriverExtension extension = FlutterDriverExtension(_handler, _silenceErrors, finders);
    registerServiceExtension(
      name: _extensionMethodName,
      callback: extension.call,
    );
    if (kIsWeb) {
      registerWebServiceExtension(extension.call);
    }
  }

  @override
  BinaryMessenger createBinaryMessenger() {
    return TestDefaultBinaryMessenger(super.createBinaryMessenger());
  }
}

/// Enables Flutter Driver VM service extension.
///
/// This extension is required for tests that use `package:flutter_driver` to
/// drive applications from a separate process. In order to allow the driver
/// to interact with the application, this method changes the behavior of the
/// framework in several ways - including keyboard interaction and text
/// editing. Applications intended for release should never include this
/// method.
///
/// Call this function prior to running your application, e.g. before you call
/// `runApp`.
///
/// Optionally you can pass a [DataHandler] callback. It will be called if the
/// test calls [FlutterDriver.requestData].
///
/// `silenceErrors` will prevent exceptions from being logged. This is useful
/// for tests where exceptions are expected. Defaults to false. Any errors
/// will still be returned in the `response` field of the result JSON along
/// with an `isError` boolean.
///
/// The `finders` parameter are used to add custom finders, as in the following example.
///
/// ```dart main
/// void main() {
///   enableFlutterDriverExtension(finders: <FinderExtension>[ SomeFinderExtension() ]);
///
///   app.main();
/// }
/// ```
///
/// ```dart
/// class Some extends SerializableFinder {
///   const Some(this.title);
///
///   final String title;
///
///   @override
///   String get finderType => 'Some';
///
///   @override
///   Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
///     'title': title,
///   });
/// }
/// ```
///
/// ```dart
/// class SomeFinderExtension extends FinderExtension {
///
///  String get finderType => 'Some';
///
///  SerializableFinder deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory) {
///    return Some(json['title']);
///  }
///
///  Finder createFinder(SerializableFinder finder) {
///    Some someFinder = finder as Some;
///
///    return find.byElementPredicate((Element element) {
///      final Widget widget = element.widget;
///      if (element.widget is SomeWidget) {
///        return element.widget.title == someFinder.title;
///      }
///      return false;
///    });
///  }
/// }
/// ```
///
void enableFlutterDriverExtension({ DataHandler handler, bool silenceErrors = false, List<FinderExtension> finders}) {
  assert(WidgetsBinding.instance == null);
  _DriverBinding(handler, silenceErrors, finders ?? <FinderExtension>[]);
  assert(WidgetsBinding.instance is _DriverBinding);
}

/// Signature for functions that handle a command and return a result.
typedef CommandHandlerCallback = Future<Result> Function(Command c);

/// Signature for functions that deserialize a JSON map to a command object.
typedef CommandDeserializerCallback = Command Function(Map<String, String> params);

/// Used to expand the new Finder
abstract class FinderExtension {

  /// Identifies the type of finder to be used by the driver extension.
  String get finderType;

  /// Deserializes the finder from JSON generated by [SerializableFinder.serialize].
  SerializableFinder deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory);

  /// Signature for functions that run the given finder and return the [Element]
  /// found, if any, or null otherwise.
  Finder createFinder(SerializableFinder finder);
}

/// The class that manages communication between a Flutter Driver test and the
/// application being remote-controlled, on the application side.
///
/// This is not normally used directly. It is instantiated automatically when
/// calling [enableFlutterDriverExtension].
@visibleForTesting
class FlutterDriverExtension with DeserializeFinderFactory {
  /// Creates an object to manage a Flutter Driver connection.
  FlutterDriverExtension(this._requestDataHandler, this._silenceErrors, List<FinderExtension> finders) {
    _testTextInput.register();

    _commandHandlers.addAll(<String, CommandHandlerCallback>{
      'get_health': _getHealth,
      'get_layer_tree': _getLayerTree,
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
      'waitForCondition': _waitForCondition,
      'waitUntilNoTransientCallbacks': _waitUntilNoTransientCallbacks,
      'waitUntilNoPendingFrame': _waitUntilNoPendingFrame,
      'waitUntilFirstFrameRasterized': _waitUntilFirstFrameRasterized,
      'get_semantics_id': _getSemanticsId,
      'get_offset': _getOffset,
      'get_diagnostics_tree': _getDiagnosticsTree,
    });

    _commandDeserializers.addAll(<String, CommandDeserializerCallback>{
      'get_health': (Map<String, String> params) => GetHealth.deserialize(params),
      'get_layer_tree': (Map<String, String> params) => GetLayerTree.deserialize(params),
      'get_render_tree': (Map<String, String> params) => GetRenderTree.deserialize(params),
      'enter_text': (Map<String, String> params) => EnterText.deserialize(params),
      'get_text': (Map<String, String> params) => GetText.deserialize(params, this),
      'request_data': (Map<String, String> params) => RequestData.deserialize(params),
      'scroll': (Map<String, String> params) => Scroll.deserialize(params, this),
      'scrollIntoView': (Map<String, String> params) => ScrollIntoView.deserialize(params, this),
      'set_frame_sync': (Map<String, String> params) => SetFrameSync.deserialize(params),
      'set_semantics': (Map<String, String> params) => SetSemantics.deserialize(params),
      'set_text_entry_emulation': (Map<String, String> params) => SetTextEntryEmulation.deserialize(params),
      'tap': (Map<String, String> params) => Tap.deserialize(params, this),
      'waitFor': (Map<String, String> params) => WaitFor.deserialize(params, this),
      'waitForAbsent': (Map<String, String> params) => WaitForAbsent.deserialize(params, this),
      'waitForCondition': (Map<String, String> params) => WaitForCondition.deserialize(params),
      'waitUntilNoTransientCallbacks': (Map<String, String> params) => WaitUntilNoTransientCallbacks.deserialize(params),
      'waitUntilNoPendingFrame': (Map<String, String> params) => WaitUntilNoPendingFrame.deserialize(params),
      'waitUntilFirstFrameRasterized': (Map<String, String> params) => WaitUntilFirstFrameRasterized.deserialize(params),
      'get_semantics_id': (Map<String, String> params) => GetSemanticsId.deserialize(params, this),
      'get_offset': (Map<String, String> params) => GetOffset.deserialize(params, this),
      'get_diagnostics_tree': (Map<String, String> params) => GetDiagnosticsTree.deserialize(params, this),
    });

    for(final FinderExtension finder in finders) {
      _finderExtensions[finder.finderType] = finder;
    }
  }

  final TestTextInput _testTextInput = TestTextInput();

  final DataHandler _requestDataHandler;
  final bool _silenceErrors;

  void _log(String message) {
    driverLog('FlutterDriverExtension', message);
  }

  final WidgetController _prober = LiveWidgetController(WidgetsBinding.instance);
  final Map<String, CommandHandlerCallback> _commandHandlers = <String, CommandHandlerCallback>{};
  final Map<String, CommandDeserializerCallback> _commandDeserializers = <String, CommandDeserializerCallback>{};
  final Map<String, FinderExtension> _finderExtensions = <String, FinderExtension>{};

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
      assert(WidgetsBinding.instance.isRootWidgetAttached || !command.requiresRootWidgetAttached,
          'No root widget is attached; have you remembered to call runApp()?');
      Future<Result> responseFuture = commandHandler(command);
      if (command.timeout != null)
        responseFuture = responseFuture.timeout(command.timeout);
      final Result response = await responseFuture;
      return _makeResponse(response?.toJson());
    } on TimeoutException catch (error, stackTrace) {
      final String message = 'Timeout while executing $commandKind: $error\n$stackTrace';
      _log(message);
      return _makeResponse(message, isError: true);
    } catch (error, stackTrace) {
      final String message = 'Uncaught extension error while executing $commandKind: $error\n$stackTrace';
      if (!_silenceErrors)
        _log(message);
      return _makeResponse(message, isError: true);
    }
  }

  Map<String, dynamic> _makeResponse(dynamic response, { bool isError = false }) {
    return <String, dynamic>{
      'isError': isError,
      'response': response,
    };
  }

  Future<Health> _getHealth(Command command) async => const Health(HealthStatus.ok);

  Future<LayerTree> _getLayerTree(Command command) async {
    return LayerTree(RendererBinding.instance?.renderView?.debugLayer?.toStringDeep());
  }

  Future<RenderTree> _getRenderTree(Command command) async {
    return RenderTree(RendererBinding.instance?.renderView?.toStringDeep());
  }

  // This can be used to wait for the first frame being rasterized during app launch.
  @Deprecated(
    'This method has been deprecated in favor of _waitForCondition. '
    'This feature was deprecated after v1.9.3.'
  )
  Future<Result> _waitUntilFirstFrameRasterized(Command command) async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    return null;
  }

  // Waits until at the end of a frame the provided [condition] is [true].
  Future<void> _waitUntilFrame(bool condition(), [ Completer<void> completer ]) {
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

  Finder _createBySemanticsLabelFinder(BySemanticsLabel arguments) {
    return find.byElementPredicate((Element element) {
      if (element is! RenderObjectElement) {
        return false;
      }
      final String semanticsLabel = element.renderObject?.debugSemantics?.label;
      if (semanticsLabel == null) {
        return false;
      }
      final Pattern label = arguments.label;
      return label is RegExp
          ? label.hasMatch(semanticsLabel)
          : label == semanticsLabel;
    }, description: 'widget with semantic label "${arguments.label}"');
  }

  Finder _createByValueKeyFinder(ByValueKey arguments) {
    switch (arguments.keyValueType) {
      case 'int':
        return find.byKey(ValueKey<int>(arguments.keyValue as int));
      case 'String':
        return find.byKey(ValueKey<String>(arguments.keyValue as String));
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

  Finder _createAncestorFinder(Ancestor arguments) {
    final Finder finder = find.ancestor(
      of: _createFinder(arguments.of),
      matching: _createFinder(arguments.matching),
      matchRoot: arguments.matchRoot,
    );
    return arguments.firstMatchOnly ? finder.first : finder;
  }

  Finder _createDescendantFinder(Descendant arguments) {
    final Finder finder = find.descendant(
      of: _createFinder(arguments.of),
      matching: _createFinder(arguments.matching),
      matchRoot: arguments.matchRoot,
    );
    return arguments.firstMatchOnly ? finder.first : finder;
  }

  Finder _createFinder(SerializableFinder finder) {
    switch (finder.finderType) {
      case 'ByText':
        return _createByTextFinder(finder as ByText);
      case 'ByTooltipMessage':
        return _createByTooltipMessageFinder(finder as ByTooltipMessage);
      case 'BySemanticsLabel':
        return _createBySemanticsLabelFinder(finder as BySemanticsLabel);
      case 'ByValueKey':
        return _createByValueKeyFinder(finder as ByValueKey);
      case 'ByType':
        return _createByTypeFinder(finder as ByType);
      case 'PageBack':
        return _createPageBackFinder();
      case 'Ancestor':
        return _createAncestorFinder(finder as Ancestor);
      case 'Descendant':
        return _createDescendantFinder(finder as Descendant);
      default:
        if (_finderExtensions.containsKey(finder.finderType)) {
          return _finderExtensions[finder.finderType].createFinder(finder);
        } else {
          throw 'Unsupported finder type: ${finder.finderType}';
        }
    }
  }

  Future<TapResult> _tap(Command command) async {
    final Tap tapCommand = command as Tap;
    final Finder computedFinder = await _waitForElement(
      _createFinder(tapCommand.finder).hitTestable()
    );
    await _prober.tap(computedFinder);
    return const TapResult();
  }

  Future<WaitForResult> _waitFor(Command command) async {
    final WaitFor waitForCommand = command as WaitFor;
    await _waitForElement(_createFinder(waitForCommand.finder));
    return const WaitForResult();
  }

  Future<WaitForAbsentResult> _waitForAbsent(Command command) async {
    final WaitForAbsent waitForAbsentCommand = command as WaitForAbsent;
    await _waitForAbsentElement(_createFinder(waitForAbsentCommand.finder));
    return const WaitForAbsentResult();
  }

  Future<Result> _waitForCondition(Command command) async {
    assert(command != null);
    final WaitForCondition waitForConditionCommand = command as WaitForCondition;
    final WaitCondition condition = deserializeCondition(waitForConditionCommand.condition);
    await condition.wait();
    return null;
  }

  @Deprecated(
    'This method has been deprecated in favor of _waitForCondition. '
    'This feature was deprecated after v1.9.3.'
  )
  Future<Result> _waitUntilNoTransientCallbacks(Command command) async {
    if (SchedulerBinding.instance.transientCallbackCount != 0)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);
    return null;
  }

  /// Returns a future that waits until no pending frame is scheduled (frame is synced).
  ///
  /// Specifically, it checks:
  /// * Whether the count of transient callbacks is zero.
  /// * Whether there's no pending request for scheduling a new frame.
  ///
  /// We consider the frame is synced when both conditions are met.
  ///
  /// This method relies on a Flutter Driver mechanism called "frame sync",
  /// which waits for transient animations to finish. Persistent animations will
  /// cause this to wait forever.
  ///
  /// If a test needs to interact with the app while animations are running, it
  /// should avoid this method and instead disable the frame sync using
  /// `set_frame_sync` method. See [FlutterDriver.runUnsynchronized] for more
  /// details on how to do this. Note, disabling frame sync will require the
  /// test author to use some other method to avoid flakiness.
  ///
  /// This method has been deprecated in favor of [_waitForCondition].
  @Deprecated(
    'This method has been deprecated in favor of _waitForCondition. '
    'This feature was deprecated after v1.9.3.'
  )
  Future<Result> _waitUntilNoPendingFrame(Command command) async {
    await _waitUntilFrame(() {
      return SchedulerBinding.instance.transientCallbackCount == 0
          && !SchedulerBinding.instance.hasScheduledFrame;
    });
    return null;
  }

  Future<GetSemanticsIdResult> _getSemanticsId(Command command) async {
    final GetSemanticsId semanticsCommand = command as GetSemanticsId;
    final Finder target = await _waitForElement(_createFinder(semanticsCommand.finder));
    final Iterable<Element> elements = target.evaluate();
    if (elements.length > 1) {
      throw StateError('Found more than one element with the same ID: $elements');
    }
    final Element element = elements.single;
    RenderObject renderObject = element.renderObject;
    SemanticsNode node;
    while (renderObject != null && node == null) {
      node = renderObject.debugSemantics;
      renderObject = renderObject.parent as RenderObject;
    }
    if (node == null)
      throw StateError('No semantics data found');
    return GetSemanticsIdResult(node.id);
  }

  Future<GetOffsetResult> _getOffset(Command command) async {
    final GetOffset getOffsetCommand = command as GetOffset;
    final Finder finder = await _waitForElement(_createFinder(getOffsetCommand.finder));
    final Element element = finder.evaluate().single;
    final RenderBox box = element.renderObject as RenderBox;
    Offset localPoint;
    switch (getOffsetCommand.offsetType) {
      case OffsetType.topLeft:
        localPoint = Offset.zero;
        break;
      case OffsetType.topRight:
        localPoint = box.size.topRight(Offset.zero);
        break;
      case OffsetType.bottomLeft:
        localPoint = box.size.bottomLeft(Offset.zero);
        break;
      case OffsetType.bottomRight:
        localPoint = box.size.bottomRight(Offset.zero);
        break;
      case OffsetType.center:
        localPoint = box.size.center(Offset.zero);
        break;
    }
    final Offset globalPoint = box.localToGlobal(localPoint);
    return GetOffsetResult(dx: globalPoint.dx, dy: globalPoint.dy);
  }

  Future<DiagnosticsTreeResult> _getDiagnosticsTree(Command command) async {
    final GetDiagnosticsTree diagnosticsCommand = command as GetDiagnosticsTree;
    final Finder finder = await _waitForElement(_createFinder(diagnosticsCommand.finder));
    final Element element = finder.evaluate().single;
    DiagnosticsNode diagnosticsNode;
    switch (diagnosticsCommand.diagnosticsType) {
      case DiagnosticsType.renderObject:
        diagnosticsNode = element.renderObject.toDiagnosticsNode();
        break;
      case DiagnosticsType.widget:
        diagnosticsNode = element.toDiagnosticsNode();
        break;
    }
    return DiagnosticsTreeResult(diagnosticsNode.toJsonMap(DiagnosticsSerializationDelegate(
      subtreeDepth: diagnosticsCommand.subtreeDepth,
      includeProperties: diagnosticsCommand.includeProperties,
    )));
  }

  Future<ScrollResult> _scroll(Command command) async {
    final Scroll scrollCommand = command as Scroll;
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

    return const ScrollResult();
  }

  Future<ScrollResult> _scrollIntoView(Command command) async {
    final ScrollIntoView scrollIntoViewCommand = command as ScrollIntoView;
    final Finder target = await _waitForElement(_createFinder(scrollIntoViewCommand.finder));
    await Scrollable.ensureVisible(target.evaluate().single, duration: const Duration(milliseconds: 100), alignment: scrollIntoViewCommand.alignment ?? 0.0);
    return const ScrollResult();
  }

  Future<GetTextResult> _getText(Command command) async {
    final GetText getTextCommand = command as GetText;
    final Finder target = await _waitForElement(_createFinder(getTextCommand.finder));

    final Widget widget = target.evaluate().single.widget;
    String text;

    if (widget.runtimeType == Text) {
      text = (widget as Text).data;
    } else if (widget.runtimeType == RichText) {
      final RichText richText = widget as RichText;
      if (richText.text.runtimeType == TextSpan) {
        text = (richText.text as TextSpan).text;
      }
    } else if (widget.runtimeType == TextField) {
      text = (widget as TextField).controller.text;
    } else if (widget.runtimeType == TextFormField) {
      text = (widget as TextFormField).controller.text;
    } else if (widget.runtimeType == EditableText) {
      text = (widget as EditableText).controller.text;
    }

    if (text == null) {
      throw UnsupportedError('Type ${widget.runtimeType.toString()} is currently not supported by getText');
    }

    return GetTextResult(text);
  }

  Future<SetTextEntryEmulationResult> _setTextEntryEmulation(Command command) async {
    final SetTextEntryEmulation setTextEntryEmulationCommand = command as SetTextEntryEmulation;
    if (setTextEntryEmulationCommand.enabled) {
      _testTextInput.register();
    } else {
      _testTextInput.unregister();
    }
    return const SetTextEntryEmulationResult();
  }

  Future<EnterTextResult> _enterText(Command command) async {
    if (!_testTextInput.isRegistered) {
      throw 'Unable to fulfill `FlutterDriver.enterText`. Text emulation is '
            'disabled. You can enable it using `FlutterDriver.setTextEntryEmulation`.';
    }
    final EnterText enterTextCommand = command as EnterText;
    _testTextInput.enterText(enterTextCommand.text);
    return const EnterTextResult();
  }

  Future<RequestDataResult> _requestData(Command command) async {
    final RequestData requestDataCommand = command as RequestData;
    return RequestDataResult(_requestDataHandler == null ? 'No requestData Extension registered' : await _requestDataHandler(requestDataCommand.message));
  }

  Future<SetFrameSyncResult> _setFrameSync(Command command) async {
    final SetFrameSync setFrameSyncCommand = command as SetFrameSync;
    _frameSync = setFrameSyncCommand.enabled;
    return const SetFrameSyncResult();
  }

  SemanticsHandle _semantics;
  bool get _semanticsIsEnabled => RendererBinding.instance.pipelineOwner.semanticsOwner != null;

  Future<SetSemanticsResult> _setSemantics(Command command) async {
    final SetSemantics setSemanticsCommand = command as SetSemantics;
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
