// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library keyboard.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class CompletionData extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  int id = 0;
  int position = 0;
  String text = null;
  String label = null;

  CompletionData() : super(kVersions.last.size);

  static CompletionData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CompletionData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CompletionData result = new CompletionData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.id = decoder0.decodeInt64(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.position = decoder0.decodeInt32(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.text = decoder0.decodeString(24, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.label = decoder0.decodeString(32, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt64(id, 8);
    
    encoder0.encodeInt32(position, 16);
    
    encoder0.encodeString(text, 24, false);
    
    encoder0.encodeString(label, 32, false);
  }

  String toString() {
    return "CompletionData("
           "id: $id" ", "
           "position: $position" ", "
           "text: $text" ", "
           "label: $label" ")";
  }
}

class CorrectionData extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  int offset = 0;
  String oldText = null;
  String newText = null;

  CorrectionData() : super(kVersions.last.size);

  static CorrectionData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CorrectionData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CorrectionData result = new CorrectionData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.offset = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.oldText = decoder0.decodeString(16, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.newText = decoder0.decodeString(24, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(offset, 8);
    
    encoder0.encodeString(oldText, 16, false);
    
    encoder0.encodeString(newText, 24, false);
  }

  String toString() {
    return "CorrectionData("
           "offset: $offset" ", "
           "oldText: $oldText" ", "
           "newText: $newText" ")";
  }
}

class KeyboardClientCommitCompletionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  CompletionData completion = null;

  KeyboardClientCommitCompletionParams() : super(kVersions.last.size);

  static KeyboardClientCommitCompletionParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientCommitCompletionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientCommitCompletionParams result = new KeyboardClientCommitCompletionParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.completion = CompletionData.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(completion, 8, false);
  }

  String toString() {
    return "KeyboardClientCommitCompletionParams("
           "completion: $completion" ")";
  }
}

class KeyboardClientCommitCorrectionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  CorrectionData correction = null;

  KeyboardClientCommitCorrectionParams() : super(kVersions.last.size);

  static KeyboardClientCommitCorrectionParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientCommitCorrectionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientCommitCorrectionParams result = new KeyboardClientCommitCorrectionParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.correction = CorrectionData.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(correction, 8, false);
  }

  String toString() {
    return "KeyboardClientCommitCorrectionParams("
           "correction: $correction" ")";
  }
}

class KeyboardClientCommitTextParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String text = null;
  int newCursorPosition = 0;

  KeyboardClientCommitTextParams() : super(kVersions.last.size);

  static KeyboardClientCommitTextParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientCommitTextParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientCommitTextParams result = new KeyboardClientCommitTextParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.text = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.newCursorPosition = decoder0.decodeInt32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(text, 8, false);
    
    encoder0.encodeInt32(newCursorPosition, 16);
  }

  String toString() {
    return "KeyboardClientCommitTextParams("
           "text: $text" ", "
           "newCursorPosition: $newCursorPosition" ")";
  }
}

class KeyboardClientDeleteSurroundingTextParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int beforeLength = 0;
  int afterLength = 0;

  KeyboardClientDeleteSurroundingTextParams() : super(kVersions.last.size);

  static KeyboardClientDeleteSurroundingTextParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientDeleteSurroundingTextParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientDeleteSurroundingTextParams result = new KeyboardClientDeleteSurroundingTextParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.beforeLength = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.afterLength = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(beforeLength, 8);
    
    encoder0.encodeInt32(afterLength, 12);
  }

  String toString() {
    return "KeyboardClientDeleteSurroundingTextParams("
           "beforeLength: $beforeLength" ", "
           "afterLength: $afterLength" ")";
  }
}

class KeyboardClientSetComposingRegionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int start = 0;
  int end = 0;

  KeyboardClientSetComposingRegionParams() : super(kVersions.last.size);

  static KeyboardClientSetComposingRegionParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientSetComposingRegionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientSetComposingRegionParams result = new KeyboardClientSetComposingRegionParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.start = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.end = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(start, 8);
    
    encoder0.encodeInt32(end, 12);
  }

  String toString() {
    return "KeyboardClientSetComposingRegionParams("
           "start: $start" ", "
           "end: $end" ")";
  }
}

class KeyboardClientSetComposingTextParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String text = null;
  int newCursorPosition = 0;

  KeyboardClientSetComposingTextParams() : super(kVersions.last.size);

  static KeyboardClientSetComposingTextParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientSetComposingTextParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientSetComposingTextParams result = new KeyboardClientSetComposingTextParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.text = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.newCursorPosition = decoder0.decodeInt32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(text, 8, false);
    
    encoder0.encodeInt32(newCursorPosition, 16);
  }

  String toString() {
    return "KeyboardClientSetComposingTextParams("
           "text: $text" ", "
           "newCursorPosition: $newCursorPosition" ")";
  }
}

class KeyboardClientSetSelectionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int start = 0;
  int end = 0;

  KeyboardClientSetSelectionParams() : super(kVersions.last.size);

  static KeyboardClientSetSelectionParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardClientSetSelectionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardClientSetSelectionParams result = new KeyboardClientSetSelectionParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.start = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.end = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(start, 8);
    
    encoder0.encodeInt32(end, 12);
  }

  String toString() {
    return "KeyboardClientSetSelectionParams("
           "start: $start" ", "
           "end: $end" ")";
  }
}

class KeyboardServiceShowParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object client = null;

  KeyboardServiceShowParams() : super(kVersions.last.size);

  static KeyboardServiceShowParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardServiceShowParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardServiceShowParams result = new KeyboardServiceShowParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.client = decoder0.decodeServiceInterface(8, false, KeyboardClientProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterface(client, 8, false);
  }

  String toString() {
    return "KeyboardServiceShowParams("
           "client: $client" ")";
  }
}

class KeyboardServiceHideParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  KeyboardServiceHideParams() : super(kVersions.last.size);

  static KeyboardServiceHideParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardServiceHideParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardServiceHideParams result = new KeyboardServiceHideParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kVersions.last);
  }

  String toString() {
    return "KeyboardServiceHideParams("")";
  }
}
const int kKeyboardClient_commitCompletion_name = 0;
const int kKeyboardClient_commitCorrection_name = 1;
const int kKeyboardClient_commitText_name = 2;
const int kKeyboardClient_deleteSurroundingText_name = 3;
const int kKeyboardClient_setComposingRegion_name = 4;
const int kKeyboardClient_setComposingText_name = 5;
const int kKeyboardClient_setSelection_name = 6;

const String KeyboardClientName =
      'keyboard::KeyboardClient';

abstract class KeyboardClient {
  void commitCompletion(CompletionData completion);
  void commitCorrection(CorrectionData correction);
  void commitText(String text, int newCursorPosition);
  void deleteSurroundingText(int beforeLength, int afterLength);
  void setComposingRegion(int start, int end);
  void setComposingText(String text, int newCursorPosition);
  void setSelection(int start, int end);

}


class KeyboardClientProxyImpl extends bindings.Proxy {
  KeyboardClientProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  KeyboardClientProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  KeyboardClientProxyImpl.unbound() : super.unbound();

  static KeyboardClientProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardClientProxyImpl.fromEndpoint(endpoint);

  String get name => KeyboardClientName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "KeyboardClientProxyImpl($superString)";
  }
}


class _KeyboardClientProxyCalls implements KeyboardClient {
  KeyboardClientProxyImpl _proxyImpl;

  _KeyboardClientProxyCalls(this._proxyImpl);
    void commitCompletion(CompletionData completion) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientCommitCompletionParams();
      params.completion = completion;
      _proxyImpl.sendMessage(params, kKeyboardClient_commitCompletion_name);
    }
  
    void commitCorrection(CorrectionData correction) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientCommitCorrectionParams();
      params.correction = correction;
      _proxyImpl.sendMessage(params, kKeyboardClient_commitCorrection_name);
    }
  
    void commitText(String text, int newCursorPosition) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientCommitTextParams();
      params.text = text;
      params.newCursorPosition = newCursorPosition;
      _proxyImpl.sendMessage(params, kKeyboardClient_commitText_name);
    }
  
    void deleteSurroundingText(int beforeLength, int afterLength) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientDeleteSurroundingTextParams();
      params.beforeLength = beforeLength;
      params.afterLength = afterLength;
      _proxyImpl.sendMessage(params, kKeyboardClient_deleteSurroundingText_name);
    }
  
    void setComposingRegion(int start, int end) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientSetComposingRegionParams();
      params.start = start;
      params.end = end;
      _proxyImpl.sendMessage(params, kKeyboardClient_setComposingRegion_name);
    }
  
    void setComposingText(String text, int newCursorPosition) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientSetComposingTextParams();
      params.text = text;
      params.newCursorPosition = newCursorPosition;
      _proxyImpl.sendMessage(params, kKeyboardClient_setComposingText_name);
    }
  
    void setSelection(int start, int end) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardClientSetSelectionParams();
      params.start = start;
      params.end = end;
      _proxyImpl.sendMessage(params, kKeyboardClient_setSelection_name);
    }
  
}


class KeyboardClientProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  KeyboardClient ptr;
  final String name = KeyboardClientName;

  KeyboardClientProxy(KeyboardClientProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _KeyboardClientProxyCalls(proxyImpl);

  KeyboardClientProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new KeyboardClientProxyImpl.fromEndpoint(endpoint) {
    ptr = new _KeyboardClientProxyCalls(impl);
  }

  KeyboardClientProxy.fromHandle(core.MojoHandle handle) :
      impl = new KeyboardClientProxyImpl.fromHandle(handle) {
    ptr = new _KeyboardClientProxyCalls(impl);
  }

  KeyboardClientProxy.unbound() :
      impl = new KeyboardClientProxyImpl.unbound() {
    ptr = new _KeyboardClientProxyCalls(impl);
  }

  static KeyboardClientProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardClientProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "KeyboardClientProxy($impl)";
  }
}


