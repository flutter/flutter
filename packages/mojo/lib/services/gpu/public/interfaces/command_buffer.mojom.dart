// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library command_buffer.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/gpu/public/interfaces/gpu_capabilities.mojom.dart' as gpu_capabilities_mojom;


class CommandBufferState extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int numEntries = 0;
  int getOffset = 0;
  int putOffset = 0;
  int token = 0;
  int error = 0;
  int contextLostReason = 0;
  int generation = 0;

  CommandBufferState() : super(kStructSize);

  static CommandBufferState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferState result = new CommandBufferState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.numEntries = decoder0.decodeInt32(8);
    }
    {
      
      result.getOffset = decoder0.decodeInt32(12);
    }
    {
      
      result.putOffset = decoder0.decodeInt32(16);
    }
    {
      
      result.token = decoder0.decodeInt32(20);
    }
    {
      
      result.error = decoder0.decodeInt32(24);
    }
    {
      
      result.contextLostReason = decoder0.decodeInt32(28);
    }
    {
      
      result.generation = decoder0.decodeUint32(32);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(numEntries, 8);
    
    encoder0.encodeInt32(getOffset, 12);
    
    encoder0.encodeInt32(putOffset, 16);
    
    encoder0.encodeInt32(token, 20);
    
    encoder0.encodeInt32(error, 24);
    
    encoder0.encodeInt32(contextLostReason, 28);
    
    encoder0.encodeUint32(generation, 32);
  }

  String toString() {
    return "CommandBufferState("
           "numEntries: $numEntries" ", "
           "getOffset: $getOffset" ", "
           "putOffset: $putOffset" ", "
           "token: $token" ", "
           "error: $error" ", "
           "contextLostReason: $contextLostReason" ", "
           "generation: $generation" ")";
  }
}

class CommandBufferSyncClientDidInitializeParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool success = false;
  gpu_capabilities_mojom.GpuCapabilities capabilities = null;

  CommandBufferSyncClientDidInitializeParams() : super(kStructSize);

  static CommandBufferSyncClientDidInitializeParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferSyncClientDidInitializeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferSyncClientDidInitializeParams result = new CommandBufferSyncClientDidInitializeParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.capabilities = gpu_capabilities_mojom.GpuCapabilities.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(success, 8, 0);
    
    encoder0.encodeStruct(capabilities, 16, false);
  }

  String toString() {
    return "CommandBufferSyncClientDidInitializeParams("
           "success: $success" ", "
           "capabilities: $capabilities" ")";
  }
}

class CommandBufferSyncClientDidMakeProgressParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  CommandBufferState state = null;

  CommandBufferSyncClientDidMakeProgressParams() : super(kStructSize);

  static CommandBufferSyncClientDidMakeProgressParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferSyncClientDidMakeProgressParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferSyncClientDidMakeProgressParams result = new CommandBufferSyncClientDidMakeProgressParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.state = CommandBufferState.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(state, 8, false);
  }

  String toString() {
    return "CommandBufferSyncClientDidMakeProgressParams("
           "state: $state" ")";
  }
}

class CommandBufferSyncPointClientDidInsertSyncPointParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int syncPoint = 0;

  CommandBufferSyncPointClientDidInsertSyncPointParams() : super(kStructSize);

  static CommandBufferSyncPointClientDidInsertSyncPointParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferSyncPointClientDidInsertSyncPointParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferSyncPointClientDidInsertSyncPointParams result = new CommandBufferSyncPointClientDidInsertSyncPointParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.syncPoint = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(syncPoint, 8);
  }

  String toString() {
    return "CommandBufferSyncPointClientDidInsertSyncPointParams("
           "syncPoint: $syncPoint" ")";
  }
}

class CommandBufferLostContextObserverDidLoseContextParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int contextLostReason = 0;

  CommandBufferLostContextObserverDidLoseContextParams() : super(kStructSize);

  static CommandBufferLostContextObserverDidLoseContextParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferLostContextObserverDidLoseContextParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferLostContextObserverDidLoseContextParams result = new CommandBufferLostContextObserverDidLoseContextParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.contextLostReason = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(contextLostReason, 8);
  }

  String toString() {
    return "CommandBufferLostContextObserverDidLoseContextParams("
           "contextLostReason: $contextLostReason" ")";
  }
}

class CommandBufferInitializeParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object syncClient = null;
  Object syncPointClient = null;
  Object lostObserver = null;
  core.MojoSharedBuffer sharedState = null;

  CommandBufferInitializeParams() : super(kStructSize);

  static CommandBufferInitializeParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferInitializeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferInitializeParams result = new CommandBufferInitializeParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.syncClient = decoder0.decodeServiceInterface(8, false, CommandBufferSyncClientProxy.newFromEndpoint);
    }
    {
      
      result.syncPointClient = decoder0.decodeServiceInterface(12, false, CommandBufferSyncPointClientProxy.newFromEndpoint);
    }
    {
      
      result.lostObserver = decoder0.decodeServiceInterface(16, false, CommandBufferLostContextObserverProxy.newFromEndpoint);
    }
    {
      
      result.sharedState = decoder0.decodeSharedBufferHandle(20, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterface(syncClient, 8, false);
    
    encoder0.encodeInterface(syncPointClient, 12, false);
    
    encoder0.encodeInterface(lostObserver, 16, false);
    
    encoder0.encodeSharedBufferHandle(sharedState, 20, false);
  }

  String toString() {
    return "CommandBufferInitializeParams("
           "syncClient: $syncClient" ", "
           "syncPointClient: $syncPointClient" ", "
           "lostObserver: $lostObserver" ", "
           "sharedState: $sharedState" ")";
  }
}

class CommandBufferSetGetBufferParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int buffer = 0;

  CommandBufferSetGetBufferParams() : super(kStructSize);

  static CommandBufferSetGetBufferParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferSetGetBufferParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferSetGetBufferParams result = new CommandBufferSetGetBufferParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.buffer = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(buffer, 8);
  }

  String toString() {
    return "CommandBufferSetGetBufferParams("
           "buffer: $buffer" ")";
  }
}

class CommandBufferFlushParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int putOffset = 0;

  CommandBufferFlushParams() : super(kStructSize);

  static CommandBufferFlushParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferFlushParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferFlushParams result = new CommandBufferFlushParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.putOffset = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(putOffset, 8);
  }

  String toString() {
    return "CommandBufferFlushParams("
           "putOffset: $putOffset" ")";
  }
}

class CommandBufferMakeProgressParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int lastGetOffset = 0;

  CommandBufferMakeProgressParams() : super(kStructSize);

  static CommandBufferMakeProgressParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferMakeProgressParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferMakeProgressParams result = new CommandBufferMakeProgressParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.lastGetOffset = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(lastGetOffset, 8);
  }

  String toString() {
    return "CommandBufferMakeProgressParams("
           "lastGetOffset: $lastGetOffset" ")";
  }
}

class CommandBufferRegisterTransferBufferParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int id = 0;
  core.MojoSharedBuffer transferBuffer = null;
  int size = 0;

  CommandBufferRegisterTransferBufferParams() : super(kStructSize);

  static CommandBufferRegisterTransferBufferParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferRegisterTransferBufferParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferRegisterTransferBufferParams result = new CommandBufferRegisterTransferBufferParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.id = decoder0.decodeInt32(8);
    }
    {
      
      result.transferBuffer = decoder0.decodeSharedBufferHandle(12, false);
    }
    {
      
      result.size = decoder0.decodeUint32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(id, 8);
    
    encoder0.encodeSharedBufferHandle(transferBuffer, 12, false);
    
    encoder0.encodeUint32(size, 16);
  }

  String toString() {
    return "CommandBufferRegisterTransferBufferParams("
           "id: $id" ", "
           "transferBuffer: $transferBuffer" ", "
           "size: $size" ")";
  }
}

class CommandBufferDestroyTransferBufferParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int id = 0;

  CommandBufferDestroyTransferBufferParams() : super(kStructSize);

  static CommandBufferDestroyTransferBufferParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferDestroyTransferBufferParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferDestroyTransferBufferParams result = new CommandBufferDestroyTransferBufferParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.id = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(id, 8);
  }

  String toString() {
    return "CommandBufferDestroyTransferBufferParams("
           "id: $id" ")";
  }
}

class CommandBufferInsertSyncPointParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool retire = false;

  CommandBufferInsertSyncPointParams() : super(kStructSize);

  static CommandBufferInsertSyncPointParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferInsertSyncPointParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferInsertSyncPointParams result = new CommandBufferInsertSyncPointParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.retire = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(retire, 8, 0);
  }

  String toString() {
    return "CommandBufferInsertSyncPointParams("
           "retire: $retire" ")";
  }
}

class CommandBufferRetireSyncPointParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int syncPoint = 0;

  CommandBufferRetireSyncPointParams() : super(kStructSize);

  static CommandBufferRetireSyncPointParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferRetireSyncPointParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferRetireSyncPointParams result = new CommandBufferRetireSyncPointParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.syncPoint = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(syncPoint, 8);
  }

  String toString() {
    return "CommandBufferRetireSyncPointParams("
           "syncPoint: $syncPoint" ")";
  }
}

class CommandBufferEchoParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CommandBufferEchoParams() : super(kStructSize);

  static CommandBufferEchoParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferEchoParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferEchoParams result = new CommandBufferEchoParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "CommandBufferEchoParams("")";
  }
}

class CommandBufferEchoResponseParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CommandBufferEchoResponseParams() : super(kStructSize);

  static CommandBufferEchoResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CommandBufferEchoResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CommandBufferEchoResponseParams result = new CommandBufferEchoResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "CommandBufferEchoResponseParams("")";
  }
}
const int kCommandBufferSyncClient_didInitialize_name = 0;
const int kCommandBufferSyncClient_didMakeProgress_name = 1;

const String CommandBufferSyncClientName =
      'mojo::CommandBufferSyncClient';

abstract class CommandBufferSyncClient {
  void didInitialize(bool success, gpu_capabilities_mojom.GpuCapabilities capabilities);
  void didMakeProgress(CommandBufferState state);

}


class CommandBufferSyncClientProxyImpl extends bindings.Proxy {
  CommandBufferSyncClientProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CommandBufferSyncClientProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CommandBufferSyncClientProxyImpl.unbound() : super.unbound();

  static CommandBufferSyncClientProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferSyncClientProxyImpl.fromEndpoint(endpoint);

  String get name => CommandBufferSyncClientName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferSyncClientProxyImpl($superString)";
  }
}


class _CommandBufferSyncClientProxyCalls implements CommandBufferSyncClient {
  CommandBufferSyncClientProxyImpl _proxyImpl;

  _CommandBufferSyncClientProxyCalls(this._proxyImpl);
    void didInitialize(bool success, gpu_capabilities_mojom.GpuCapabilities capabilities) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferSyncClientDidInitializeParams();
      params.success = success;
      params.capabilities = capabilities;
      _proxyImpl.sendMessage(params, kCommandBufferSyncClient_didInitialize_name);
    }
  
    void didMakeProgress(CommandBufferState state) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferSyncClientDidMakeProgressParams();
      params.state = state;
      _proxyImpl.sendMessage(params, kCommandBufferSyncClient_didMakeProgress_name);
    }
  
}


class CommandBufferSyncClientProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CommandBufferSyncClient ptr;
  final String name = CommandBufferSyncClientName;

  CommandBufferSyncClientProxy(CommandBufferSyncClientProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CommandBufferSyncClientProxyCalls(proxyImpl);

  CommandBufferSyncClientProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CommandBufferSyncClientProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CommandBufferSyncClientProxyCalls(impl);
  }

  CommandBufferSyncClientProxy.fromHandle(core.MojoHandle handle) :
      impl = new CommandBufferSyncClientProxyImpl.fromHandle(handle) {
    ptr = new _CommandBufferSyncClientProxyCalls(impl);
  }

  CommandBufferSyncClientProxy.unbound() :
      impl = new CommandBufferSyncClientProxyImpl.unbound() {
    ptr = new _CommandBufferSyncClientProxyCalls(impl);
  }

  static CommandBufferSyncClientProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferSyncClientProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "CommandBufferSyncClientProxy($impl)";
  }
}


class CommandBufferSyncClientStub extends bindings.Stub {
  CommandBufferSyncClient _impl = null;

  CommandBufferSyncClientStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CommandBufferSyncClientStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CommandBufferSyncClientStub.unbound() : super.unbound();

  static CommandBufferSyncClientStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferSyncClientStub.fromEndpoint(endpoint);

  static const String name = CommandBufferSyncClientName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCommandBufferSyncClient_didInitialize_name:
        var params = CommandBufferSyncClientDidInitializeParams.deserialize(
            message.payload);
        _impl.didInitialize(params.success, params.capabilities);
        break;
      case kCommandBufferSyncClient_didMakeProgress_name:
        var params = CommandBufferSyncClientDidMakeProgressParams.deserialize(
            message.payload);
        _impl.didMakeProgress(params.state);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  CommandBufferSyncClient get impl => _impl;
      set impl(CommandBufferSyncClient d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferSyncClientStub($superString)";
  }
}

