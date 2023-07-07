import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/asn1_utils.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 Octed String object
///
class ASN1OctetString extends ASN1Object {
  ///
  /// The decoded string value
  ///
  Uint8List? octets;

  ///
  /// A list of elements. Only set if this ASN1OctetString is constructed, otherwhise null.
  ///
  List<ASN1Object>? elements;

  ///
  /// Create an [ASN1OctetString] entity with the given [octets].
  ///
  ASN1OctetString({this.octets, this.elements, int tag = ASN1Tags.OCTET_STRING})
      : super(tag: tag);

  ///
  /// Creates an [ASN1OctetString] entity from the given [encodedBytes].
  ///
  ASN1OctetString.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    if (ASN1Utils.isConstructed(encodedBytes.elementAt(0))) {
      elements = [];
      var parser = ASN1Parser(valueBytes);
      var bytes = <int>[];
      while (parser.hasNext()) {
        var octetString = parser.nextObject() as ASN1OctetString;
        bytes.addAll(octetString.octets!);
        elements!.add(octetString);
      }
      octets = Uint8List.fromList(bytes);
    } else {
      octets = valueBytes;
    }
  }

  ///
  /// Encodes this ASN1Object depending on the given [encodingRule]
  ///
  /// If no [ASN1EncodingRule] is given, ENCODING_DER will be used.
  ///
  /// Supported encoding rules are :
  /// * [ASN1EncodingRule.ENCODING_DER]
  /// * [ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM]
  /// * [ASN1EncodingRule.ENCODING_BER_CONSTRUCTED]
  /// * [ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH]
  ///
  /// Throws an [UnsupportedAsn1EncodingRuleException] if the given [encodingRule] is not supported.
  ///
  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    switch (encodingRule) {
      case ASN1EncodingRule.ENCODING_DER:
      case ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM:
        valueByteLength = octets!.length;
        valueBytes = octets;
        break;
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED:
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH:
        valueByteLength = 0;
        if (elements == null) {
          elements!.add(ASN1OctetString(octets: octets));
        }
        valueByteLength = _childLength(
            isIndefinite: encodingRule ==
                ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH);
        valueBytes = Uint8List(valueByteLength!);
        var i = 0;
        elements!.forEach((obj) {
          var b = obj.encode();
          valueBytes!.setRange(i, i + b.length, b);
          i += b.length;
        });
        break;
      case ASN1EncodingRule.ENCODING_BER_PADDED:
        throw UnsupportedAsn1EncodingRuleException(encodingRule);
    }
    return super.encode(encodingRule: encodingRule);
  }

  ///
  /// Calculate encoded length of all children
  ///
  int _childLength({bool isIndefinite = false}) {
    var l = 0;
    elements!.forEach((ASN1Object obj) {
      l += obj.encode().length;
    });
    if (isIndefinite) {
      return l + 2;
    }
    return l;
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    if (isConstructed!) {
      sb.write('OCTET STRING (${elements!.length} elem)');
      for (var e in elements!) {
        var dump = e.dump(spaces: spaces + dumpIndent);
        sb.write('\n $dump');
      }
    } else {
      sb.write('OCTET STRING (${octets!.length} byte) ');
      for (var o in octets!) {
        var s = o.toRadixString(16).toUpperCase();
        if (s.length == 1) {
          s = '0$s';
        }
        sb.write(s);
      }
    }
    return sb.toString();
  }
}
