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
typedef Future<R> CommandHandlerCallback<R extends Result>(Command c);

/// Deserializes JSON map to a command object.
typedef Command CommandDeserializerCallback(Map<String, String> params);

class FlutterDriverExtension {
  static final Logger _log = new Logger('FlutterDriverExtension');

  FlutterDriverExtension() {
    _commandHandlers = {
      'get_health': getHealth,
      'find': find,
      'tap': tap,
      'get_text': getText,
      'scroll': scroll,
    };

    _commandDeserializers = {
      'get_health': GetHealth.deserialize,
      'find': Find.deserialize,
      'tap': Tap.deserialize,
      'get_text': GetText.deserialize,
      'scroll': Scroll.deserialize,
    };
  }

  final Instrumentation prober = new Instrumentation();

  Map<String, CommandHandlerCallback> _commandHandlers =
      <String, CommandHandlerCallback>{};

  Map<String, CommandDeserializerCallback> _commandDeserializers =
      <String, CommandDeserializerCallback>{};

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
      }, onError: (e, s) {
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

  Future<ObjectRef> find(Find command) async {
    SearchSpecification searchSpec = command.searchSpec;
    switch(searchSpec.runtimeType) {
      case ByValueKey: return findByValueKey(searchSpec);
      case ByTooltipMessage: return findByTooltipMessage(searchSpec);
      case ByText: return findByText(searchSpec);
    }
    throw new DriverError('Unsupported search specification type ${searchSpec.runtimeType}');
  }

  /// Runs object [locator] repeatedly until it returns a non-`null` value.
  ///
  /// [descriptionGetter] describes the object to be waited for. It is used in
  /// the warning printed should timeout happen.
  Future<ObjectRef> _waitForObject(String descriptionGetter(), Object locator()) async {
    Object object = await retry(locator, _kDefaultTimeout, _kDefaultPauseBetweenRetries, predicate: (object) {
      return object != null;
    }).catchError((dynamic error, stackTrace) {
      _log.warning('Timed out waiting for ${descriptionGetter()}');
      return null;
    });

    ObjectRef elemRef = object != null
      ? new ObjectRef(_registerObject(object))
      : new ObjectRef.notFound();
    return new Future.value(elemRef);
  }

  Future<ObjectRef> findByValueKey(ByValueKey byKey) async {
    return _waitForObject(
      () => 'element with key "${byKey.keyValue}" of type ${byKey.keyValueType}',
      () {
        return prober.findElementByKey(new ValueKey<dynamic>(byKey.keyValue));
      }
    );
  }

  Future<ObjectRef> findByTooltipMessage(ByTooltipMessage byTooltipMessage) async {
    return _waitForObject(
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

  Future<ObjectRef> findByText(ByText byText) async {
    return await _waitForObject(
      () => 'text "${byText.text}"',
      () {
        return prober.findText(byText.text);
      });
  }

  Future<TapResult> tap(Tap command) async {
    Element target = await _dereferenceOrDie(command.targetRef);
    prober.tap(target);
    return new TapResult();
  }

  Future<ScrollResult> scroll(Scroll command) async {
    Element target = await _dereferenceOrDie(command.targetRef);
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
    Element target = await _dereferenceOrDie(command.targetRef);
    // TODO(yjbanov): support more ways to read text
    Text text = target.widget;
    return new GetTextResult(text.data);
  }

  int _refCounter = 1;
  final Map<String, Object> _objectRefs = <String, Object>{};
  String _registerObject(Object obj) {
    if (obj == null)
      throw new ArgumentError('Cannot register null object');
    String refKey = '${_refCounter++}';
    _objectRefs[refKey] = obj;
    return refKey;
  }

  dynamic _dereference(String reference) => _objectRefs[reference];

  Future<dynamic> _dereferenceOrDie(String reference) {
    Element object = _dereference(reference);

    if (object == null)
      return new Future.error('Object reference not found ($reference).');

    return new Future.value(object);
  }
}
