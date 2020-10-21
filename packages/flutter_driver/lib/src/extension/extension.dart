// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/deserialization_factory.dart';
import '../common/error.dart';
import '../common/find.dart';
import '../common/handler_factory.dart';
import '../common/message.dart';
import '_extension_io.dart' if (dart.library.html) '_extension_web.dart';

const String _extensionMethodName = 'driver';

/// Signature for the handler passed to [enableFlutterDriverExtension].
///
/// Messages are described in string form and should return a [Future] which
/// eventually completes to a string response.
typedef DataHandler = Future<String> Function(String? message);

class _DriverBinding extends BindingBase with SchedulerBinding, ServicesBinding, GestureBinding, PaintingBinding, SemanticsBinding, RendererBinding, WidgetsBinding {
  _DriverBinding(this._handler, this._silenceErrors, this.finders, this.commands);

  final DataHandler? _handler;
  final bool _silenceErrors;
  final List<FinderExtension>? finders;
  final List<CommandExtension>? commands;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    final FlutterDriverExtension extension = FlutterDriverExtension(_handler, _silenceErrors, finders: finders ?? const <FinderExtension>[], commands: commands ?? const <CommandExtension>[]);
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
/// The `finders` and `commands` parameters are optional and used to add custom
/// finders or commands, as in the following example.
///
/// ```dart main
/// void main() {
///   enableFlutterDriverExtension(
///     finders: <FinderExtension>[ SomeFinderExtension() ],
///     commands: <CommandExtension>[ SomeCommandExtension() ],
///   );
///
///   app.main();
/// }
/// ```
///
/// ```dart
/// driver.sendCommand(SomeCommand(ByValueKey('Button'), 7));
/// ```
///
/// Note: SomeFinder and SomeFinderExtension must be placed in different files
/// to avoid `dart:ui` import issue. Imports relative to `dart:ui` can't be
/// accessed from host runner, where flutter runtime is not accessible.
///
/// ```dart
/// class SomeFinder extends SerializableFinder {
///   const SomeFinder(this.title);
///
///   final String title;
///
///   @override
///   String get finderType => 'SomeFinder';
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
///  String get finderType => 'SomeFinder';
///
///  SerializableFinder deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory) {
///    return SomeFinder(json['title']);
///  }
///
///  Finder createFinder(SerializableFinder finder, CreateFinderFactory finderFactory) {
///    Some someFinder = finder as SomeFinder;
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
/// Note: SomeCommand, SomeResult and SomeCommandExtension must be placed in
/// different files to avoid `dart:ui` import issue. Imports relative to `dart:ui`
/// can't be accessed from host runner, where flutter runtime is not accessible.
///
/// ```dart
/// class SomeCommand extends CommandWithTarget {
///   SomeCommand(SerializableFinder finder, this.times, {Duration? timeout})
///       : super(finder, timeout: timeout);
///
///   SomeCommand.deserialize(Map<String, String> json, DeserializeFinderFactory finderFactory)
///       : times = int.parse(json['times']!),
///         super.deserialize(json, finderFactory);
///
///   @override
///   Map<String, String> serialize() {
///     return super.serialize()..addAll(<String, String>{'times': '$times'});
///   }
///
///   @override
///   String get kind => 'SomeCommand';
///
///   final int times;
/// }
///```
///
/// ```dart
/// class SomeCommandResult extends Result {
///   const SomeCommandResult(this.resultParam);
///
///   final String resultParam;
///
///   @override
///   Map<String, dynamic> toJson() {
///     return <String, dynamic>{
///       'resultParam': resultParam,
///     };
///   }
/// }
/// ```
///
/// ```dart
/// class SomeCommandExtension extends CommandExtension {
///   @override
///   String get commandKind => 'SomeCommand';
///
///   @override
///   Future<Result> call(Command command, WidgetController prober, CreateFinderFactory finderFactory, CommandHandlerFactory handlerFactory) async {
///     final SomeCommand someCommand = command as SomeCommand;
///
///     // Deserialize [Finder]:
///     final Finder finder = finderFactory.createFinder(stubCommand.finder);
///
///     // Wait for [Element]:
///     handlerFactory.waitForElement(finder);
///
///     // Alternatively, wait for [Element] absence:
///     handlerFactory.waitForAbsentElement(finder);
///
///     // Submit known [Command]s:
///     for (int index = 0; i < someCommand.times; index++) {
///       await handlerFactory.handleCommand(Tap(someCommand.finder), prober, finderFactory);
///     }
///
///     // Alternatively, use [WidgetController]:
///     for (int index = 0; i < stubCommand.times; index++) {
///       await prober.tap(finder);
///     }
///
///     return const SomeCommandResult('foo bar');
///   }
///
///   @override
///   Command deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory, DeserializeCommandFactory commandFactory) {
///     return SomeCommand.deserialize(params, finderFactory);
///   }
/// }
/// ```
///
void enableFlutterDriverExtension({ DataHandler? handler, bool silenceErrors = false, List<FinderExtension>? finders, List<CommandExtension>? commands}) {
  assert(WidgetsBinding.instance == null);
  _DriverBinding(handler, silenceErrors, finders ?? <FinderExtension>[], commands ?? <CommandExtension>[]);
  assert(WidgetsBinding.instance is _DriverBinding);
}

/// Signature for functions that handle a command and return a result.
typedef CommandHandlerCallback = Future<Result?> Function(Command c);

/// Signature for functions that deserialize a JSON map to a command object.
typedef CommandDeserializerCallback = Command Function(Map<String, String> params);

/// Used to expand the new [Finder].
abstract class FinderExtension {

