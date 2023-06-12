// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'rsa.dart';

// ignore: avoid_classes_with_only_static_members
class ASN1Parser {
  static const integerTag = 0x02;
  static const octetStringTag = 0x04;
  static const nullTag = 0x05;
  static const objectIdTag = 0x06;
  static const sequenceTag = 0x30;

  static ASN1Object parse(Uint8List bytes) {
    Never invalidFormat(String msg) {
      throw ArgumentError('Invalid DER encoding: $msg');
    }

    final data = ByteData.view(bytes.buffer);
    var offset = 0;
    final end = bytes.length;

    void checkNBytesAvailable(int n) {
      if ((offset + n) > end) {
        invalidFormat('Tried to read more bytes than available.');
      }
    }

    List<int> readBytes(int n) {
      checkNBytesAvailable(n);

      final integerBytes = bytes.sublist(offset, offset + n);
      offset += n;
      return integerBytes;
    }

    int readEncodedLength() {
      checkNBytesAvailable(1);

      final lengthByte = data.getUint8(offset++);

      // Short length encoding form: This byte is the length itself.
      if (lengthByte < 0x80) {
        return lengthByte;
      }

      // Long length encoding form:
      // This byte has in bits 0..6 the number of bytes following which encode
      // the length.
      var countLengthBytes = lengthByte & 0x7f;
      checkNBytesAvailable(countLengthBytes);

      var length = 0;
      while (countLengthBytes > 0) {
        length = (length << 8) | data.getUint8(offset++);
        countLengthBytes--;
      }
      return length;
    }

    void readNullBytes() {
      checkNBytesAvailable(1);
      final nullByte = data.getUint8(offset++);
      if (nullByte != 0x00) {
        invalidFormat('Null byte expect, but was: $nullByte.');
      }
    }

    ASN1Object decodeObject() {
      checkNBytesAvailable(1);
      final tag = bytes[offset++];
      switch (tag) {
        case integerTag:
          final size = readEncodedLength();
          return ASN1Integer(RSAAlgorithm.bytes2BigInt(readBytes(size)));
        case octetStringTag:
          final size = readEncodedLength();
          return ASN1OctetString(readBytes(size));
        case nullTag:
          readNullBytes();
          return ASN1Null();
        case objectIdTag:
          final size = readEncodedLength();
          return ASN1ObjectIdentifier(readBytes(size));
        case sequenceTag:
          final lengthInBytes = readEncodedLength();
          if ((offset + lengthInBytes) > end) {
            invalidFormat('Tried to read more bytes than available.');
          }
          final endOfSequence = offset + lengthInBytes;

          final objects = <ASN1Object>[];
          while (offset < endOfSequence) {
            objects.add(decodeObject());
          }
          return ASN1Sequence(objects);
        default:
          invalidFormat(
            'Unexpected tag $tag at offset ${offset - 1} (end: $end).',
          );
      }
    }

    final obj = decodeObject();
    if (offset != bytes.length) {
      throw ArgumentError('More bytes than expected in ASN1 encoding.');
    }
    return obj;
  }
}

abstract class ASN1Object {}

class ASN1Sequence extends ASN1Object {
  final List<ASN1Object> objects;

  ASN1Sequence(this.objects);
}

class ASN1Integer extends ASN1Object {
  final BigInt integer;

  ASN1Integer(this.integer);
}

class ASN1OctetString extends ASN1Object {
  final List<int> bytes;

  ASN1OctetString(this.bytes);
}

class ASN1ObjectIdentifier extends ASN1Object {
  final List<int> bytes;

  ASN1ObjectIdentifier(this.bytes);
}

class ASN1Null extends ASN1Object {}
