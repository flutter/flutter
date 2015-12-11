// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

class MessageHeader {
  static const int kSimpleMessageSize = 16;
  static const int kSimpleMessageVersion = 0;
  static const int kMessageWithRequestIdSize = 24;
  static const int kMessageWithRequestIdVersion = 1;
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
      : _header =
            new StructDataHeader(kSimpleMessageSize, kSimpleMessageVersion),
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
}

class Message {
  final ByteData buffer;
  final List<core.MojoHandle> handles;
  final dataLength;
  final handlesLength;
  Message(this.buffer, this.handles, this.dataLength, this.handlesLength);
  String toString() =>
      "Message(numBytes=${dataLength}, numHandles=${handlesLength})";
}

class ServiceMessage extends Message {
  final MessageHeader header;
  Message _payload;

  ServiceMessage(Message message, this.header)
      : super(message.buffer, message.handles, message.dataLength,
            message.handlesLength);

  ServiceMessage.fromMessage(Message message)
      : this(message, new MessageHeader.fromMessage(message));

  Message get payload {
    if (_payload == null) {
      var truncatedBuffer = new ByteData.view(
          buffer.buffer, header.size, dataLength - header.size);
      _payload = new Message(
          truncatedBuffer, handles, dataLength - header.size, handlesLength);
    }
    return _payload;
  }

  String toString() => "ServiceMessage($header, $_payload)";
}
