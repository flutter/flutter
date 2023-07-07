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
class ASN1BMPString extends ASN1Object {
  ///
  /// The ascii decoded string value
  ///
  String? stringValue;

  ///
  /// A list of elements. Only set if this ASN1BMPString is constructed, otherwhise null.
  ///
  List<ASN1Object>? elements;

  ///
  /// Create an [ASN1BMPString] entity with the given [stringValue].
  ///
  ASN1BMPString(
      {this.stringValue, this.elements, int tag = ASN1Tags.BMP_STRING})
      : super(tag: tag);

  ///
  /// Creates an [ASN1BMPString] entity from the given [encodedBytes].
  ///
  ASN1BMPString.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    if (ASN1Utils.isConstructed(encodedBytes.elementAt(0))) {
      elements = [];
      var parser = ASN1Parser(valueBytes);
      var sb = StringBuffer();
      while (parser.hasNext()) {
        var bmpString = parser.nextObject() as ASN1BMPString;
        sb.write(bmpString.stringValue);
        elements!.add(bmpString);
      }
      stringValue = sb.toString();
    } else {
      var sb = StringBuffer();
      for (var b in valueBytes!) {
        if (b != 0) {
          sb.write(ascii.decode([b]));
        }
      }
      stringValue = sb.toString();
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
        var l = <int>[];
        for (var c in stringValue!.codeUnits) {
          l.add(0);
          l.add(c);
        }
        valueBytes = Uint8List.fromList(l);
        break;
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH:
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED:
        valueByteLength = 0;
        if (elements == null) {
          elements!.add(ASN1BMPString(stringValue: stringValue));
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
      sb.write('BMPString (${elements!.length} elem)');
      for (var e in elements!) {
        var dump = e.dump(spaces: spaces + dumpIndent);
        sb.write('\n $dump');
      }
    } else {
      sb.write('BMPString $stringValue');
    }
    return sb.toString();
  }
}