  /// Identifies the type of finder to be used by the driver extension.
  String get finderType;

  /// Deserializes the finder from JSON generated by [SerializableFinder.serialize].
  ///
  /// Use [finderFactory] to deserialize nested [Finder]s.
  ///
  /// See also:
  ///   * [Ancestor], a finder that uses other [Finder]s as parameters.
  SerializableFinder deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory);

  /// Signature for functions that run the given finder and return the [Element]
  /// found, if any, or null otherwise.
  ///
  /// Call [finderFactory] to create known, nested [Finder]s from [SerializableFinder]s.
  Finder createFinder(SerializableFinder finder, CreateFinderFactory finderFactory);
}

/// Used to expand the new [Command].
///
/// See also:
///   * [CommandWithTarget], a base class for [Command]s with [Finder]s.
abstract class CommandExtension {

  /// Identifies the type of command to be used by the driver extension.
  String get commandKind;

  /// Deserializes the command from JSON generated by [Command.serialize].
  ///
  /// Use [finderFactory] to deserialize nested [Finder]s.
  /// Usually used for [CommandWithTarget]s.
  ///
  /// Call [commandFactory] to deserialize commands specified as parameters.
  ///
  /// See also:
  ///   * [CommandWithTarget], a base class for commands with target finders.
  ///   * [Tap], a command that uses [Finder]s as parameter.
  Command deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory, DeserializeCommandFactory commandFactory);

  /// Calls action for given [command].
  /// Returns action [Result].
  /// Invoke [prober] functions to perform widget actions.
  /// Use [finderFactory] to create [Finder]s from [SerializableFinder].
  /// Call [handlerFactory] to invoke other [Command]s or [CommandWithTarget]s.
  ///
  /// The following example shows invoking nested command with [handlerFactory].
  ///
  /// ```dart
  /// @override
  /// Future<Result> call(Command command, WidgetController prober, CreateFinderFactory finderFactory, CommandHandlerFactory handlerFactory) async {
  ///   final StubNestedCommand stubCommand = command as StubNestedCommand;
  ///   for (int index = 0; i < stubCommand.times; index++) {
  ///     await handlerFactory.handleCommand(Tap(stubCommand.finder), prober, finderFactory);
  ///   }
  ///   return const StubCommandResult('stub response');
  /// }
  /// ```
  ///
  /// Check the example below for direct [WidgetController] usage with [prober]:
  ///
  /// ```dart
  ///   @override
  /// Future<Result> call(Command command, WidgetController prober, CreateFinderFactory finderFactory, CommandHandlerFactory handlerFactory) async {
  ///   final StubProberCommand stubCommand = command as StubProberCommand;
  ///   for (int index = 0; i < stubCommand.times; index++) {
  ///     await prober.tap(finderFactory.createFinder(stubCommand.finder));
  ///   }
  ///   return const StubCommandResult('stub response');
  /// }
  /// ```
  Future<Result> call(Command command, WidgetController prober, CreateFinderFactory finderFactory, CommandHandlerFactory handlerFactory);
}

/// The class that manages communication between a Flutter Driver test and the
/// application being remote-controlled, on the application side.
///
/// This is not normally used directly. It is instantiated automatically when
/// calling [enableFlutterDriverExtension].
@visibleForTesting
class FlutterDriverExtension with DeserializeFinderFactory, CreateFinderFactory, DeserializeCommandFactory, CommandHandlerFactory {
  /// Creates an object to manage a Flutter Driver connection.
  FlutterDriverExtension(
    this._requestDataHandler,
    this._silenceErrors, {
    List<FinderExtension> finders = const <FinderExtension>[],
    List<CommandExtension> commands = const <CommandExtension>[],
  }) : assert(finders != null) {
<<<<<<< HEAD
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
      'waitUntilNoTransientCallbacks': _waitForCondition,
      'waitUntilNoPendingFrame': _waitForCondition,
      'waitUntilFirstFrameRasterized': _waitForCondition,
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
      'waitUntilNoTransientCallbacks': (Map<String, String> params) => WaitForCondition.deserialize(params),
      'waitUntilNoPendingFrame': (Map<String, String> params) => WaitForCondition.deserialize(params),
      'waitUntilFirstFrameRasterized': (Map<String, String> params) => WaitForCondition.deserialize(params),
      'get_semantics_id': (Map<String, String> params) => GetSemanticsId.deserialize(params, this),
      'get_offset': (Map<String, String> params) => GetOffset.deserialize(params, this),
      'get_diagnostics_tree': (Map<String, String> params) => GetDiagnosticsTree.deserialize(params, this),
    });
