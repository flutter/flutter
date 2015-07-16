// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Mock out the support module to avoid depending on the message loop.
define("mojo/public/js/support", ["timer"], function(timer) {
  var waitingCallbacks = [];

  function WaitCookie(id) {
    this.id = id;
  }

  function asyncWait(handle, flags, callback) {
    var id = waitingCallbacks.length;
    waitingCallbacks.push(callback);
    return new WaitCookie(id);
  }

  function cancelWait(cookie) {
    waitingCallbacks[cookie.id] = null;
  }

  function numberOfWaitingCallbacks() {
    var count = 0;
    for (var i = 0; i < waitingCallbacks.length; ++i) {
      if (waitingCallbacks[i])
        ++count;
    }
    return count;
  }

  function pumpOnce(result) {
    var callbacks = waitingCallbacks;
    waitingCallbacks = [];
    for (var i = 0; i < callbacks.length; ++i) {
      if (callbacks[i])
        callbacks[i](result);
    }
  }

  // Queue up a pumpOnce call to execute after the stack unwinds. Use
  // this to trigger a pump after all Promises are executed.
  function queuePump(result) {
    timer.createOneShot(0, pumpOnce.bind(undefined, result));
  }

  var exports = {};
  exports.asyncWait = asyncWait;
  exports.cancelWait = cancelWait;
  exports.numberOfWaitingCallbacks = numberOfWaitingCallbacks;
  exports.pumpOnce = pumpOnce;
  exports.queuePump = queuePump;
  return exports;
});

define([
    "gin/test/expect",
    "mojo/public/js/support",
    "mojo/public/js/core",
    "mojo/public/js/connection",
    "mojo/public/interfaces/bindings/tests/sample_interfaces.mojom",
    "mojo/public/interfaces/bindings/tests/sample_service.mojom",
    "mojo/public/js/threading",
    "gc",
], function(expect,
            mockSupport,
            core,
            connection,
            sample_interfaces,
            sample_service,
            threading,
            gc) {
  testClientServer();
  testWriteToClosedPipe();
  testRequestResponse().then(function() {
    this.result = "PASS";
    gc.collectGarbage();  // should not crash
    threading.quit();
  }.bind(this)).catch(function(e) {
    this.result = "FAIL: " + (e.stack || e);
    threading.quit();
  }.bind(this));

  function createPeerConnection(handle, stubClass, proxyClass) {
    var c = new connection.Connection(handle, stubClass, proxyClass);
    if (c.local)
      c.local.peer = c.remote;
    if (c.remote)
      c.remote.peer = c.local;
    return c;
  }

  function testClientServer() {
    var receivedFrobinate = false;

    // ServiceImpl ------------------------------------------------------------

    function ServiceImpl() {
    }

    ServiceImpl.prototype = Object.create(
        sample_service.Service.stubClass.prototype);

    ServiceImpl.prototype.frobinate = function(foo, baz, port) {
      receivedFrobinate = true;

      expect(foo.name).toBe("Example name");
      expect(baz).toBeTruthy();
      expect(core.close(port)).toBe(core.RESULT_OK);

      return Promise.resolve(42);
    };

    var pipe = core.createMessagePipe();
    var anotherPipe = core.createMessagePipe();
    var sourcePipe = core.createMessagePipe();

    var connection0 = createPeerConnection(
        pipe.handle0, ServiceImpl);

    var connection1 = createPeerConnection(
        pipe.handle1, undefined, sample_service.Service.proxyClass);

    var foo = new sample_service.Foo();
    foo.bar = new sample_service.Bar();
    foo.name = "Example name";
    foo.source = sourcePipe.handle0;
    connection1.remote.frobinate(foo, true, anotherPipe.handle0);

    mockSupport.pumpOnce(core.RESULT_OK);

    expect(receivedFrobinate).toBeTruthy();

    connection0.close();
    connection1.close();

    expect(mockSupport.numberOfWaitingCallbacks()).toBe(0);

    // sourcePipe.handle0 was closed automatically when sent over IPC.
    expect(core.close(sourcePipe.handle0)).toBe(core.RESULT_INVALID_ARGUMENT);
    // sourcePipe.handle1 hasn't been closed yet.
    expect(core.close(sourcePipe.handle1)).toBe(core.RESULT_OK);

    // anotherPipe.handle0 was closed automatically when sent over IPC.
    expect(core.close(anotherPipe.handle0)).toBe(core.RESULT_INVALID_ARGUMENT);
    // anotherPipe.handle1 hasn't been closed yet.
    expect(core.close(anotherPipe.handle1)).toBe(core.RESULT_OK);

    // The Connection object is responsible for closing these handles.
    expect(core.close(pipe.handle0)).toBe(core.RESULT_INVALID_ARGUMENT);
    expect(core.close(pipe.handle1)).toBe(core.RESULT_INVALID_ARGUMENT);
  }

  function testWriteToClosedPipe() {
    var pipe = core.createMessagePipe();

    var connection1 = createPeerConnection(
        pipe.handle1, function() {}, sample_service.Service.proxyClass);

    // Close the other end of the pipe.
    core.close(pipe.handle0);

    // Not observed yet because we haven't pumped events yet.
    expect(connection1.encounteredError()).toBeFalsy();

    var foo = new sample_service.Foo();
    foo.bar = new sample_service.Bar();
    connection1.remote.frobinate(null, true, null);

    // Write failures are not reported.
    expect(connection1.encounteredError()).toBeFalsy();

    // Pump events, and then we should start observing the closed pipe.
    mockSupport.pumpOnce(core.RESULT_OK);

    expect(connection1.encounteredError()).toBeTruthy();

    connection1.close();
  }

  function testRequestResponse() {

    // ProviderImpl ------------------------------------------------------------

    function ProviderImpl() {
    }

    ProviderImpl.prototype =
        Object.create(sample_interfaces.Provider.stubClass.prototype);

    ProviderImpl.prototype.echoString = function(a) {
      mockSupport.queuePump(core.RESULT_OK);
      return Promise.resolve({a: a});
    };

    ProviderImpl.prototype.echoStrings = function(a, b) {
      mockSupport.queuePump(core.RESULT_OK);
      return Promise.resolve({a: a, b: b});
    };

    var pipe = core.createMessagePipe();

    var connection0 = createPeerConnection(
        pipe.handle0,
        ProviderImpl);

    var connection1 = createPeerConnection(
        pipe.handle1,
        undefined,
        sample_interfaces.Provider.proxyClass);

    var origReadMessage = core.readMessage;
    // echoString
    mockSupport.queuePump(core.RESULT_OK);
    return connection1.remote.echoString("hello").then(function(response) {
      expect(response.a).toBe("hello");
    }).then(function() {
      // echoStrings
      mockSupport.queuePump(core.RESULT_OK);
      return connection1.remote.echoStrings("hello", "world");
    }).then(function(response) {
      expect(response.a).toBe("hello");
      expect(response.b).toBe("world");
    }).then(function() {
      // Mock a read failure, expect it to fail.
      core.readMessage = function() {
        return { result: core.RESULT_UNKNOWN };
      };
      mockSupport.queuePump(core.RESULT_OK);
      return connection1.remote.echoString("goodbye");
    }).then(function() {
      throw Error("Expected echoString to fail.");
    }, function(error) {
      expect(error.message).toBe("Connection error: " + core.RESULT_UNKNOWN);

      // Clean up.
      core.readMessage = origReadMessage;
    });
  }
});
