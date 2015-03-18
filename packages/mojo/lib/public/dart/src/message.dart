// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

class MessageHeader {
  static const int kSimpleMessageSize = 16;
  // TODO(yzshen): In order to work with other bindings which still interprets
  // the |version| field as |num_fields|, set it to version 2 for now.
  static const int kSimpleMessageVersion = 2;
  static const int kMessageWithRequestIdSize = 24;
  // TODO(yzshen): In order to work with other bindings which still interprets
  // the |version| field as |num_fields|, set it to version 3 for now.
  static const int kMessageWithRequestIdVersion = 3;
  static const int kMessageTypeOffset = StructDataHeader.kHeaderSize;
  static const int kMessageFlagsOffset = kMessageTypeOffset + 4;
  static const int kMessageRequestIdOffset = kMessageFlagsOffset + 4;
  static const int kMessageExpectsResponse = 1 << 0;
  static const int kMessageIsResponse = 1 << 1;

  StructDataHeader _header;
  int type;
  int flags;
  int requestId;

  static bool mustHaveRequestId(int flags) =>
      (flags & (kMessageExpectsResponse | kMessageIsResponse)) != 0;

  MessageHeader(this.type)
      : _header = new StructDataHeader(
          kSimpleMessageSize, kSimpleMessageVersion),
        flags = 0,
        requestId = 0;

  MessageHeader.withRequestId(this.type, this.flags, this.requestId)
      : _header = new StructDataHeader(
          kMessageWithRequestIdSize, kMessageWithRequestIdVersion);

  MessageHeader.fromMessage(Message message) {
    var decoder = new Decoder(message);
    _header = decoder.decodeStructDataHeader();
    if (_header.size < kSimpleMessageSize) {
      throw new MojoCodecError('Incorrect message size. Got: ${_header.size} '
          'wanted $kSimpleMessageSize');
    }
    type = decoder.decodeUint32(kMessageTypeOffset);
    flags = decoder.decodeUint32(kMessageFlagsOffset);
    if (mustHaveRequestId(flags)) {
      if (_header.size < kMessageWithRequestIdSize) {
        throw new MojoCodecError('Incorrect message size. Got: ${_header.size} '
            'wanted $kMessageWithRequestIdSize');
      }
      requestId = decoder.decodeUint64(kMessageRequestIdOffset);
    } else {
      requestId = 0;
    }
  }

  int get size => _header.size;
  bool get hasRequestId => mustHaveRequestId(flags);

  void encode(Encoder encoder) {
    encoder.encodeStructDataHeader(_header);
    encoder.encodeUint32(type, kMessageTypeOffset);
    encoder.encodeUint32(flags, kMessageFlagsOffset);
    if (hasRequestId) {
      encoder.encodeUint64(requestId, kMessageRequestIdOffset);
    }
  }

  String toString() => "MessageHeader($_header, $type, $flags, $requestId)";

  bool validateHeaderFlags(expectedFlags) =>
      (flags & (kMessageExpectsResponse | kMessageIsResponse)) == expectedFlags;

  bool validateHeader(int expectedType, int expectedFlags) =>
      (type == expectedType) && validateHeaderFlags(expectedFlags);

  static void _validateDataHeader(StructDataHeader dataHeader) {
    if (dataHeader.version < kSimpleMessageVersion) {
      throw 'Incorrect version, expecting at least '
          '$kSimpleMessageVersion, but got: ${dataHeader.version}.';
    }
    if (dataHeader.size < kSimpleMessageSize) {
      throw 'Incorrect message size, expecting at least $kSimpleMessageSize, '
          'but got: ${dataHeader.size}';
    }
    if ((dataHeader.version == kSimpleMessageVersion) &&
        (dataHeader.size != kSimpleMessageSize)) {
      throw 'Incorrect message size for a message of version '
          '$kSimpleMessageVersion, expecting $kSimpleMessageSize, '
          'but got ${dataHeader.size}';
    }
    if ((dataHeader.version == kMessageWithRequestIdVersion) &&
        (dataHeader.size != kMessageWithRequestIdSize)) {
      throw 'Incorrect message size for a message of version '
          '$kMessageWithRequestIdVersion, expecting '
          '$kMessageWithRequestIdSize, but got ${dataHeader.size}';
    }
  }
}

class Message {
  final ByteData buffer;
  final List<core.MojoHandle> handles;
  Message(this.buffer, this.handles);
  String toString() =>
      "Message(numBytes=${buffer.lengthInBytes}, numHandles=${handles.length})";
}

class ServiceMessage extends Message {
  final MessageHeader header;
  Message _payload;

  ServiceMessage(Message message, this.header)
      : super(message.buffer, message.handles);

  ServiceMessage.fromMessage(Message message)
      : this(message, new MessageHeader.fromMessage(message));

  Message get payload {
    if (_payload == null) {
      var truncatedBuffer = new ByteData.view(buffer.buffer, header.size);
      _payload = new Message(truncatedBuffer, handles);
    }
    return _payload;
  }

  String toString() => "ServiceMessage($header, $_payload)";
}