const int kCommandBufferSyncPointClient_didInsertSyncPoint_name = 0;

const String CommandBufferSyncPointClientName =
      'mojo::CommandBufferSyncPointClient';

abstract class CommandBufferSyncPointClient {
  void didInsertSyncPoint(int syncPoint);

}


class CommandBufferSyncPointClientProxyImpl extends bindings.Proxy {
  CommandBufferSyncPointClientProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CommandBufferSyncPointClientProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CommandBufferSyncPointClientProxyImpl.unbound() : super.unbound();

  static CommandBufferSyncPointClientProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferSyncPointClientProxyImpl.fromEndpoint(endpoint);

  String get name => CommandBufferSyncPointClientName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferSyncPointClientProxyImpl($superString)";
  }
}


class _CommandBufferSyncPointClientProxyCalls implements CommandBufferSyncPointClient {
  CommandBufferSyncPointClientProxyImpl _proxyImpl;

  _CommandBufferSyncPointClientProxyCalls(this._proxyImpl);
    void didInsertSyncPoint(int syncPoint) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferSyncPointClientDidInsertSyncPointParams();
      params.syncPoint = syncPoint;
      _proxyImpl.sendMessage(params, kCommandBufferSyncPointClient_didInsertSyncPoint_name);
    }
  
}


class CommandBufferSyncPointClientProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CommandBufferSyncPointClient ptr;
  final String name = CommandBufferSyncPointClientName;

  CommandBufferSyncPointClientProxy(CommandBufferSyncPointClientProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CommandBufferSyncPointClientProxyCalls(proxyImpl);

  CommandBufferSyncPointClientProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CommandBufferSyncPointClientProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CommandBufferSyncPointClientProxyCalls(impl);
  }

  CommandBufferSyncPointClientProxy.fromHandle(core.MojoHandle handle) :
      impl = new CommandBufferSyncPointClientProxyImpl.fromHandle(handle) {
    ptr = new _CommandBufferSyncPointClientProxyCalls(impl);
  }

  CommandBufferSyncPointClientProxy.unbound() :
      impl = new CommandBufferSyncPointClientProxyImpl.unbound() {
    ptr = new _CommandBufferSyncPointClientProxyCalls(impl);
  }

  static CommandBufferSyncPointClientProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferSyncPointClientProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "CommandBufferSyncPointClientProxy($impl)";
  }
}


class CommandBufferSyncPointClientStub extends bindings.Stub {
  CommandBufferSyncPointClient _impl = null;

  CommandBufferSyncPointClientStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CommandBufferSyncPointClientStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CommandBufferSyncPointClientStub.unbound() : super.unbound();

  static CommandBufferSyncPointClientStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferSyncPointClientStub.fromEndpoint(endpoint);

  static const String name = CommandBufferSyncPointClientName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCommandBufferSyncPointClient_didInsertSyncPoint_name:
        var params = CommandBufferSyncPointClientDidInsertSyncPointParams.deserialize(
            message.payload);
        _impl.didInsertSyncPoint(params.syncPoint);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  CommandBufferSyncPointClient get impl => _impl;
      set impl(CommandBufferSyncPointClient d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferSyncPointClientStub($superString)";
  }
}

const int kCommandBufferLostContextObserver_didLoseContext_name = 0;

const String CommandBufferLostContextObserverName =
      'mojo::CommandBufferLostContextObserver';

abstract class CommandBufferLostContextObserver {
  void didLoseContext(int contextLostReason);

}


class CommandBufferLostContextObserverProxyImpl extends bindings.Proxy {
  CommandBufferLostContextObserverProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CommandBufferLostContextObserverProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CommandBufferLostContextObserverProxyImpl.unbound() : super.unbound();

  static CommandBufferLostContextObserverProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferLostContextObserverProxyImpl.fromEndpoint(endpoint);

  String get name => CommandBufferLostContextObserverName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferLostContextObserverProxyImpl($superString)";
  }
}


class _CommandBufferLostContextObserverProxyCalls implements CommandBufferLostContextObserver {
  CommandBufferLostContextObserverProxyImpl _proxyImpl;

  _CommandBufferLostContextObserverProxyCalls(this._proxyImpl);
    void didLoseContext(int contextLostReason) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferLostContextObserverDidLoseContextParams();
      params.contextLostReason = contextLostReason;
      _proxyImpl.sendMessage(params, kCommandBufferLostContextObserver_didLoseContext_name);
    }
  
}


class CommandBufferLostContextObserverProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CommandBufferLostContextObserver ptr;
  final String name = CommandBufferLostContextObserverName;

  CommandBufferLostContextObserverProxy(CommandBufferLostContextObserverProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CommandBufferLostContextObserverProxyCalls(proxyImpl);

  CommandBufferLostContextObserverProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CommandBufferLostContextObserverProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CommandBufferLostContextObserverProxyCalls(impl);
  }

  CommandBufferLostContextObserverProxy.fromHandle(core.MojoHandle handle) :
      impl = new CommandBufferLostContextObserverProxyImpl.fromHandle(handle) {
    ptr = new _CommandBufferLostContextObserverProxyCalls(impl);
  }

  CommandBufferLostContextObserverProxy.unbound() :
      impl = new CommandBufferLostContextObserverProxyImpl.unbound() {
    ptr = new _CommandBufferLostContextObserverProxyCalls(impl);
  }

  static CommandBufferLostContextObserverProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferLostContextObserverProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "CommandBufferLostContextObserverProxy($impl)";
  }
}


class CommandBufferLostContextObserverStub extends bindings.Stub {
  CommandBufferLostContextObserver _impl = null;

  CommandBufferLostContextObserverStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CommandBufferLostContextObserverStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CommandBufferLostContextObserverStub.unbound() : super.unbound();

  static CommandBufferLostContextObserverStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferLostContextObserverStub.fromEndpoint(endpoint);

  static const String name = CommandBufferLostContextObserverName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCommandBufferLostContextObserver_didLoseContext_name:
        var params = CommandBufferLostContextObserverDidLoseContextParams.deserialize(
            message.payload);
        _impl.didLoseContext(params.contextLostReason);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  CommandBufferLostContextObserver get impl => _impl;
      set impl(CommandBufferLostContextObserver d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferLostContextObserverStub($superString)";
  }
}

const int kCommandBuffer_initialize_name = 0;
const int kCommandBuffer_setGetBuffer_name = 1;
const int kCommandBuffer_flush_name = 2;
const int kCommandBuffer_makeProgress_name = 3;
const int kCommandBuffer_registerTransferBuffer_name = 4;
const int kCommandBuffer_destroyTransferBuffer_name = 5;
const int kCommandBuffer_insertSyncPoint_name = 6;
const int kCommandBuffer_retireSyncPoint_name = 7;
const int kCommandBuffer_echo_name = 8;

const String CommandBufferName =
      'mojo::CommandBuffer';

abstract class CommandBuffer {
  void initialize(Object syncClient, Object syncPointClient, Object lostObserver, core.MojoSharedBuffer sharedState);
  void setGetBuffer(int buffer);
  void flush(int putOffset);
  void makeProgress(int lastGetOffset);
  void registerTransferBuffer(int id, core.MojoSharedBuffer transferBuffer, int size);
  void destroyTransferBuffer(int id);
  void insertSyncPoint(bool retire);
  void retireSyncPoint(int syncPoint);
  Future<CommandBufferEchoResponseParams> echo([Function responseFactory = null]);

}


class CommandBufferProxyImpl extends bindings.Proxy {
  CommandBufferProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CommandBufferProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CommandBufferProxyImpl.unbound() : super.unbound();

  static CommandBufferProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferProxyImpl.fromEndpoint(endpoint);

  String get name => CommandBufferName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kCommandBuffer_echo_name:
        var r = CommandBufferEchoResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferProxyImpl($superString)";
  }
}


class _CommandBufferProxyCalls implements CommandBuffer {
  CommandBufferProxyImpl _proxyImpl;

