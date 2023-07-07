// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Contains hard-coded test data usable for tests.
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

// ignore_for_file: prefer_single_quotes

/// Stack frames as they would be in a Chrome 'Debugger.paused' event.
///
/// This is taken from a real run, but truncated to two levels of scope and one
/// level of stack.
List<WipCallFrame> frames1 =
    frames1Json.map((json) => WipCallFrame(json)).toList();

List<Map<String, dynamic>> frames1Json = [
  {
    "callFrameId": "{\"ordinal\":0,\"injectedScriptId\":2}",
    "functionName": "",
    "functionLocation": {
      "scriptId": "69",
      "lineNumber": 88,
      "columnNumber": 72
    },
    "location": {"scriptId": "69", "lineNumber": 37, "columnNumber": 0},
    "url": "http://127.0.0.1:8081/foo.ddc.js",
    "scopeChain": [
      {
        "type": "local",
        "object": {
          "type": "object",
          "className": "Object",
          "description": "Object",
          "objectId": "{\"injectedScriptId\":2,\"id\":3}"
        },
        "startLocation": {
          "scriptId": "69",
          "lineNumber": 88,
          "columnNumber": 72
        },
        "endLocation": {"scriptId": "69", "lineNumber": 93, "columnNumber": 7}
      },
      {
        "type": "closure",
        "object": {
          "type": "object",
          "className": "Object",
          "description": "Object",
          "objectId": "{\"injectedScriptId\":2,\"id\":4}"
        },
        "name": "main",
        "startLocation": {
          "scriptId": "69",
          "lineNumber": 74,
          "columnNumber": 48
        },
        "endLocation": {"scriptId": "69", "lineNumber": 100, "columnNumber": 5}
      },
      {
        "type": "closure",
        "name": "load__some_module",
        "object": {
          "type": "object",
          "className": "Object",
          "description": "Object",
          "objectId": "{\"injectedScriptId\":2,\"id\":5}"
        },
        "startLocation": {
          "scriptId": "69",
          "lineNumber": 0,
          "columnNumber": 29
        },
        "endLocation": {"scriptId": "69", "lineNumber": 126, "columnNumber": 1}
      },
      {
        "type": "global",
        "object": {
          "type": "object",
          "className": "Window",
          "description": "Window",
          "objectId": "{\"injectedScriptId\":2,\"id\":6}"
        }
      }
    ],
    "this": {"type": "undefined"},
  }
];

/// Data in the form returned from getProperties called twice on successive
/// elements of a scope chain.
///
/// It has two variables named 'a' and 'b' in the first scope.
var variables1 = [
  WipResponse({
    'id': 1,
    'result': {'result': []}
  }),
  WipResponse({
    'id': 2,
    'result': {
      'result': [
        {
          'name': 'a',
          'value': {'type': 'string', 'value': 'foo'}
        },
        {
          'name': 'b',
          'value': {'type': 'string', 'value': 'bar'}
        }
      ]
    }
  }),
  WipResponse({
    'id': 3,
    'result': {'result': []}
  }),
  // Fake that the SDK is loaded.
  WipResponse({
    'id': 4,
    'result': {
      'result': [
        {'name': 'dart', 'value': null},
        {'name': 'core', 'value': null}
      ]
    }
  }),
  WipResponse({
    'id': 5,
    'result': {'result': []}
  }),
  WipResponse({
    'id': 6,
    'result': {'result': []}
  }),
];

/// Sample data for a Debugger.scriptParsed event
var scriptParsedParams = {
  "endColumn": 0,
  "endLine": 53,
  "executionContextAuxData": {
    "frameId": "75DC0B9DAB420DD67036D4560E614998",
    "isDefault": true,
    "type": "default"
  },
  "executionContextId": 7,
  "hasSourceURL": false,
  "hash": "1b7029ad6e8a77da7fe7c0741479c0394f01b0f9",
  "isLiveEdit": false,
  "isModule": false,
  "length": 2732,
  "scriptId": "146",
  "sourceMapURL": "main.ddc.js.map",
  "startColumn": 0,
  "startLine": 0,
  "url": "http://localhost:8080/main.ddc.js"
};
