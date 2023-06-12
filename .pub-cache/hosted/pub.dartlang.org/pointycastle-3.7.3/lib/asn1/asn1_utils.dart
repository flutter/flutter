import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/asn1/object_identifiers.dart';
import 'package:pointycastle/ecc/api.dart';

///
/// Utils class holding different methods to ease the handling of ANS1Objects and their byte representation.
///
class ASN1Utils {
  ///
  /// Calculates the start position of the value bytes for the given [encodedBytes].
  ///
  /// It will return 2 if the **length byte** is less than or equal 127 or the length calculate on the **length byte** value.
  /// This will throw a [RangeError] if the given [encodedBytes] has length < 2.
  ///
  static int calculateValueStartPosition(Uint8List encodedBytes) {
    // TODO tag length can be >1
    var length = encodedBytes[1];
    if (length <= 0x7F) {
      return 2;
    } else {
      return 2 + (length & 0x7F);
    }
  }

  ///
  /// Calculates the length of the **value bytes** for the given [encodedBytes].
  ///
  /// Will return **-1** if the length byte equals **0x80**. Throws an [ArgumentError] if the length could not be calculated for the given [encodedBytes].
  ///
  static int decodeLength(Uint8List encodedBytes) {
    var valueStartPosition = 2;
    var length = encodedBytes[1];
    if (length <= 0x7F) {
      return length;
    }
    if (length == 0x80) {
      return -1;
    }
    if (length > 127) {
      var length = encodedBytes[1] & 0x7F;

      var numLengthBytes = length;

      length = 0;
      for (var i = 0; i < numLengthBytes; i++) {
        length <<= 8;
        length |= (encodedBytes[valueStartPosition++] & 0xFF);
      }
      return length;
    }
    throw ArgumentError('Could not calculate the length from the given bytes.');
  }

  ///
  /// Encode the given [length] to byte representation.
  ///
  static Uint8List encodeLength(int length, {bool longform = false}) {
    Uint8List e;
    if (length <= 127 && longform == false) {
      e = Uint8List(1);
      e[0] = length;
    } else {
      var x = Uint32List(1);
      x[0] = length;
      var y = Uint8List.view(x.buffer);
      // Skip null bytes
      var num = 3;
      while (y[num] == 0) {
        --num;
      }
      e = Uint8List(num + 2);
      e[0] = 0x80 + num + 1;
      for (var i = 1; i < e.length; ++i) {
        e[i] = y[num--];
      }
    }
    return e;
  }

  ///
  /// Checks if the given int [i] is constructed according to <https://www.bouncycastle.org/asn1_layman_93.txt> section 3.2.
  ///
  /// The Identifier octets (represented by the given [i]) is marked as constructed if bit 6 has the value **1**.
  ///
  /// Example with the IA5 String tag:
  ///
  /// 0x36 = 0 0 1 1 0 1 1 0
  ///
  /// 0x16 = 0 0 0 1 0 1 1 0
  /// ```
  /// ASN1Utils.isConstructed(0x36);  // true
  /// ASN1Utils.isConstructed(0x16);  // false
  /// ```
  ///
  ///
  static bool isConstructed(int i) {
    // Shift bits
    var newNum = i >> (6 - 1);
    // Check if bit is set to 1
    return (newNum & 1) == 1;
  }

  static bool isASN1Tag(int i) {
    return ASN1Tags.TAGS.contains(i);
  }

  ///
  /// Checks if the given [bytes] ends with 0x00, 0x00
  ///
  static bool hasIndefiniteLengthEnding(Uint8List bytes) {
    var last = bytes.elementAt(bytes.length - 1);
    var lastMinus1 = bytes.elementAt(bytes.length - 2);
    if (last == 0 && lastMinus1 == 0) {
      return true;
    }
    return false;
  }

  static Uint8List getBytesFromPEMString(String pem,
      {bool checkHeader = true}) {
    var lines = LineSplitter.split(pem)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    var base64;
    if (checkHeader) {
      if (lines.length < 2 ||
          !lines.first.startsWith('-----BEGIN') ||
          !lines.last.startsWith('-----END')) {
        throw ArgumentError('The given string does not have the correct '
            'begin/end markers expected in a PEM file.');
      }
      base64 = lines.sublist(1, lines.length - 1).join('');
    } else {
      base64 = lines.join('');
    }

    return Uint8List.fromList(base64Decode(base64));
  }

  static ECPrivateKey ecPrivateKeyFromDerBytes(Uint8List bytes,
      {bool pkcs8 = false}) {
    var asn1Parser = ASN1Parser(bytes);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    var curveName;
    var x;
    if (pkcs8) {
      // Parse the PKCS8 format
      var innerSeq = topLevelSeq.elements!.elementAt(1) as ASN1Sequence;
      var b2 = innerSeq.elements!.elementAt(1) as ASN1ObjectIdentifier;
      var b2Data = b2.objectIdentifierAsString;
      var b2Curvedata = ObjectIdentifiers.getIdentifierByIdentifier(b2Data);
      if (b2Curvedata != null) {
        curveName = b2Curvedata['readableName'];
      }

      var octetString = topLevelSeq.elements!.elementAt(2) as ASN1OctetString;
      asn1Parser = ASN1Parser(octetString.valueBytes);
      var octetStringSeq = asn1Parser.nextObject() as ASN1Sequence;
      var octetStringKeyData =
          octetStringSeq.elements!.elementAt(1) as ASN1OctetString;

      x = octetStringKeyData.valueBytes!;
    } else {
      // Parse the SEC1 format
      var privateKeyAsOctetString =
          topLevelSeq.elements!.elementAt(1) as ASN1OctetString;
      var choice = topLevelSeq.elements!.elementAt(2);
      var s = ASN1Sequence();
      var parser = ASN1Parser(choice.valueBytes);
      while (parser.hasNext()) {
        s.add(parser.nextObject());
      }
      var curveNameOi = s.elements!.elementAt(0) as ASN1ObjectIdentifier;
      var data = ObjectIdentifiers.getIdentifierByIdentifier(
          curveNameOi.objectIdentifierAsString);
      if (data != null) {
        curveName = data['readableName'];
      }

      x = privateKeyAsOctetString.valueBytes!;
    }

    return ECPrivateKey(osp2i(x), ECDomainParameters(curveName));
  }

  static BigInt osp2i(Iterable<int> bytes, {Endian endian = Endian.big}) {
    var result = BigInt.from(0);
    if (endian == Endian.little) {
      bytes = bytes.toList().reversed;
    }

    for (var byte in bytes) {
      result = result << 8;
      result |= BigInt.from(byte);
    }

    return result;
  }
}