  _CommandBufferProxyCalls(this._proxyImpl);
    void initialize(Object syncClient, Object syncPointClient, Object lostObserver, core.MojoSharedBuffer sharedState) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferInitializeParams();
      params.syncClient = syncClient;
      params.syncPointClient = syncPointClient;
      params.lostObserver = lostObserver;
      params.sharedState = sharedState;
      _proxyImpl.sendMessage(params, kCommandBuffer_initialize_name);
    }
  
    void setGetBuffer(int buffer) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferSetGetBufferParams();
      params.buffer = buffer;
      _proxyImpl.sendMessage(params, kCommandBuffer_setGetBuffer_name);
    }
  
    void flush(int putOffset) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferFlushParams();
      params.putOffset = putOffset;
      _proxyImpl.sendMessage(params, kCommandBuffer_flush_name);
    }
  
    void makeProgress(int lastGetOffset) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferMakeProgressParams();
      params.lastGetOffset = lastGetOffset;
      _proxyImpl.sendMessage(params, kCommandBuffer_makeProgress_name);
    }
  
    void registerTransferBuffer(int id, core.MojoSharedBuffer transferBuffer, int size) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferRegisterTransferBufferParams();
      params.id = id;
      params.transferBuffer = transferBuffer;
      params.size = size;
      _proxyImpl.sendMessage(params, kCommandBuffer_registerTransferBuffer_name);
    }
  
    void destroyTransferBuffer(int id) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferDestroyTransferBufferParams();
      params.id = id;
      _proxyImpl.sendMessage(params, kCommandBuffer_destroyTransferBuffer_name);
    }
  
    void insertSyncPoint(bool retire) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferInsertSyncPointParams();
      params.retire = retire;
      _proxyImpl.sendMessage(params, kCommandBuffer_insertSyncPoint_name);
    }
  
    void retireSyncPoint(int syncPoint) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferRetireSyncPointParams();
      params.syncPoint = syncPoint;
      _proxyImpl.sendMessage(params, kCommandBuffer_retireSyncPoint_name);
    }
  
    Future<CommandBufferEchoResponseParams> echo([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CommandBufferEchoParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCommandBuffer_echo_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class CommandBufferProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CommandBuffer ptr;
  final String name = CommandBufferName;

  CommandBufferProxy(CommandBufferProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CommandBufferProxyCalls(proxyImpl);

  CommandBufferProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CommandBufferProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CommandBufferProxyCalls(impl);
  }

  CommandBufferProxy.fromHandle(core.MojoHandle handle) :
      impl = new CommandBufferProxyImpl.fromHandle(handle) {
    ptr = new _CommandBufferProxyCalls(impl);
  }

  CommandBufferProxy.unbound() :
      impl = new CommandBufferProxyImpl.unbound() {
    ptr = new _CommandBufferProxyCalls(impl);
  }

  static CommandBufferProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "CommandBufferProxy($impl)";
  }
}


class CommandBufferStub extends bindings.Stub {
  CommandBuffer _impl = null;

  CommandBufferStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CommandBufferStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CommandBufferStub.unbound() : super.unbound();

  static CommandBufferStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CommandBufferStub.fromEndpoint(endpoint);

  static const String name = CommandBufferName;


  CommandBufferEchoResponseParams _CommandBufferEchoResponseParamsFactory() {
    var result = new CommandBufferEchoResponseParams();
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCommandBuffer_initialize_name:
        var params = CommandBufferInitializeParams.deserialize(
            message.payload);
        _impl.initialize(params.syncClient, params.syncPointClient, params.lostObserver, params.sharedState);
        break;
      case kCommandBuffer_setGetBuffer_name:
        var params = CommandBufferSetGetBufferParams.deserialize(
            message.payload);
        _impl.setGetBuffer(params.buffer);
        break;
      case kCommandBuffer_flush_name:
        var params = CommandBufferFlushParams.deserialize(
            message.payload);
        _impl.flush(params.putOffset);
        break;
      case kCommandBuffer_makeProgress_name:
        var params = CommandBufferMakeProgressParams.deserialize(
            message.payload);
        _impl.makeProgress(params.lastGetOffset);
        break;
      case kCommandBuffer_registerTransferBuffer_name:
        var params = CommandBufferRegisterTransferBufferParams.deserialize(
            message.payload);
        _impl.registerTransferBuffer(params.id, params.transferBuffer, params.size);
        break;
      case kCommandBuffer_destroyTransferBuffer_name:
        var params = CommandBufferDestroyTransferBufferParams.deserialize(
            message.payload);
        _impl.destroyTransferBuffer(params.id);
        break;
      case kCommandBuffer_insertSyncPoint_name:
        var params = CommandBufferInsertSyncPointParams.deserialize(
            message.payload);
        _impl.insertSyncPoint(params.retire);
        break;
      case kCommandBuffer_retireSyncPoint_name:
        var params = CommandBufferRetireSyncPointParams.deserialize(
            message.payload);
        _impl.retireSyncPoint(params.syncPoint);
        break;
      case kCommandBuffer_echo_name:
        var params = CommandBufferEchoParams.deserialize(
            message.payload);
        return _impl.echo(_CommandBufferEchoResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCommandBuffer_echo_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  CommandBuffer get impl => _impl;
      set impl(CommandBuffer d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CommandBufferStub($superString)";
  }
}


