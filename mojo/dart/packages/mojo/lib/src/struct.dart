// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

abstract class Struct {
  final int encodedSize;

  Struct(this.encodedSize);

  static StructDataHeader checkVersion(
      Decoder decoder, List<StructDataHeader> knownVersions) {
    var mainDataHeader = decoder.decodeStructDataHeader();
    if (mainDataHeader.version <= knownVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = knownVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= knownVersions[i].version) {
          if (mainDataHeader.size == knownVersions[i].size) {
            // Found a match.
            break;
          }
          throw new MojoCodecError(
              "Header size doesn't correspond to known version size.");
        }
      }
    } else if (mainDataHeader.size < knownVersions.last.size) {
      throw new MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    return mainDataHeader;
  }

  static dynamic deserialize(dynamic decode(Decoder d), Message message) {
    var decoder = new Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static void fixErrorMessage(
      MojoCodecError e, String fieldName, String structName) {
    e.message = "Error encountered while encoding field $fieldName "
                "of struct $structName: $e";
  }

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
