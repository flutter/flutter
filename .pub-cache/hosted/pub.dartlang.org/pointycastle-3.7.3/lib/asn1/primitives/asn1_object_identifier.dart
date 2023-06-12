import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/object_identifiers.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';
import 'package:pointycastle/asn1/unsupported_object_identifier_exception.dart';

class ASN1ObjectIdentifier extends ASN1Object {
  ///
  /// The object identifier integer values
  ///
  List<int>? objectIdentifier;

  ///
  /// The String representation of the [objectIdentifier]
  ///
  String? objectIdentifierAsString;

  ///
  /// The readable representation of the [objectIdentifier]
  ///
  String? readableName;

  ///
  /// Create an [ASN1ObjectIdentifier] entity with the given [objectIdentifier].
  ///
  ASN1ObjectIdentifier(this.objectIdentifier,
      {int tag = ASN1Tags.OBJECT_IDENTIFIER})
      : super(tag: tag) {
    objectIdentifierAsString = objectIdentifier!.join('.');
  }

  ///
  /// Creates an [ASN1ObjectIdentifier] entity from the given [encodedBytes].
  ///
  ASN1ObjectIdentifier.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    var value = 0;
    var first = true;
    BigInt? bigValue;
    var list = <int>[];
    var sb = StringBuffer();
    valueBytes!.forEach((element) {
      var b = element & 0xff;
      if (value < 0x80000000000000) {
        value = value * 128 + (b & 0x7f);
        if ((b & 0x80) == 0) {
          if (first) {
            var truncated = value ~/ 40;
            if (truncated < 2) {
              list.add(truncated);
              sb.write(truncated);
              value -= truncated * 40;
            } else {
              list.add(2);
              sb.write('2');
              value -= 80;
            }
            first = false;
          }
          list.add(value);
          sb.write('.$value');
          value = 0;
        }
      } else {
        bigValue ??= BigInt.from(value);
        bigValue = bigValue! << (7);
        bigValue = bigValue! | BigInt.from(b & 0x7f);
        if ((b & 0x80) == 0) {
          sb.write('.$bigValue');
          bigValue = null;
          value = 0;
        }
      }
    });
    objectIdentifierAsString = sb.toString();
    objectIdentifier = Uint8List.fromList(list);
    var identifier =
        ObjectIdentifiers.getIdentifierByIdentifier(objectIdentifierAsString);
    if (identifier != null) {
      readableName = identifier['readableName'] as String?;
    }
  }

  ///
  /// Creates an [ASN1ObjectIdentifier] entity from the given [name].
  ///
  /// Example:
  /// ```
  /// var oi = ASN1ObjectIdentifier.fromName('ecdsaWithSHA256');
  /// ```
  ///
  /// Throws an [UnsupportedObjectIdentifierException] if the given [name] is not supported
  ///
  ASN1ObjectIdentifier.fromName(String name) {
    tag = ASN1Tags.OBJECT_IDENTIFIER;
    var identifier = ObjectIdentifiers.getIdentifierByName(name);
    if (identifier == null) {
      throw UnsupportedObjectIdentifierException(name);
    }
    objectIdentifierAsString = identifier['identifierString'] as String?;
    readableName = identifier['readableName'] as String?;
    objectIdentifier = identifier['identifier'] as List<int>?;
  }

  ///
  /// Creates an [ASN1ObjectIdentifier] entity from the given [objectIdentifierAsString].
  ///
  /// Example:
  /// ```
  /// var oi = ASN1ObjectIdentifier.fromName('2.5.4.3');
  /// ```
  ///
  /// Throws an [UnsupportedObjectIdentifierException] if the given [objectIdentifierAsString] is not supported
  ///
  ASN1ObjectIdentifier.fromIdentifierString(this.objectIdentifierAsString,
      {int tag = ASN1Tags.OBJECT_IDENTIFIER})
      : super(tag: tag) {
    var identifier =
        ObjectIdentifiers.getIdentifierByIdentifier(objectIdentifierAsString);
    if (identifier != null) {
      objectIdentifierAsString = identifier['identifierString'] as String?;
      readableName = identifier['readableName'] as String?;
      objectIdentifier = identifier['identifier'] as List<int>?;
    } else {
      var splittedInts = objectIdentifierAsString!.split('.');
      objectIdentifier = <int>[];
      for (var i in splittedInts) {
        objectIdentifier!.add(int.parse(i));
      }
    }
  }

  ///
  /// Encodes this ASN1Object depending on the given [encodingRule]
  ///
  /// If no [ASN1EncodingRule] is given, ENCODING_DER will be used.
  ///
  /// Supported encoding rules are :
  /// * [ASN1EncodingRule.ENCODING_DER]
  ///
  /// Throws an [UnsupportedAsn1EncodingRuleException] if the given [encodingRule] is not supported.
  ///
  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    if (encodingRule != ASN1EncodingRule.ENCODING_DER) {
      throw UnsupportedAsn1EncodingRuleException(encodingRule);
    }
    var oi = <int>[];
    oi.add(objectIdentifier![0] * 40 + objectIdentifier![1]);

    for (var ci = 2; ci < objectIdentifier!.length; ci++) {
      var position = oi.length;
      var v = objectIdentifier![ci];
      assert(v >= 0);

      var first = true;
      do {
        var remainder = v & 127;
        v = v >> 7;
        if (first) {
          first = false;
        } else {
          remainder |= 0x80;
        }

        oi.insert(position, remainder);
      } while (v > 0);
    }

    valueBytes = Uint8List.fromList(oi);
    valueByteLength = oi.length;

    return super.encode();
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    sb.write('OBJECT IDENTIFIER $objectIdentifierAsString $readableName');
    return sb.toString();
  }
}
