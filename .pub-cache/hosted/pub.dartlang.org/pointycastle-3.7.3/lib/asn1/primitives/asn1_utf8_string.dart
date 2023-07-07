import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/asn1_utils.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 UTF8 String object
///
class ASN1UTF8String extends ASN1Object {
  ///
  /// The decoded string value
  ///
  String? utf8StringValue;

  ///
  /// A list of elements. Only set if this ASN1UTF8String is constructed, otherwhise null.
  ///
  List<ASN1Object>? elements;

  ///
  /// Creates an empty [ASN1UTF8String] entity with only the [tag] set.
  ///
  ASN1UTF8String(
      {this.utf8StringValue, this.elements, int tag = ASN1Tags.UTF8_STRING})
      : super(tag: tag);

  ///
  /// Creates an [ASN1UTF8String] entity from the given [encodedBytes].
  ///
  ASN1UTF8String.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    if (ASN1Utils.isConstructed(encodedBytes.elementAt(0))) {
      elements = [];
      var parser = ASN1Parser(valueBytes);
      var sb = StringBuffer();
      while (parser.hasNext()) {
        var utf8String = parser.nextObject() as ASN1UTF8String;
        sb.write(utf8String.utf8StringValue);
        elements!.add(utf8String);
      }
      utf8StringValue = sb.toString();
    } else {
      utf8StringValue = utf8.decode(valueBytes!);
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
        var octets = utf8.encode(utf8StringValue!);
        valueByteLength = octets.length;
        valueBytes = Uint8List.fromList(octets);
        break;
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH:
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED:
        valueByteLength = 0;
        if (elements == null) {
          elements!.add(ASN1UTF8String(utf8StringValue: utf8StringValue));
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
      sb.write('UTF8STRING (${elements!.length} elem)');
      for (var e in elements!) {
        var dump = e.dump(spaces: spaces + dumpIndent);
        sb.write('\n$dump');
      }
    } else {
      sb.write('UTF8STRING $utf8StringValue');
    }
    return sb.toString();
  }
}
