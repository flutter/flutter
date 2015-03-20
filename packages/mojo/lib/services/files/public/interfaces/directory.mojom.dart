// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library directory.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/files/public/interfaces/file.mojom.dart' as file_mojom;
import 'package:mojo/services/files/public/interfaces/types.mojom.dart' as types_mojom;


class DirectoryReadParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  DirectoryReadParams() : super(kStructSize);

  static DirectoryReadParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryReadParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryReadParams result = new DirectoryReadParams();

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
    return "DirectoryReadParams("")";
  }
}

class DirectoryReadResponseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;
  List<types_mojom.DirectoryEntry> directoryContents = null;

  DirectoryReadResponseParams() : super(kStructSize);

  static DirectoryReadResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryReadResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryReadResponseParams result = new DirectoryReadResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.directoryContents = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.directoryContents = new List<types_mojom.DirectoryEntry>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.directoryContents[i1] = types_mojom.DirectoryEntry.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
    
    if (directoryContents == null) {
      encoder0.encodeNullPointer(16, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(directoryContents.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < directoryContents.length; ++i0) {
        
        encoder1.encodeStruct(directoryContents[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "DirectoryReadResponseParams("
           "error: $error" ", "
           "directoryContents: $directoryContents" ")";
  }
}

class DirectoryStatParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  DirectoryStatParams() : super(kStructSize);

  static DirectoryStatParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryStatParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryStatParams result = new DirectoryStatParams();

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
    return "DirectoryStatParams("")";
  }
}

class DirectoryStatResponseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;
  types_mojom.FileInformation fileInformation = null;

  DirectoryStatResponseParams() : super(kStructSize);

  static DirectoryStatResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryStatResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryStatResponseParams result = new DirectoryStatResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fileInformation = types_mojom.FileInformation.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeStruct(fileInformation, 16, true);
  }

  String toString() {
    return "DirectoryStatResponseParams("
           "error: $error" ", "
           "fileInformation: $fileInformation" ")";
  }
}

class DirectoryTouchParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  types_mojom.TimespecOrNow atime = null;
  types_mojom.TimespecOrNow mtime = null;

  DirectoryTouchParams() : super(kStructSize);

  static DirectoryTouchParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryTouchParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryTouchParams result = new DirectoryTouchParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.atime = types_mojom.TimespecOrNow.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.mtime = types_mojom.TimespecOrNow.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(atime, 8, true);
    
    encoder0.encodeStruct(mtime, 16, true);
  }

  String toString() {
    return "DirectoryTouchParams("
           "atime: $atime" ", "
           "mtime: $mtime" ")";
  }
}

class DirectoryTouchResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;

  DirectoryTouchResponseParams() : super(kStructSize);

  static DirectoryTouchResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryTouchResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryTouchResponseParams result = new DirectoryTouchResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "DirectoryTouchResponseParams("
           "error: $error" ")";
  }
}

class DirectoryOpenFileParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String path = null;
  Object file = null;
  int openFlags = 0;

  DirectoryOpenFileParams() : super(kStructSize);

  static DirectoryOpenFileParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryOpenFileParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryOpenFileParams result = new DirectoryOpenFileParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.path = decoder0.decodeString(8, false);
    }
    {
      
      result.file = decoder0.decodeInterfaceRequest(16, true, file_mojom.FileStub.newFromEndpoint);
    }
    {
      
      result.openFlags = decoder0.decodeUint32(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(path, 8, false);
    
    encoder0.encodeInterfaceRequest(file, 16, true);
    
    encoder0.encodeUint32(openFlags, 20);
  }

  String toString() {
    return "DirectoryOpenFileParams("
           "path: $path" ", "
           "file: $file" ", "
           "openFlags: $openFlags" ")";
  }
}

class DirectoryOpenFileResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;

  DirectoryOpenFileResponseParams() : super(kStructSize);

  static DirectoryOpenFileResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryOpenFileResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryOpenFileResponseParams result = new DirectoryOpenFileResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "DirectoryOpenFileResponseParams("
           "error: $error" ")";
  }
}

class DirectoryOpenDirectoryParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String path = null;
  Object directory = null;
  int openFlags = 0;

  DirectoryOpenDirectoryParams() : super(kStructSize);

  static DirectoryOpenDirectoryParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryOpenDirectoryParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryOpenDirectoryParams result = new DirectoryOpenDirectoryParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.path = decoder0.decodeString(8, false);
    }
    {
      
      result.directory = decoder0.decodeInterfaceRequest(16, true, DirectoryStub.newFromEndpoint);
    }
    {
      
      result.openFlags = decoder0.decodeUint32(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(path, 8, false);
    
    encoder0.encodeInterfaceRequest(directory, 16, true);
    
    encoder0.encodeUint32(openFlags, 20);
  }

  String toString() {
    return "DirectoryOpenDirectoryParams("
           "path: $path" ", "
           "directory: $directory" ", "
           "openFlags: $openFlags" ")";
  }
}

class DirectoryOpenDirectoryResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;

  DirectoryOpenDirectoryResponseParams() : super(kStructSize);

  static DirectoryOpenDirectoryResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryOpenDirectoryResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryOpenDirectoryResponseParams result = new DirectoryOpenDirectoryResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "DirectoryOpenDirectoryResponseParams("
           "error: $error" ")";
  }
}

class DirectoryRenameParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String path = null;
  String newPath = null;

  DirectoryRenameParams() : super(kStructSize);

  static DirectoryRenameParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryRenameParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryRenameParams result = new DirectoryRenameParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.path = decoder0.decodeString(8, false);
    }
    {
      
      result.newPath = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(path, 8, false);
    
    encoder0.encodeString(newPath, 16, false);
  }

  String toString() {
    return "DirectoryRenameParams("
           "path: $path" ", "
           "newPath: $newPath" ")";
  }
}

class DirectoryRenameResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;

  DirectoryRenameResponseParams() : super(kStructSize);

  static DirectoryRenameResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryRenameResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryRenameResponseParams result = new DirectoryRenameResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "DirectoryRenameResponseParams("
           "error: $error" ")";
  }
}

class DirectoryDeleteParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String path = null;
  int deleteFlags = 0;

  DirectoryDeleteParams() : super(kStructSize);

  static DirectoryDeleteParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryDeleteParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryDeleteParams result = new DirectoryDeleteParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.path = decoder0.decodeString(8, false);
    }
    {
      
      result.deleteFlags = decoder0.decodeUint32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(path, 8, false);
    
    encoder0.encodeUint32(deleteFlags, 16);
  }

  String toString() {
    return "DirectoryDeleteParams("
           "path: $path" ", "
           "deleteFlags: $deleteFlags" ")";
  }
}

class DirectoryDeleteResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int error = 0;

  DirectoryDeleteResponseParams() : super(kStructSize);

  static DirectoryDeleteResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryDeleteResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryDeleteResponseParams result = new DirectoryDeleteResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "DirectoryDeleteResponseParams("
           "error: $error" ")";
  }
}
const int kDirectory_read_name = 0;
const int kDirectory_stat_name = 1;
const int kDirectory_touch_name = 2;
const int kDirectory_openFile_name = 3;
const int kDirectory_openDirectory_name = 4;
const int kDirectory_rename_name = 5;
const int kDirectory_delete_name = 6;

const String DirectoryName =
      'mojo::files::Directory';

abstract class Directory {
  Future<DirectoryReadResponseParams> read([Function responseFactory = null]);
  Future<DirectoryStatResponseParams> stat([Function responseFactory = null]);
  Future<DirectoryTouchResponseParams> touch(types_mojom.TimespecOrNow atime,types_mojom.TimespecOrNow mtime,[Function responseFactory = null]);
  Future<DirectoryOpenFileResponseParams> openFile(String path,Object file,int openFlags,[Function responseFactory = null]);
  Future<DirectoryOpenDirectoryResponseParams> openDirectory(String path,Object directory,int openFlags,[Function responseFactory = null]);
  Future<DirectoryRenameResponseParams> rename(String path,String newPath,[Function responseFactory = null]);
  Future<DirectoryDeleteResponseParams> delete(String path,int deleteFlags,[Function responseFactory = null]);

}


class DirectoryProxyImpl extends bindings.Proxy {
  DirectoryProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  DirectoryProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  DirectoryProxyImpl.unbound() : super.unbound();

  static DirectoryProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DirectoryProxyImpl.fromEndpoint(endpoint);

