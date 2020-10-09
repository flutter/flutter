// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
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
///  Finder createFinder(SerializableFinder finder, CreateFinderFactory finderFactory) {
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
void enableFlutterDriverExtension({ DataHandler? handler, bool silenceErrors = false, List<FinderExtension>? finders, List<CommandExtension>? commands}) {
  assert(WidgetsBinding.instance == null);
  _DriverBinding(handler, silenceErrors, finders ?? <FinderExtension>[], commands ?? <CommandExtension>[]);
  assert(WidgetsBinding.instance is _DriverBinding);
}

/// Signature for functions that handle a command and return a result.
typedef CommandHandlerCallback = Future<Result?> Function(Command c);

/// Signature for functions that deserialize a JSON map to a command object.
typedef CommandDeserializerCallback = Command Function(Map<String, String> params);

/// Used to expand the new Finder
abstract class FinderExtension {

  /// Identifies the type of finder to be used by the driver extension.
  String get finderType;

  /// Deserializes the finder from JSON generated by [SerializableFinder.serialize].
  /// [finderFactory] could be used to deserialize nested finders.
  SerializableFinder deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory);

  /// Signature for functions that run the given finder and return the [Element]
  /// found, if any, or null otherwise.
  /// [finderFactory] could be used to create nested finders.
  Finder createFinder(SerializableFinder finder, CreateFinderFactory finderFactory);
}

/// Used to expand the new Command
abstract class CommandExtension {

  /// Identifies the type of command to be used by the driver extension.
  String get commandKind;

  /// Deserializes the command from JSON generated by [Command.serialize].
  /// [finderFactory] could be used to deserialize nested finders.
  Command deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory);
  
  /// Calls action for given [command].
  /// Returns action [Result].
  Future<Result> call(Command command);
}

/// The class that manages communication between a Flutter Driver test and the
/// application being remote-controlled, on the application side.
///
/// This is not normally used directly. It is instantiated automatically when
/// calling [enableFlutterDriverExtension].
@visibleForTesting
class FlutterDriverExtension with DeserializeFinderFactory, CreateFinderFactory, CommandDeserializerFactory, CommandHandlerFactory {
  /// Creates an object to manage a Flutter Driver connection.
  FlutterDriverExtension(
    this._requestDataHandler,
    this._silenceErrors, {
    List<FinderExtension> finders = const <FinderExtension>[],
    List<CommandExtension> commands = const <CommandExtension>[],
  }) : assert(finders != null) {
    _testTextInput.register();

    for(final FinderExtension finder in finders) {
      _finderExtensions[finder.finderType] = finder;
    }

    for(final CommandExtension command in commands) {
      _commandExtensions[command.commandKind] = command;
    }
  }

  final TestTextInput _testTextInput = TestTextInput();

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
      Future<Result?> responseFuture = handleCommand(command);
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
    if (_finderExtensions.containsKey(finder.finderType)) {
      return _finderExtensions[finder.finderType]!.createFinder(finder, this);
    }

    return super.createFinder(finder);
  }

  @override
  Command deserializeCommand(Map<String, String> params, DeserializeFinderFactory finderFactory) {
    final String? kind = params['command'];
    if(_commandExtensions.containsKey(kind)) {
      return _commandExtensions[kind]!.deserialize(params, finderFactory);
    }

    return super.deserializeCommand(params, finderFactory);
  }

  @override
  Future<Result?> handleCommand(Command command) {
    final String kind = command.kind;
    if(_commandExtensions.containsKey(kind)) {
      return _commandExtensions[kind]!.call(command);
    }

    return super.handleCommand(command);
  }
}
