import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';
import 'package:pointycastle/src/utils.dart';

class ASN1Integer extends ASN1Object {
  ///
  /// The integer value
  ///
  BigInt? integer;

  ///
  /// Create an [ASN1Integer] entity with the given BigInt [integer].
  ///
  ASN1Integer(this.integer, {int tag = ASN1Tags.INTEGER}) : super(tag: tag);

  ///
  /// Create an [ASN1Integer] entity with the given int [i].
  ///
  ASN1Integer.fromtInt(int i, {int tag = ASN1Tags.INTEGER}) : super(tag: tag) {
    integer = BigInt.from(i);
  }

  ///
  /// Creates an [ASN1Integer] entity from the given [encodedBytes].
  ///
  ASN1Integer.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    integer = decodeBigInt(valueBytes!);
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
    if (integer!.bitLength == 0) {
      if (integer == BigInt.from(-1)) {
        valueBytes = Uint8List.fromList([0xff]);
      } else {
        valueBytes = Uint8List.fromList([0]);
      }
    } else {
      valueBytes = encodeBigInt(integer);
    }
    valueByteLength = valueBytes!.length;
    return super.encode();
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    sb.write('INTEGER ${integer.toString().toUpperCase()}');
    return sb.toString();
  }
}