  String get name => DirectoryName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kDirectory_read_name:
        var r = DirectoryReadResponseParams.deserialize(
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
      case kDirectory_stat_name:
        var r = DirectoryStatResponseParams.deserialize(
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
      case kDirectory_touch_name:
        var r = DirectoryTouchResponseParams.deserialize(
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
      case kDirectory_openFile_name:
        var r = DirectoryOpenFileResponseParams.deserialize(
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
      case kDirectory_openDirectory_name:
        var r = DirectoryOpenDirectoryResponseParams.deserialize(
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
      case kDirectory_rename_name:
        var r = DirectoryRenameResponseParams.deserialize(
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
      case kDirectory_delete_name:
        var r = DirectoryDeleteResponseParams.deserialize(
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
    return "DirectoryProxyImpl($superString)";
  }
}


class _DirectoryProxyCalls implements Directory {
  DirectoryProxyImpl _proxyImpl;

  _DirectoryProxyCalls(this._proxyImpl);
    Future<DirectoryReadResponseParams> read([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryReadParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_read_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<DirectoryStatResponseParams> stat([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryStatParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_stat_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<DirectoryTouchResponseParams> touch(types_mojom.TimespecOrNow atime,types_mojom.TimespecOrNow mtime,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryTouchParams();
      params.atime = atime;
      params.mtime = mtime;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_touch_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<DirectoryOpenFileResponseParams> openFile(String path,Object file,int openFlags,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryOpenFileParams();
      params.path = path;
      params.file = file;
      params.openFlags = openFlags;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_openFile_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<DirectoryOpenDirectoryResponseParams> openDirectory(String path,Object directory,int openFlags,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryOpenDirectoryParams();
      params.path = path;
      params.directory = directory;
      params.openFlags = openFlags;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_openDirectory_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<DirectoryRenameResponseParams> rename(String path,String newPath,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryRenameParams();
      params.path = path;
      params.newPath = newPath;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_rename_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<DirectoryDeleteResponseParams> delete(String path,int deleteFlags,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DirectoryDeleteParams();
      params.path = path;
      params.deleteFlags = deleteFlags;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDirectory_delete_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class DirectoryProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Directory ptr;
  final String name = DirectoryName;

  DirectoryProxy(DirectoryProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _DirectoryProxyCalls(proxyImpl);

  DirectoryProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new DirectoryProxyImpl.fromEndpoint(endpoint) {
    ptr = new _DirectoryProxyCalls(impl);
  }

  DirectoryProxy.fromHandle(core.MojoHandle handle) :
      impl = new DirectoryProxyImpl.fromHandle(handle) {
    ptr = new _DirectoryProxyCalls(impl);
  }

  DirectoryProxy.unbound() :
      impl = new DirectoryProxyImpl.unbound() {
    ptr = new _DirectoryProxyCalls(impl);
  }

  static DirectoryProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DirectoryProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "DirectoryProxy($impl)";
  }
}


class DirectoryStub extends bindings.Stub {
  Directory _impl = null;

  DirectoryStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  DirectoryStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  DirectoryStub.unbound() : super.unbound();

  static DirectoryStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DirectoryStub.fromEndpoint(endpoint);

  static const String name = DirectoryName;


  DirectoryReadResponseParams _DirectoryReadResponseParamsFactory(int error, List<types_mojom.DirectoryEntry> directoryContents) {
    var result = new DirectoryReadResponseParams();
    result.error = error;
    result.directoryContents = directoryContents;
    return result;
  }
  DirectoryStatResponseParams _DirectoryStatResponseParamsFactory(int error, types_mojom.FileInformation fileInformation) {
    var result = new DirectoryStatResponseParams();
    result.error = error;
    result.fileInformation = fileInformation;
    return result;
  }
  DirectoryTouchResponseParams _DirectoryTouchResponseParamsFactory(int error) {
    var result = new DirectoryTouchResponseParams();
    result.error = error;
    return result;
  }
  DirectoryOpenFileResponseParams _DirectoryOpenFileResponseParamsFactory(int error) {
    var result = new DirectoryOpenFileResponseParams();
    result.error = error;
    return result;
  }
  DirectoryOpenDirectoryResponseParams _DirectoryOpenDirectoryResponseParamsFactory(int error) {
    var result = new DirectoryOpenDirectoryResponseParams();
    result.error = error;
    return result;
  }
  DirectoryRenameResponseParams _DirectoryRenameResponseParamsFactory(int error) {
    var result = new DirectoryRenameResponseParams();
    result.error = error;
    return result;
  }
  DirectoryDeleteResponseParams _DirectoryDeleteResponseParamsFactory(int error) {
    var result = new DirectoryDeleteResponseParams();
    result.error = error;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kDirectory_read_name:
        var params = DirectoryReadParams.deserialize(
            message.payload);
        return _impl.read(_DirectoryReadResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_read_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kDirectory_stat_name:
        var params = DirectoryStatParams.deserialize(
            message.payload);
        return _impl.stat(_DirectoryStatResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_stat_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kDirectory_touch_name:
        var params = DirectoryTouchParams.deserialize(
            message.payload);
        return _impl.touch(params.atime,params.mtime,_DirectoryTouchResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_touch_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kDirectory_openFile_name:
        var params = DirectoryOpenFileParams.deserialize(
            message.payload);
        return _impl.openFile(params.path,params.file,params.openFlags,_DirectoryOpenFileResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_openFile_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kDirectory_openDirectory_name:
        var params = DirectoryOpenDirectoryParams.deserialize(
            message.payload);
        return _impl.openDirectory(params.path,params.directory,params.openFlags,_DirectoryOpenDirectoryResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_openDirectory_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kDirectory_rename_name:
        var params = DirectoryRenameParams.deserialize(
            message.payload);
        return _impl.rename(params.path,params.newPath,_DirectoryRenameResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_rename_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kDirectory_delete_name:
        var params = DirectoryDeleteParams.deserialize(
            message.payload);
        return _impl.delete(params.path,params.deleteFlags,_DirectoryDeleteResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDirectory_delete_name,
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

  Directory get impl => _impl;
      set impl(Directory d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "DirectoryStub($superString)";
  }
}


