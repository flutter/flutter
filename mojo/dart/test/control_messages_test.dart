// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_testing/expect.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojom/sample/sample_interfaces.mojom.dart' as sample;

// Bump this if sample_interfaces.mojom adds higher versions.
const maxVersion = 3;

// Implementation of IntegerAccessor.
class IntegerAccessorImpl implements sample.IntegerAccessor {
  // Some initial value.
  int _value = 0;

  Future<sample.IntegerAccessorGetIntegerResponseParams>
      getInteger([Function responseFactory = null]) {
    return new Future.value(responseFactory(_value, sample.Enum_VALUE));
  }

  void setInteger(int data, int type) {
    Expect.equals(sample.Enum_VALUE, type);
    // Update data.
    _value = data;
  }
}

// Returns [proxy, stub].
List buildConnectedProxyAndStub() {
  var pipe = new core.MojoMessagePipe();
  var proxy = new sample.IntegerAccessorProxy.fromEndpoint(pipe.endpoints[0]);
  var impl = new IntegerAccessorImpl();
  var stub =
      new sample.IntegerAccessorStub.fromEndpoint(pipe.endpoints[1], impl);
  return [proxy, stub];
}

void closeProxyAndStub(List ps) {
  var proxy = ps[0];
  var stub = ps[1];
  proxy.close();
  stub.close();
}

testQueryVersion() async {
  var ps = buildConnectedProxyAndStub();
  var proxy = ps[0];
  // The version starts at 0.
  Expect.equals(0, proxy.version);
  // We are talking to an implementation that supports version maxVersion.
  var providedVersion = await proxy.queryVersion();
  Expect.equals(maxVersion, providedVersion);
  // The proxy's version has been updated.
  Expect.equals(providedVersion, proxy.version);
  closeProxyAndStub(ps);
}

testRequireVersionSuccess() async {
  var ps = buildConnectedProxyAndStub();
  var proxy = ps[0];
  Expect.equals(0, proxy.version);
  // Require version maxVersion.
  proxy.requireVersion(maxVersion);
  // Make a request and get a response.
  var response = await proxy.ptr.getInteger();
  Expect.equals(0, response.data);
  closeProxyAndStub(ps);
}

testRequireVersionDisconnect() async {
  var ps = buildConnectedProxyAndStub();
  var proxy = ps[0];
  Expect.equals(0, proxy.version);
  // Require version maxVersion.
  proxy.requireVersion(maxVersion);
  Expect.equals(maxVersion, proxy.version);
  // Set integer.
  proxy.ptr.setInteger(34, sample.Enum_VALUE);
  // Get integer.
  var response = await proxy.ptr.getInteger();
  Expect.equals(34, response.data);
  // Require version maxVersion + 1
  proxy.requireVersion(maxVersion + 1);
  // Version number is updated synchronously.
  Expect.equals(maxVersion + 1, proxy.version);
  // Get integer, expect a failure.
  bool exceptionCaught = false;
  try {
    response = await proxy.ptr.getInteger();
    Expect.fail('Should have an exception.');
  } catch(e) {
    exceptionCaught = true;
  }
  Expect.isTrue(exceptionCaught);
  closeProxyAndStub(ps);
}

main() async {
  await testQueryVersion();
  await testRequireVersionSuccess();
  await testRequireVersionDisconnect();
}
