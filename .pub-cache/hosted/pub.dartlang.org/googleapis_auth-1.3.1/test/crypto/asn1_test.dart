// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:googleapis_auth/src/crypto/asn1.dart';
import 'package:test/test.dart';

void main() {
  void expectArgumentError(List<int> bytes) {
    expect(() => ASN1Parser.parse(Uint8List.fromList(bytes)),
        throwsA(isArgumentError));
  }

  void invalidLenTest(int tagBytes) {
    test('invalid-len', () {
      expectArgumentError([tagBytes]);
      expectArgumentError([tagBytes, 0x07]);
      expectArgumentError([tagBytes, 0x82]);
      expectArgumentError([tagBytes, 0x82, 1]);
      expectArgumentError([tagBytes, 0x01, 1, 2, 3, 4]);
    });
  }

  group('asn1-parser', () {
    group('sequence', () {
      test('empty', () {
        final sequenceBytes = [ASN1Parser.sequenceTag, 0];
        final sequence = ASN1Parser.parse(Uint8List.fromList(sequenceBytes));
        expect(sequence is ASN1Sequence, isTrue);
        expect((sequence as ASN1Sequence).objects, isEmpty);
      });

      test('one-element', () {
        final sequenceBytes = [
          ASN1Parser.sequenceTag,
          1,
          ASN1Parser.nullTag,
          0
        ];
        final sequence = ASN1Parser.parse(Uint8List.fromList(sequenceBytes));
        expect(sequence is ASN1Sequence, isTrue);
        expect((sequence as ASN1Sequence).objects, hasLength(1));
        expect(sequence.objects[0] is ASN1Null, isTrue);
      });

      test('many-elements', () {
        final sequenceBytes = [ASN1Parser.sequenceTag, 0x82, 0x01, 0x00];
        for (var i = 0; i < 128; i++) {
          sequenceBytes.addAll([ASN1Parser.nullTag, 0]);
        }

        final sequence = ASN1Parser.parse(Uint8List.fromList(sequenceBytes));
        expect(sequence is ASN1Sequence, isTrue);
        expect((sequence as ASN1Sequence).objects.length, equals(128));
        for (var i = 0; i < 128; i++) {
          expect(sequence.objects[i] is ASN1Null, isTrue);
        }
      });

      invalidLenTest(ASN1Parser.sequenceTag);
    });

    group('integer', () {
      test('small', () {
        for (var i = 0; i < 256; i++) {
          final integerBytes = [ASN1Parser.integerTag, 1, i];
          final integer =
              ASN1Parser.parse(Uint8List.fromList(integerBytes)) as ASN1Integer;
          expect(integer.integer, BigInt.from(i));
        }
      });

      test('multi-byte', () {
        final integerBytes = [ASN1Parser.integerTag, 3, 1, 2, 3];
        final integer = ASN1Parser.parse(Uint8List.fromList(integerBytes));
        expect(integer is ASN1Integer, isTrue);
        expect((integer as ASN1Integer).integer, BigInt.from(0x010203));
      });

      invalidLenTest(ASN1Parser.integerTag);
    });

    group('octet-string', () {
      test('small', () {
        final octetStringBytes = [ASN1Parser.octetStringTag, 3, 1, 2, 3];
        final octetString =
            ASN1Parser.parse(Uint8List.fromList(octetStringBytes));
        expect(octetString is ASN1OctetString, isTrue);
        expect((octetString as ASN1OctetString).bytes, equals([1, 2, 3]));
      });

      test('large', () {
        final octetStringBytes = [ASN1Parser.octetStringTag, 0x82, 0x01, 0x00];
        for (var i = 0; i < 256; i++) {
          octetStringBytes.add(i % 256);
        }

        final octetString =
            ASN1Parser.parse(Uint8List.fromList(octetStringBytes));
        expect(octetString is ASN1OctetString, isTrue);
        final castedOctetString = octetString as ASN1OctetString;
        for (var i = 0; i < 256; i++) {
          expect(castedOctetString.bytes[i], equals(i % 256));
        }
      });

      invalidLenTest(ASN1Parser.octetStringTag);
    });

    group('oid', () {
      // NOTE: Currently the oid is parsed as normal bytes, so we don't validate
      // the oid structure.
      test('small', () {
        final objIdBytes = [ASN1Parser.objectIdTag, 3, 1, 2, 3];
        final objId = ASN1Parser.parse(Uint8List.fromList(objIdBytes));
        expect(objId is ASN1ObjectIdentifier, isTrue);
        expect((objId as ASN1ObjectIdentifier).bytes, equals([1, 2, 3]));
      });

      test('large', () {
        final objIdBytes = [ASN1Parser.objectIdTag, 0x82, 0x01, 0x00];
        for (var i = 0; i < 256; i++) {
          objIdBytes.add(i % 256);
        }

        final objId = ASN1Parser.parse(Uint8List.fromList(objIdBytes));
        expect(objId is ASN1ObjectIdentifier, isTrue);
        final castedObjId = objId as ASN1ObjectIdentifier;
        for (var i = 0; i < 256; i++) {
          expect(castedObjId.bytes[i], equals(i % 256));
        }
      });

      invalidLenTest(ASN1Parser.objectIdTag);
    });
  });

  test('null', () {
    final objId =
        ASN1Parser.parse(Uint8List.fromList([ASN1Parser.nullTag, 0x00]));
    expect(objId is ASN1Null, isTrue);

    expectArgumentError([ASN1Parser.nullTag]);
    expectArgumentError([ASN1Parser.nullTag, 0x01]);
  });
}
