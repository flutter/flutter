// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

abstract class Struct {
  final int encodedSize;

  Struct(this.encodedSize);

  void encode(Encoder encoder);

  Message serialize() {
    var encoder = new Encoder(encodedSize);
    encode(encoder);
    return encoder.message;
  }

  ServiceMessage serializeWithHeader(MessageHeader header) {
    var encoder = new Encoder(encodedSize + header.size);
    header.encode(encoder);
    encode(encoder);
    return new ServiceMessage(encoder.message, header);
  }
}
