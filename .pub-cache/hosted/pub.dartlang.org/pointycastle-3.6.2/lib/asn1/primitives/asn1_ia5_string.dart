import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/asn1_utils.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 IA5 String object
///
class ASN1IA5String extends ASN1Object {
  ///
  /// The ascii decoded string value
  ///
  String? stringValue;

  ///
  /// A list of elements. Only set if this ASN1IA5String is constructed, otherwhise null.
  ///
  List<ASN1Object>? elements;

  ///
  /// Create an [ASN1IA5String] entity with the given [stringValue].
  ///
  ASN1IA5String(
      {this.stringValue, this.elements, int tag = ASN1Tags.IA5_STRING})
      : super(tag: tag);

  ///
  /// Creates an [ASN1IA5String] entity from the given [encodedBytes].
  ///
  ASN1IA5String.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    if (ASN1Utils.isConstructed(encodedBytes.elementAt(0))) {
      elements = [];
      var parser = ASN1Parser(valueBytes);
      var sb = StringBuffer();
      while (parser.hasNext()) {
        var ia5String = parser.nextObject() as ASN1IA5String;
        sb.write(ia5String.stringValue);
        elements!.add(ia5String);
      }
      stringValue = sb.toString();
    } else {
      stringValue = ascii.decode(valueBytes!);
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
        var octets = ascii.encode(stringValue!);
        valueByteLength = octets.length;
        valueBytes = Uint8List.fromList(octets);
        break;
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH:
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED:
        valueByteLength = 0;
        if (elements == null) {
          elements!.add(ASN1IA5String(stringValue: stringValue));
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
      sb.write('IA5String (${elements!.length} elem)');
      for (var e in elements!) {
        var dump = e.dump(spaces: spaces + dumpIndent);
        sb.write('\n $dump');
      }
    } else {
      sb.write('IA5String $stringValue');
    }
    return sb.toString();
  }
}
