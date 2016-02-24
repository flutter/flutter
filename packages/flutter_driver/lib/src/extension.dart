// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/src/instrumentation.dart';

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
      'find_by_value_key': findByValueKey,
      'tap': tap,
      'get_text': getText,
    };

    _commandDeserializers = {
      'get_health': GetHealth.fromJson,
      'find_by_value_key': FindByValueKey.fromJson,
      'tap': Tap.fromJson,
      'get_text': GetText.fromJson,
    };
  }

  final Instrumentation prober = new Instrumentation();

  Map<String, CommandHandlerCallback> _commandHandlers =
      <String, CommandHandlerCallback>{};

  Map<String, CommandDeserializerCallback> _commandDeserializers =
      <String, CommandDeserializerCallback>{};

  Future<ServiceExtensionResponse> call(Map<String, String> params) async {
    String commandKind = params['kind'];
    CommandHandlerCallback commandHandler = _commandHandlers[commandKind];
    CommandDeserializerCallback commandDeserializer =
        _commandDeserializers[commandKind];

    if (commandHandler == null || commandDeserializer == null) {
      return new ServiceExtensionResponse.error(
        ServiceExtensionResponse.kInvalidParams,
        'Extension $_extensionMethod does not support command $commandKind'
      );
    }

    Command command = commandDeserializer(params);
    return commandHandler(command).then((Result result) {
      return new ServiceExtensionResponse.result(JSON.encode(result.toJson()));
    }, onError: (e, s) {
      _log.warning('$e:\n$s');
      return new ServiceExtensionResponse.error(
        ServiceExtensionResponse.kExtensionError, '$e');
    });
  }

  Future<Health> getHealth(GetHealth command) async => new Health(HealthStatus.ok);

  Future<ObjectRef> findByValueKey(FindByValueKey command) async {
    Element elem = await retry(() {
      return prober.findElementByKey(new ValueKey<dynamic>(command.keyValue));
    }, _kDefaultTimeout, _kDefaultPauseBetweenRetries);

    ObjectRef elemRef = elem != null
      ? new ObjectRef(_registerObject(elem))
      : new ObjectRef.notFound();
    return new Future.value(elemRef);
  }

  Future<TapResult> tap(Tap command) async {
    Element target = await _dereferenceOrDie(command.targetRef);
    prober.tap(target);
    return new TapResult();
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
