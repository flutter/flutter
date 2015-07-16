// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/public/js/codec", [
  "mojo/public/js/unicode",
  "mojo/public/js/buffer",
], function(unicode, buffer) {

  var kErrorUnsigned = "Passing negative value to unsigned";
  var kErrorArray = "Passing non Array for array type";
  var kErrorString = "Passing non String for string type";
  var kErrorMap = "Passing non Map for map type";

  // Memory -------------------------------------------------------------------

  var kAlignment = 8;

  function align(size) {
    return size + (kAlignment - (size % kAlignment)) % kAlignment;
  }

  function isAligned(offset) {
    return offset >= 0 && (offset % kAlignment) === 0;
  }

  // Constants ----------------------------------------------------------------

  var kArrayHeaderSize = 8;
  var kStructHeaderSize = 8;
  var kMessageHeaderSize = 16;
  var kMessageWithRequestIDHeaderSize = 24;
  var kMapStructPayloadSize = 16;

  var kStructHeaderNumBytesOffset = 0;
  var kStructHeaderVersionOffset = 4;

  var kEncodedInvalidHandleValue = 0xFFFFFFFF;

  // Decoder ------------------------------------------------------------------

  function Decoder(buffer, handles, base) {
    this.buffer = buffer;
    this.handles = handles;
    this.base = base;
    this.next = base;
  }

  Decoder.prototype.align = function() {
    this.next = align(this.next);
  };

  Decoder.prototype.skip = function(offset) {
    this.next += offset;
  };

  Decoder.prototype.readInt8 = function() {
    var result = this.buffer.getInt8(this.next);
    this.next += 1;
    return result;
  };

  Decoder.prototype.readUint8 = function() {
    var result = this.buffer.getUint8(this.next);
    this.next += 1;
    return result;
  };

  Decoder.prototype.readInt16 = function() {
    var result = this.buffer.getInt16(this.next);
    this.next += 2;
    return result;
  };

  Decoder.prototype.readUint16 = function() {
    var result = this.buffer.getUint16(this.next);
    this.next += 2;
    return result;
  };

  Decoder.prototype.readInt32 = function() {
    var result = this.buffer.getInt32(this.next);
    this.next += 4;
    return result;
  };

  Decoder.prototype.readUint32 = function() {
    var result = this.buffer.getUint32(this.next);
    this.next += 4;
    return result;
  };

  Decoder.prototype.readInt64 = function() {
    var result = this.buffer.getInt64(this.next);
    this.next += 8;
    return result;
  };

  Decoder.prototype.readUint64 = function() {
    var result = this.buffer.getUint64(this.next);
    this.next += 8;
    return result;
  };

  Decoder.prototype.readFloat = function() {
    var result = this.buffer.getFloat32(this.next);
    this.next += 4;
    return result;
  };

  Decoder.prototype.readDouble = function() {
    var result = this.buffer.getFloat64(this.next);
    this.next += 8;
    return result;
  };

  Decoder.prototype.decodePointer = function() {
    // TODO(abarth): To correctly decode a pointer, we need to know the real
    // base address of the array buffer.
    var offsetPointer = this.next;
    var offset = this.readUint64();
    if (!offset)
      return 0;
    return offsetPointer + offset;
  };

  Decoder.prototype.decodeAndCreateDecoder = function(pointer) {
    return new Decoder(this.buffer, this.handles, pointer);
  };

  Decoder.prototype.decodeHandle = function() {
    return this.handles[this.readUint32()] || null;
  };

  Decoder.prototype.decodeString = function() {
    var numberOfBytes = this.readUint32();
    var numberOfElements = this.readUint32();
    var base = this.next;
    this.next += numberOfElements;
    return unicode.decodeUtf8String(
        new Uint8Array(this.buffer.arrayBuffer, base, numberOfElements));
  };

  Decoder.prototype.decodeArray = function(cls) {
    var numberOfBytes = this.readUint32();
    var numberOfElements = this.readUint32();
    var val = new Array(numberOfElements);
    if (cls === PackedBool) {
      var byte;
      for (var i = 0; i < numberOfElements; ++i) {
        if (i % 8 === 0)
          byte = this.readUint8();
        val[i] = (byte & (1 << i % 8)) ? true : false;
      }
    } else {
      for (var i = 0; i < numberOfElements; ++i) {
        val[i] = cls.decode(this);
      }
    }
    return val;
  };

  Decoder.prototype.decodeStruct = function(cls) {
    return cls.decode(this);
  };

  Decoder.prototype.decodeStructPointer = function(cls) {
    var pointer = this.decodePointer();
    if (!pointer) {
      return null;
    }
    return cls.decode(this.decodeAndCreateDecoder(pointer));
  };

  Decoder.prototype.decodeArrayPointer = function(cls) {
    var pointer = this.decodePointer();
    if (!pointer) {
      return null;
    }
    return this.decodeAndCreateDecoder(pointer).decodeArray(cls);
  };

  Decoder.prototype.decodeStringPointer = function() {
    var pointer = this.decodePointer();
    if (!pointer) {
      return null;
    }
    return this.decodeAndCreateDecoder(pointer).decodeString();
  };

  Decoder.prototype.decodeMap = function(keyClass, valueClass) {
    this.skip(4); // numberOfBytes
    this.skip(4); // version
    var keys = this.decodeArrayPointer(keyClass);
    var values = this.decodeArrayPointer(valueClass);
    var val = new Map();
    for (var i = 0; i < keys.length; i++)
      val.set(keys[i], values[i]);
    return val;
  };

  Decoder.prototype.decodeMapPointer = function(keyClass, valueClass) {
    var pointer = this.decodePointer();
    if (!pointer) {
      return null;
    }
    var decoder = this.decodeAndCreateDecoder(pointer);
    return decoder.decodeMap(keyClass, valueClass);
  };

  // Encoder ------------------------------------------------------------------

  function Encoder(buffer, handles, base) {
    this.buffer = buffer;
    this.handles = handles;
    this.base = base;
    this.next = base;
  }

  Encoder.prototype.align = function() {
    this.next = align(this.next);
  };

  Encoder.prototype.skip = function(offset) {
    this.next += offset;
  };

  Encoder.prototype.writeInt8 = function(val) {
    this.buffer.setInt8(this.next, val);
    this.next += 1;
  };

  Encoder.prototype.writeUint8 = function(val) {
    if (val < 0) {
      throw new Error(kErrorUnsigned);
    }
    this.buffer.setUint8(this.next, val);
    this.next += 1;
  };

  Encoder.prototype.writeInt16 = function(val) {
    this.buffer.setInt16(this.next, val);
    this.next += 2;
  };

  Encoder.prototype.writeUint16 = function(val) {
    if (val < 0) {
      throw new Error(kErrorUnsigned);
    }
    this.buffer.setUint16(this.next, val);
    this.next += 2;
  };

  Encoder.prototype.writeInt32 = function(val) {
    this.buffer.setInt32(this.next, val);
    this.next += 4;
  };

  Encoder.prototype.writeUint32 = function(val) {
    if (val < 0) {
      throw new Error(kErrorUnsigned);
    }
    this.buffer.setUint32(this.next, val);
    this.next += 4;
  };

  Encoder.prototype.writeInt64 = function(val) {
    this.buffer.setInt64(this.next, val);
    this.next += 8;
  };

  Encoder.prototype.writeUint64 = function(val) {
    if (val < 0) {
      throw new Error(kErrorUnsigned);
    }
    this.buffer.setUint64(this.next, val);
    this.next += 8;
  };

  Encoder.prototype.writeFloat = function(val) {
    this.buffer.setFloat32(this.next, val);
    this.next += 4;
  };

  Encoder.prototype.writeDouble = function(val) {
    this.buffer.setFloat64(this.next, val);
    this.next += 8;
  };

  Encoder.prototype.encodePointer = function(pointer) {
    if (!pointer)
      return this.writeUint64(0);
    // TODO(abarth): To correctly encode a pointer, we need to know the real
    // base address of the array buffer.
    var offset = pointer - this.next;
    this.writeUint64(offset);
  };

  Encoder.prototype.createAndEncodeEncoder = function(size) {
    var pointer = this.buffer.alloc(align(size));
    this.encodePointer(pointer);
    return new Encoder(this.buffer, this.handles, pointer);
  };

  Encoder.prototype.encodeHandle = function(handle) {
    this.handles.push(handle);
    this.writeUint32(this.handles.length - 1);
  };

  Encoder.prototype.encodeString = function(val) {
    var base = this.next + kArrayHeaderSize;
    var numberOfElements = unicode.encodeUtf8String(
        val, new Uint8Array(this.buffer.arrayBuffer, base));
    var numberOfBytes = kArrayHeaderSize + numberOfElements;
    this.writeUint32(numberOfBytes);
    this.writeUint32(numberOfElements);
    this.next += numberOfElements;
  };

  Encoder.prototype.encodeArray =
      function(cls, val, numberOfElements, encodedSize) {
    if (numberOfElements === undefined)
      numberOfElements = val.length;
    if (encodedSize === undefined)
      encodedSize = kArrayHeaderSize + cls.encodedSize * numberOfElements;

    this.writeUint32(encodedSize);
    this.writeUint32(numberOfElements);

    if (cls === PackedBool) {
      var byte = 0;
      for (i = 0; i < numberOfElements; ++i) {
        if (val[i])
          byte |= (1 << i % 8);
        if (i % 8 === 7 || i == numberOfElements - 1) {
          Uint8.encode(this, byte);
          byte = 0;
        }
      }
    } else {
      for (var i = 0; i < numberOfElements; ++i)
        cls.encode(this, val[i]);
    }
  };

  Encoder.prototype.encodeStruct = function(cls, val) {
    return cls.encode(this, val);
  };

  Encoder.prototype.encodeStructPointer = function(cls, val) {
    if (val == null) {
      // Also handles undefined, since undefined == null.
      this.encodePointer(val);
      return;
    }
    var encoder = this.createAndEncodeEncoder(cls.encodedSize);
    cls.encode(encoder, val);
  };

  Encoder.prototype.encodeArrayPointer = function(cls, val) {
    if (val == null) {
      // Also handles undefined, since undefined == null.
      this.encodePointer(val);
      return;
    }

    var numberOfElements = val.length;
    if (!Number.isSafeInteger(numberOfElements) || numberOfElements < 0)
      throw new Error(kErrorArray);

    var encodedSize = kArrayHeaderSize + ((cls === PackedBool) ?
        Math.ceil(numberOfElements / 8) : cls.encodedSize * numberOfElements);
    var encoder = this.createAndEncodeEncoder(encodedSize);
    encoder.encodeArray(cls, val, numberOfElements, encodedSize);
  };

  Encoder.prototype.encodeStringPointer = function(val) {
    if (val == null) {
      // Also handles undefined, since undefined == null.
      this.encodePointer(val);
      return;
    }
    // Only accepts string primivites, not String Objects like new String("foo")
    if (typeof(val) !== "string") {
      throw new Error(kErrorString);
    }
    var encodedSize = kArrayHeaderSize + unicode.utf8Length(val);
    var encoder = this.createAndEncodeEncoder(encodedSize);
    encoder.encodeString(val);
  };

  Encoder.prototype.encodeMap = function(keyClass, valueClass, val) {
    var keys = new Array(val.size);
    var values = new Array(val.size);
    var i = 0;
    val.forEach(function(value, key) {
      values[i] = value;
      keys[i++] = key;
    });
    this.writeUint32(kStructHeaderSize + kMapStructPayloadSize);
    this.writeUint32(0);  // version
    this.encodeArrayPointer(keyClass, keys);
    this.encodeArrayPointer(valueClass, values);
  }

  Encoder.prototype.encodeMapPointer = function(keyClass, valueClass, val) {
    if (val == null) {
      // Also handles undefined, since undefined == null.
      this.encodePointer(val);
      return;
    }
    if (!(val instanceof Map)) {
      throw new Error(kErrorMap);
    }
    var encodedSize = kStructHeaderSize + kMapStructPayloadSize;
    var encoder = this.createAndEncodeEncoder(encodedSize);
    encoder.encodeMap(keyClass, valueClass, val);
  };

  // Message ------------------------------------------------------------------

  var kMessageNameOffset = kStructHeaderSize;
  var kMessageFlagsOffset = kMessageNameOffset + 4;
  var kMessageRequestIDOffset = kMessageFlagsOffset + 4;

  var kMessageExpectsResponse = 1 << 0;
  var kMessageIsResponse      = 1 << 1;

  function Message(buffer, handles) {
    this.buffer = buffer;
    this.handles = handles;
  }

  Message.prototype.getHeaderNumBytes = function() {
    return this.buffer.getUint32(kStructHeaderNumBytesOffset);
  };

  Message.prototype.getHeaderVersion = function() {
    return this.buffer.getUint32(kStructHeaderVersionOffset);
  };

  Message.prototype.getName = function() {
    return this.buffer.getUint32(kMessageNameOffset);
  };

  Message.prototype.getFlags = function() {
    return this.buffer.getUint32(kMessageFlagsOffset);
  };

  Message.prototype.isResponse = function() {
    return (this.getFlags() & kMessageIsResponse) != 0;
  };

  Message.prototype.expectsResponse = function() {
    return (this.getFlags() & kMessageExpectsResponse) != 0;
  };

  Message.prototype.setRequestID = function(requestID) {
    // TODO(darin): Verify that space was reserved for this field!
    this.buffer.setUint64(kMessageRequestIDOffset, requestID);
  };


  // MessageBuilder -----------------------------------------------------------

  function MessageBuilder(messageName, payloadSize) {
    // Currently, we don't compute the payload size correctly ahead of time.
    // Instead, we resize the buffer at the end.
    var numberOfBytes = kMessageHeaderSize + payloadSize;
    this.buffer = new buffer.Buffer(numberOfBytes);
    this.handles = [];
    var encoder = this.createEncoder(kMessageHeaderSize);
    encoder.writeUint32(kMessageHeaderSize);
    encoder.writeUint32(0);  // version.
    encoder.writeUint32(messageName);
    encoder.writeUint32(0);  // flags.
  }

  MessageBuilder.prototype.createEncoder = function(size) {
    var pointer = this.buffer.alloc(size);
    return new Encoder(this.buffer, this.handles, pointer);
  };

  MessageBuilder.prototype.encodeStruct = function(cls, val) {
    cls.encode(this.createEncoder(cls.encodedSize), val);
  };

  MessageBuilder.prototype.finish = function() {
    // TODO(abarth): Rather than resizing the buffer at the end, we could
    // compute the size we need ahead of time, like we do in C++.
    this.buffer.trim();
    var message = new Message(this.buffer, this.handles);
    this.buffer = null;
    this.handles = null;
    this.encoder = null;
    return message;
  };

  // MessageWithRequestIDBuilder -----------------------------------------------

  function MessageWithRequestIDBuilder(messageName, payloadSize, flags,
                                       requestID) {
    // Currently, we don't compute the payload size correctly ahead of time.
    // Instead, we resize the buffer at the end.
    var numberOfBytes = kMessageWithRequestIDHeaderSize + payloadSize;
    this.buffer = new buffer.Buffer(numberOfBytes);
    this.handles = [];
    var encoder = this.createEncoder(kMessageWithRequestIDHeaderSize);
    encoder.writeUint32(kMessageWithRequestIDHeaderSize);
    encoder.writeUint32(1);  // version.
    encoder.writeUint32(messageName);
    encoder.writeUint32(flags);
    encoder.writeUint64(requestID);
  }

  MessageWithRequestIDBuilder.prototype =
      Object.create(MessageBuilder.prototype);

  MessageWithRequestIDBuilder.prototype.constructor =
      MessageWithRequestIDBuilder;

  // MessageReader ------------------------------------------------------------

  function MessageReader(message) {
    this.decoder = new Decoder(message.buffer, message.handles, 0);
    var messageHeaderSize = this.decoder.readUint32();
    this.payloadSize = message.buffer.byteLength - messageHeaderSize;
    var version = this.decoder.readUint32();
    this.messageName = this.decoder.readUint32();
    this.flags = this.decoder.readUint32();
    if (version >= 1)
      this.requestID = this.decoder.readUint64();
    this.decoder.skip(messageHeaderSize - this.decoder.next);
  }

  MessageReader.prototype.decodeStruct = function(cls) {
    return cls.decode(this.decoder);
  };

  // Built-in types -----------------------------------------------------------

  // This type is only used with ArrayOf(PackedBool).
  function PackedBool() {
  }

  function Int8() {
  }

  Int8.encodedSize = 1;

  Int8.decode = function(decoder) {
    return decoder.readInt8();
  };

  Int8.encode = function(encoder, val) {
    encoder.writeInt8(val);
  };

  Uint8.encode = function(encoder, val) {
    encoder.writeUint8(val);
  };

  function Uint8() {
  }

  Uint8.encodedSize = 1;

  Uint8.decode = function(decoder) {
    return decoder.readUint8();
  };

  Uint8.encode = function(encoder, val) {
    encoder.writeUint8(val);
  };

  function Int16() {
  }

  Int16.encodedSize = 2;

  Int16.decode = function(decoder) {
    return decoder.readInt16();
  };

  Int16.encode = function(encoder, val) {
    encoder.writeInt16(val);
  };

  function Uint16() {
  }

  Uint16.encodedSize = 2;

  Uint16.decode = function(decoder) {
    return decoder.readUint16();
  };

  Uint16.encode = function(encoder, val) {
    encoder.writeUint16(val);
  };

  function Int32() {
  }

  Int32.encodedSize = 4;

  Int32.decode = function(decoder) {
    return decoder.readInt32();
  };

  Int32.encode = function(encoder, val) {
    encoder.writeInt32(val);
  };

  function Uint32() {
  }

  Uint32.encodedSize = 4;

  Uint32.decode = function(decoder) {
    return decoder.readUint32();
  };

  Uint32.encode = function(encoder, val) {
    encoder.writeUint32(val);
  };

  function Int64() {
  }

  Int64.encodedSize = 8;

  Int64.decode = function(decoder) {
    return decoder.readInt64();
  };

  Int64.encode = function(encoder, val) {
    encoder.writeInt64(val);
  };

  function Uint64() {
  }

  Uint64.encodedSize = 8;

  Uint64.decode = function(decoder) {
    return decoder.readUint64();
  };

  Uint64.encode = function(encoder, val) {
    encoder.writeUint64(val);
  };

  function String() {
  };

  String.encodedSize = 8;

  String.decode = function(decoder) {
    return decoder.decodeStringPointer();
  };

  String.encode = function(encoder, val) {
    encoder.encodeStringPointer(val);
  };

  function NullableString() {
  }

  NullableString.encodedSize = String.encodedSize;

  NullableString.decode = String.decode;

  NullableString.encode = String.encode;

  function Float() {
  }

  Float.encodedSize = 4;

  Float.decode = function(decoder) {
    return decoder.readFloat();
  };

  Float.encode = function(encoder, val) {
    encoder.writeFloat(val);
  };

  function Double() {
  }

  Double.encodedSize = 8;

  Double.decode = function(decoder) {
    return decoder.readDouble();
  };

  Double.encode = function(encoder, val) {
    encoder.writeDouble(val);
  };

  function PointerTo(cls) {
    this.cls = cls;
  }

  PointerTo.prototype.encodedSize = 8;

  PointerTo.prototype.decode = function(decoder) {
    var pointer = decoder.decodePointer();
    if (!pointer) {
      return null;
    }
    return this.cls.decode(decoder.decodeAndCreateDecoder(pointer));
  };

  PointerTo.prototype.encode = function(encoder, val) {
    if (!val) {
      encoder.encodePointer(val);
      return;
    }
    var objectEncoder = encoder.createAndEncodeEncoder(this.cls.encodedSize);
    this.cls.encode(objectEncoder, val);
  };

  function NullablePointerTo(cls) {
    PointerTo.call(this, cls);
  }

  NullablePointerTo.prototype = Object.create(PointerTo.prototype);

  function ArrayOf(cls, length) {
    this.cls = cls;
    this.length = length || 0;
  }

  ArrayOf.prototype.encodedSize = 8;

  ArrayOf.prototype.dimensions = function() {
    return [this.length].concat(
      (this.cls instanceof ArrayOf) ? this.cls.dimensions() : []);
  }

  ArrayOf.prototype.decode = function(decoder) {
    return decoder.decodeArrayPointer(this.cls);
  };

  ArrayOf.prototype.encode = function(encoder, val) {
    encoder.encodeArrayPointer(this.cls, val);
  };

  function NullableArrayOf(cls) {
    ArrayOf.call(this, cls);
  }

  NullableArrayOf.prototype = Object.create(ArrayOf.prototype);

  function Handle() {
  }

  Handle.encodedSize = 4;

  Handle.decode = function(decoder) {
    return decoder.decodeHandle();
  };

  Handle.encode = function(encoder, val) {
    encoder.encodeHandle(val);
  };

  function NullableHandle() {
  }

  NullableHandle.encodedSize = Handle.encodedSize;

  NullableHandle.decode = Handle.decode;

  NullableHandle.encode = Handle.encode;

  function Interface() {
  }

  Interface.encodedSize = 8;

  Interface.decode = function(decoder) {
    var handle = decoder.decodeHandle();
    // Ignore the version field for now.
    decoder.readUint32();

    return handle;
  };

  Interface.encode = function(encoder, val) {
    encoder.encodeHandle(val);
    // Set the version field to 0 for now.
    encoder.writeUint32(0);
  };

  function NullableInterface() {
  }

  NullableInterface.encodedSize = Interface.encodedSize;

  NullableInterface.decode = Interface.decode;

  NullableInterface.encode = Interface.encode;

  function MapOf(keyClass, valueClass) {
    this.keyClass = keyClass;
    this.valueClass = valueClass;
  }

  MapOf.prototype.encodedSize = 8;

  MapOf.prototype.decode = function(decoder) {
    return decoder.decodeMapPointer(this.keyClass, this.valueClass);
  };

  MapOf.prototype.encode = function(encoder, val) {
    encoder.encodeMapPointer(this.keyClass, this.valueClass, val);
  };

  function NullableMapOf(keyClass, valueClass) {
    MapOf.call(this, keyClass, valueClass);
  }

  NullableMapOf.prototype = Object.create(MapOf.prototype);

  var exports = {};
  exports.align = align;
  exports.isAligned = isAligned;
  exports.Message = Message;
  exports.MessageBuilder = MessageBuilder;
  exports.MessageWithRequestIDBuilder = MessageWithRequestIDBuilder;
  exports.MessageReader = MessageReader;
  exports.kArrayHeaderSize = kArrayHeaderSize;
  exports.kMapStructPayloadSize = kMapStructPayloadSize;
  exports.kStructHeaderSize = kStructHeaderSize;
  exports.kEncodedInvalidHandleValue = kEncodedInvalidHandleValue;
  exports.kMessageHeaderSize = kMessageHeaderSize;
  exports.kMessageWithRequestIDHeaderSize = kMessageWithRequestIDHeaderSize;
  exports.kMessageExpectsResponse = kMessageExpectsResponse;
  exports.kMessageIsResponse = kMessageIsResponse;
  exports.Int8 = Int8;
  exports.Uint8 = Uint8;
  exports.Int16 = Int16;
  exports.Uint16 = Uint16;
  exports.Int32 = Int32;
  exports.Uint32 = Uint32;
  exports.Int64 = Int64;
  exports.Uint64 = Uint64;
  exports.Float = Float;
  exports.Double = Double;
  exports.String = String;
  exports.NullableString = NullableString;
  exports.PointerTo = PointerTo;
  exports.NullablePointerTo = NullablePointerTo;
  exports.ArrayOf = ArrayOf;
  exports.NullableArrayOf = NullableArrayOf;
  exports.PackedBool = PackedBool;
  exports.Handle = Handle;
  exports.NullableHandle = NullableHandle;
  exports.Interface = Interface;
  exports.NullableInterface = NullableInterface;
  exports.MapOf = MapOf;
  exports.NullableMapOf = NullableMapOf;
  return exports;
});
