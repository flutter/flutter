// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.import 'dart:async';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../../loaders/strategy.dart';
import '../../utilities/shared.dart';
import '../remote_debugger.dart';

/// Meta data for a remote Dart function in Chrome.
class FunctionMetaData {
  final String name;
  FunctionMetaData(this.name);

  /// Returns the [FunctionMetaData] for the Chrome [remoteObject].
  static Future<FunctionMetaData> metaDataFor(
      RemoteDebugger remoteDebugger, RemoteObject remoteObject) async {
    final evalExpression = '''
      function(remoteObject) {
        var sdkUtils = ${globalLoadStrategy.loadModuleSnippet}('dart_sdk').dart;
        var name = remoteObject.name;
        if(remoteObject._boundObject) {
         name = sdkUtils.getType(remoteObject._boundObject).name +
                 '.' + remoteObject._boundMethod.name;
        }
        return name;
      }
    ''';
    final arguments = [
      {'objectId': remoteObject.objectId}
    ];
    final response =
        await remoteDebugger.sendCommand('Runtime.callFunctionOn', params: {
      'functionDeclaration': evalExpression,
      'arguments': arguments,
      'objectId': remoteObject.objectId,
      'returnByValue': true,
    });
    handleErrorIfPresent(
      response,
      evalContents: evalExpression,
    );
    final name = response.result?['result']?['value'] as String?;
    if (name == null) return FunctionMetaData('<unknown>');
    if (name.isEmpty) return FunctionMetaData('Closure');
    return FunctionMetaData(name);
  }
}
