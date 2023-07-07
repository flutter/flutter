import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 Boolean object
///
class ASN1Boolean extends ASN1Object {
  bool? boolValue;

  ///
  /// The byte to use for the TRUE value
  ///
  static const int BOOLEAN_TRUE_VALUE = 0xff;

  ///
  /// The byte to use for the FALSE value
  ///
  static const int BOOLEAN_FALSE_VALUE = 0x00;

  ///
  /// Creates an [ASN1Boolean] entity with the given [boolValue].
  ///
  ASN1Boolean(this.boolValue, {int tag = ASN1Tags.BOOLEAN}) : super(tag: tag);

  ///
  /// Creates an [ASN1Boolean] entity from the given [encodedBytes].
  ///
  ASN1Boolean.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    boolValue = (valueBytes![0] == BOOLEAN_TRUE_VALUE);
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
    valueByteLength = 1;
    valueBytes = (boolValue == true)
        ? Uint8List.fromList([BOOLEAN_TRUE_VALUE])
        : Uint8List.fromList([BOOLEAN_FALSE_VALUE]);
    return super.encode();
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    sb.write('BOOLEAN $boolValue');
    return sb.toString();
  }
}