=======
    registerTextInput();
>>>>>>> 42f3709a5a1532f84a2fbcf229927666b6b4e284

    for(final FinderExtension finder in finders) {
      _finderExtensions[finder.finderType] = finder;
    }

    for(final CommandExtension command in commands) {
      _commandExtensions[command.commandKind] = command;
    }
  }

  final WidgetController _prober = LiveWidgetController(WidgetsBinding.instance!);

  final DataHandler? _requestDataHandler;

  final bool _silenceErrors;

  void _log(String message) {
    driverLog('FlutterDriverExtension', message);
  }

  final Map<String, FinderExtension> _finderExtensions = <String, FinderExtension>{};
  final Map<String, CommandExtension> _commandExtensions = <String, CommandExtension>{};

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
    final String commandKind = params['command']!;
    try {
      final Command command = deserializeCommand(params, this);
      assert(WidgetsBinding.instance!.isRootWidgetAttached || !command.requiresRootWidgetAttached,
          'No root widget is attached; have you remembered to call runApp()?');
      Future<Result?> responseFuture = handleCommand(command, _prober, this);
      if (command.timeout != null)
        responseFuture = responseFuture.timeout(command.timeout ?? Duration.zero);
      final Result? response = await responseFuture;
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

<<<<<<< HEAD
  Future<Health> _getHealth(Command command) async => const Health(HealthStatus.ok);

  Future<LayerTree> _getLayerTree(Command command) async {
    return LayerTree(RendererBinding.instance?.renderView.debugLayer?.toStringDeep());
  }

  Future<RenderTree> _getRenderTree(Command command) async {
    return RenderTree(RendererBinding.instance?.renderView.toStringDeep());
  }

  // Waits until at the end of a frame the provided [condition] is [true].
  Future<void> _waitUntilFrame(bool condition(), [ Completer<void>? completer ]) {
    completer ??= Completer<void>();
    if (!condition()) {
      SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
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
      await _waitUntilFrame(() => SchedulerBinding.instance!.transientCallbackCount == 0);

    await _waitUntilFrame(() => finder.evaluate().isNotEmpty);

    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance!.transientCallbackCount == 0);

    return finder;
  }

  /// Runs `finder` repeatedly until it finds zero [Element]s.
  Future<Finder> _waitForAbsentElement(Finder finder) async {
    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance!.transientCallbackCount == 0);

    await _waitUntilFrame(() => finder.evaluate().isEmpty);

    if (_frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance!.transientCallbackCount == 0);

    return finder;
  }

=======
>>>>>>> 42f3709a5a1532f84a2fbcf229927666b6b4e284
  @override
  SerializableFinder deserializeFinder(Map<String, String> json) {
    final String? finderType = json['finderType'];
    if (_finderExtensions.containsKey(finderType)) {
      return _finderExtensions[finderType]!.deserialize(json, this);
    }

    return super.deserializeFinder(json);
  }

  @override
  Finder createFinder(SerializableFinder finder) {
    final String finderType = finder.finderType;
    if (_finderExtensions.containsKey(finderType)) {
      return _finderExtensions[finderType]!.createFinder(finder, this);
    }

    return super.createFinder(finder);
  }

