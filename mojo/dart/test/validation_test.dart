// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:mojo.builtin' as builtin;
import 'dart:typed_data';

import 'package:_testing/validation_test_input_parser.dart' as parser;
import 'package:mojo/bindings.dart';
import 'package:mojo/core.dart';
import 'package:mojom/mojo/test/validation_test_interfaces.mojom.dart';

class ConformanceTestInterfaceImpl implements ConformanceTestInterface {
  ConformanceTestInterfaceStub _stub;
  Completer _completer;

  ConformanceTestInterfaceImpl(
      this._completer, MojoMessagePipeEndpoint endpoint) {
    _stub = new ConformanceTestInterfaceStub.fromEndpoint(endpoint, this);
  }

  void _complete() => _completer.complete(null);

  method0(double param0) => _complete();
  method1(StructA param0) => _complete();
  method2(StructB param0, StructA param1) => _complete();
  method3(List<bool> param0) => _complete();
  method4(StructC param0, List<int> param1) => _complete();
  method5(StructE param0, MojoDataPipeProducer param1) {
    param1.handle.close();
    param0.dataPipeConsumer.handle.close();
    param0.structD.messagePipes.forEach((h) => h.close());
    _complete();
  }
  method6(List<List<int>> param0) => _complete();
  method7(StructF param0, List<List<int>> param1) => _complete();
  method8(List<List<String>> param0) => _complete();
  method9(List<List<MojoHandle>> param0) {
    if (param0 != null) {
      param0.forEach((l) => l.forEach((h) {
        if (h != null) h.close();
      }));
    }
    _complete();
  }
  method10(Map<String, int> param0) => _complete();
  method11(StructG param0) => _complete();
  method12(double param0, [Function responseFactory]) {
    // If there are ever any passing method12 tests added, then this may need
    // to change.
    assert(responseFactory != null);
    _complete();
    return new Future.value(responseFactory(0.0));
  }
  method13(InterfaceAProxy param0, int param1, InterfaceAProxy param2) {
    if (param0 != null) param0.close(immediate: true);
    if (param2 != null) param2.close(immediate: true);
    _complete();
  }

  Future close({bool immediate: false}) => _stub.close(immediate: immediate);
}

parser.ValidationParseResult readAndParseTest(String test) {
  List<int> data = builtin.readSync("${test}.data");
  String input = new Utf8Decoder().convert(data).trim();
  return parser.parse(input);
}

String expectedResult(String test) {
  List<int> data = builtin.readSync("${test}.expected");
  return new Utf8Decoder().convert(data).trim();
}

Future runTest(
    String name, parser.ValidationParseResult test, String expected) {
  var handles = new List.generate(
      test.numHandles, (_) => new MojoSharedBuffer.create(10).handle);
  var pipe = new MojoMessagePipe();
  var completer = new Completer();
  var conformanceImpl;

  runZoned(() {
    conformanceImpl =
        new ConformanceTestInterfaceImpl(completer, pipe.endpoints[0]);
  }, onError: (e, stackTrace) {
    assert(e is MojoCodecError);
    // TODO(zra): Make the error messages conform?
    // assert(e == expected);
    conformanceImpl.close(immediate: true);
    pipe.endpoints[0].close();
    pipe.endpoints[1].close();
    handles.forEach((h) => h.close());
    completer.completeError(null);
  });

  var length = (test.data == null) ? 0 : test.data.lengthInBytes;
  var r = pipe.endpoints[1].write(test.data, length, handles);
  assert(r.isOk);

  return completer.future.then((_) {
    assert(expected == "PASS");
    conformanceImpl.close();
    pipe.endpoints[0].close();
    pipe.endpoints[1].close();
    handles.forEach((h) => h.close());
  }, onError: (e) {
    // Do nothing.
  });
}

Iterable<String> getTestFiles(String path, String prefix) => builtin
    .enumerateFiles(path)
    .where((s) => s.startsWith(prefix) && s.endsWith(".data"))
    .map((s) => s.replaceFirst('.data', ''));

main(List args) {
  int handle = args[0];
  String path = args[1];

  // First test the parser.
  parser.parserTests();

  // Then run the conformance tests.
  var futures = getTestFiles(path, "$path/conformance_").map((test) {
    return runTest(test, readAndParseTest(test), expectedResult(test));
  });
  Future.wait(futures).then((_) {
    assert(MojoHandle.reportLeakedHandles());
  }, onError: (e) {
    assert(MojoHandle.reportLeakedHandles());
  });
  // TODO(zra): Add integration tests when they no longer rely on Client=.
}