class KeyboardClientStub extends bindings.Stub {
  KeyboardClient _impl = null;

  KeyboardClientStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  KeyboardClientStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  KeyboardClientStub.unbound() : super.unbound();

  static KeyboardClientStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardClientStub.fromEndpoint(endpoint);

  static const String name = KeyboardClientName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kKeyboardClient_commitCompletion_name:
        var params = KeyboardClientCommitCompletionParams.deserialize(
            message.payload);
        _impl.commitCompletion(params.completion);
        break;
      case kKeyboardClient_commitCorrection_name:
        var params = KeyboardClientCommitCorrectionParams.deserialize(
            message.payload);
        _impl.commitCorrection(params.correction);
        break;
      case kKeyboardClient_commitText_name:
        var params = KeyboardClientCommitTextParams.deserialize(
            message.payload);
        _impl.commitText(params.text, params.newCursorPosition);
        break;
      case kKeyboardClient_deleteSurroundingText_name:
        var params = KeyboardClientDeleteSurroundingTextParams.deserialize(
            message.payload);
        _impl.deleteSurroundingText(params.beforeLength, params.afterLength);
        break;
      case kKeyboardClient_setComposingRegion_name:
        var params = KeyboardClientSetComposingRegionParams.deserialize(
            message.payload);
        _impl.setComposingRegion(params.start, params.end);
        break;
      case kKeyboardClient_setComposingText_name:
        var params = KeyboardClientSetComposingTextParams.deserialize(
            message.payload);
        _impl.setComposingText(params.text, params.newCursorPosition);
        break;
      case kKeyboardClient_setSelection_name:
        var params = KeyboardClientSetSelectionParams.deserialize(
            message.payload);
        _impl.setSelection(params.start, params.end);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  KeyboardClient get impl => _impl;
      set impl(KeyboardClient d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "KeyboardClientStub($superString)";
  }
}

const int kKeyboardService_show_name = 0;
const int kKeyboardService_hide_name = 1;

const String KeyboardServiceName =
      'keyboard::KeyboardService';

abstract class KeyboardService {
  void show(Object client);
  void hide();

}


class KeyboardServiceProxyImpl extends bindings.Proxy {
  KeyboardServiceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  KeyboardServiceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  KeyboardServiceProxyImpl.unbound() : super.unbound();

  static KeyboardServiceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardServiceProxyImpl.fromEndpoint(endpoint);

  String get name => KeyboardServiceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "KeyboardServiceProxyImpl($superString)";
  }
}


class _KeyboardServiceProxyCalls implements KeyboardService {
  KeyboardServiceProxyImpl _proxyImpl;

  _KeyboardServiceProxyCalls(this._proxyImpl);
    void show(Object client) {
      assert(_proxyImpl.isBound);
      var params = new KeyboardServiceShowParams();
      params.client = client;
      _proxyImpl.sendMessage(params, kKeyboardService_show_name);
    }
  
    void hide() {
      assert(_proxyImpl.isBound);
      var params = new KeyboardServiceHideParams();
      _proxyImpl.sendMessage(params, kKeyboardService_hide_name);
    }
  
}


class KeyboardServiceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  KeyboardService ptr;
  final String name = KeyboardServiceName;

  KeyboardServiceProxy(KeyboardServiceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _KeyboardServiceProxyCalls(proxyImpl);

  KeyboardServiceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new KeyboardServiceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _KeyboardServiceProxyCalls(impl);
  }

  KeyboardServiceProxy.fromHandle(core.MojoHandle handle) :
      impl = new KeyboardServiceProxyImpl.fromHandle(handle) {
    ptr = new _KeyboardServiceProxyCalls(impl);
  }

  KeyboardServiceProxy.unbound() :
      impl = new KeyboardServiceProxyImpl.unbound() {
    ptr = new _KeyboardServiceProxyCalls(impl);
  }

  static KeyboardServiceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardServiceProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "KeyboardServiceProxy($impl)";
  }
}


class KeyboardServiceStub extends bindings.Stub {
  KeyboardService _impl = null;

  KeyboardServiceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  KeyboardServiceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  KeyboardServiceStub.unbound() : super.unbound();

  static KeyboardServiceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardServiceStub.fromEndpoint(endpoint);

  static const String name = KeyboardServiceName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kKeyboardService_show_name:
        var params = KeyboardServiceShowParams.deserialize(
            message.payload);
        _impl.show(params.client);
        break;
      case kKeyboardService_hide_name:
        var params = KeyboardServiceHideParams.deserialize(
            message.payload);
        _impl.hide();
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  KeyboardService get impl => _impl;
      set impl(KeyboardService d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "KeyboardServiceStub($superString)";
  }
}