<<<<<<< HEAD
  Future<TapResult> _tap(Command command) async {
    final Tap tapCommand = command as Tap;
    final Finder computedFinder = await _waitForElement(
      createFinder(tapCommand.finder).hitTestable()
    );
    await _prober.tap(computedFinder);
    return const TapResult();
  }

  Future<WaitForResult> _waitFor(Command command) async {
    final WaitFor waitForCommand = command as WaitFor;
    await _waitForElement(createFinder(waitForCommand.finder));
    return const WaitForResult();
  }

  Future<WaitForAbsentResult> _waitForAbsent(Command command) async {
    final WaitForAbsent waitForAbsentCommand = command as WaitForAbsent;
    await _waitForAbsentElement(createFinder(waitForAbsentCommand.finder));
    return const WaitForAbsentResult();
  }

  Future<Result?> _waitForCondition(Command command) async {
    assert(command != null);
    final WaitForCondition waitForConditionCommand = command as WaitForCondition;
    final WaitCondition condition = deserializeCondition(waitForConditionCommand.condition);
    await condition.wait();
    return null;
  }

  Future<GetSemanticsIdResult> _getSemanticsId(Command command) async {
    final GetSemanticsId semanticsCommand = command as GetSemanticsId;
    final Finder target = await _waitForElement(createFinder(semanticsCommand.finder));
    final Iterable<Element> elements = target.evaluate();
    if (elements.length > 1) {
      throw StateError('Found more than one element with the same ID: $elements');
    }
    final Element element = elements.single;
    RenderObject? renderObject = element.renderObject;
    SemanticsNode? node;
    while (renderObject != null && node == null) {
      node = renderObject.debugSemantics;
      renderObject = renderObject.parent as RenderObject?;
    }
    if (node == null)
      throw StateError('No semantics data found');
    return GetSemanticsIdResult(node.id);
  }

  Future<GetOffsetResult> _getOffset(Command command) async {
    final GetOffset getOffsetCommand = command as GetOffset;
    final Finder finder = await _waitForElement(createFinder(getOffsetCommand.finder));
    final Element element = finder.evaluate().single;
    final RenderBox box = (element.renderObject as RenderBox?)!;
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
    final Finder finder = await _waitForElement(createFinder(diagnosticsCommand.finder));
    final Element element = finder.evaluate().single;
    DiagnosticsNode diagnosticsNode;
    switch (diagnosticsCommand.diagnosticsType) {
      case DiagnosticsType.renderObject:
        diagnosticsNode = element.renderObject!.toDiagnosticsNode();
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
    final Finder target = await _waitForElement(createFinder(scrollCommand.finder));
    final int totalMoves = scrollCommand.duration.inMicroseconds * scrollCommand.frequency ~/ Duration.microsecondsPerSecond;
    final Offset delta = Offset(scrollCommand.dx, scrollCommand.dy) / totalMoves.toDouble();
    final Duration pause = scrollCommand.duration ~/ totalMoves;
    final Offset startLocation = _prober.getCenter(target);
    Offset currentLocation = startLocation;
    final TestPointer pointer = TestPointer(1);
    _prober.binding.handlePointerEvent(pointer.down(startLocation));
    await Future<void>.value(); // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves += 1) {
      currentLocation = currentLocation + delta;
      _prober.binding.handlePointerEvent(pointer.move(currentLocation));
      await Future<void>.delayed(pause);
    }
    _prober.binding.handlePointerEvent(pointer.up());

    return const ScrollResult();
  }

  Future<ScrollResult> _scrollIntoView(Command command) async {
    final ScrollIntoView scrollIntoViewCommand = command as ScrollIntoView;
    final Finder target = await _waitForElement(createFinder(scrollIntoViewCommand.finder));
    await Scrollable.ensureVisible(target.evaluate().single, duration: const Duration(milliseconds: 100), alignment: scrollIntoViewCommand.alignment);
    return const ScrollResult();
  }

  Future<GetTextResult> _getText(Command command) async {
    final GetText getTextCommand = command as GetText;
    final Finder target = await _waitForElement(createFinder(getTextCommand.finder));

    final Widget widget = target.evaluate().single.widget;
    String? text;

    if (widget.runtimeType == Text) {
      text = (widget as Text).data;
    } else if (widget.runtimeType == RichText) {
      final RichText richText = widget as RichText;
      if (richText.text.runtimeType == TextSpan) {
        text = (richText.text as TextSpan).text;
      }
    } else if (widget.runtimeType == TextField) {
      text = (widget as TextField).controller?.text;
    } else if (widget.runtimeType == TextFormField) {
      text = (widget as TextFormField).controller?.text;
    } else if (widget.runtimeType == EditableText) {
      text = (widget as EditableText).controller.text;
    }

    if (text == null) {
      throw UnsupportedError('Type ${widget.runtimeType.toString()} is currently not supported by getText');
=======
  @override
  Command deserializeCommand(Map<String, String> params, DeserializeFinderFactory finderFactory) {
    final String? kind = params['command'];
    if(_commandExtensions.containsKey(kind)) {
      return _commandExtensions[kind]!.deserialize(params, finderFactory, this);
>>>>>>> 42f3709a5a1532f84a2fbcf229927666b6b4e284
    }

    return super.deserializeCommand(params, finderFactory);
  }

  @override
  @protected
  DataHandler? getDataHandler() {
    return _requestDataHandler;
  }

  @override
  Future<Result?> handleCommand(Command command, WidgetController prober, CreateFinderFactory finderFactory) {
    final String kind = command.kind;
    if(_commandExtensions.containsKey(kind)) {
      return _commandExtensions[kind]!.call(command, prober, finderFactory, this);
    }

    return super.handleCommand(command, prober, finderFactory);
  }
}
