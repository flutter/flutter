import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_utils.dart';

///
/// Base model for all ASN1Objects
///
class ASN1Object {
  ///
  /// The BER tag representing this object.
  ///
  /// For a list of all supported BER tags take a look in the **Asn1Tags** class.
  ///
  int? tag;

  ///
  /// The encoded bytes.
  ///
  Uint8List? encodedBytes;

  ///
  /// The value bytes.
  ///
  Uint8List? valueBytes;

  ///
  /// The index where the value bytes start. This is the position after the tag + length bytes.
  ///
  /// The default value for this field is 2. If the length byte is larger than **127**, the value of this field will increase depending on the length bytes.
  ///
  int valueStartPosition = 2;

  ///
  /// Length of the encoded value bytes.
  ///
  int? valueByteLength;

  ///
  /// Describes if this ASN1 Object is constructed.
  ///
  /// The object is marked as constructed if bit 6 of the [tag] field has value **1**
  ///
  bool? isConstructed;

  int dumpIndent = 2;

  ASN1Object({this.tag}) {
    if (tag != null) {
      isConstructed = ASN1Utils.isConstructed(tag!);
    }
  }

  ///
  /// Creates a new ASN1Object from the given [encodedBytes].
  ///
  /// The first byte will be used as the [tag].The field [valueStartPosition] and [valueByteLength] will be calculated on the given [encodedBytes].
  ///
  ASN1Object.fromBytes(this.encodedBytes) {
    tag = encodedBytes![0];
    isConstructed = ASN1Utils.isConstructed(tag!);
    valueByteLength = ASN1Utils.decodeLength(encodedBytes!);
    valueStartPosition = ASN1Utils.calculateValueStartPosition(encodedBytes!);
    if (valueByteLength == -1) {
      // Indefinite length, check the last to bytes
      if (ASN1Utils.hasIndefiniteLengthEnding(encodedBytes!)) {
        valueByteLength = encodedBytes!.length - 4;
      }
    }
    valueBytes = Uint8List.view(encodedBytes!.buffer,
        valueStartPosition + encodedBytes!.offsetInBytes, valueByteLength);
  }

  ///
  /// Encode the object to their byte representation.
  ///
  /// [encodingRule] defines if the [valueByteLength] should be encoded as indefinite length (0x80) or fixed length with short/long form.
  /// The default is [ASN1EncodingRule.ENCODING_DER] which will automatically decode in definite length with short form.
  ///
  /// **Important note**: Subclasses need to override this method and may call this method. If this method is called by a subclass, the subclass has to set the [valueBytes] before calling super.encode().
  ///
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    if (encodedBytes == null) {
      // Encode the length
      Uint8List lengthAsBytes;
      valueByteLength ??= valueBytes!.length;
      // Check if we have indefinite length or fixed length (short or longform)
      if (encodingRule ==
          ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH) {
        // Set length to 0x80
        lengthAsBytes = Uint8List.fromList([0x80]);
        // Add 2 to the valueByteLength to handle the 0x00, 0x00 at the end
        //valueByteLength = valueByteLength + 2;
      } else {
        lengthAsBytes = ASN1Utils.encodeLength(valueByteLength!,
            longform:
                encodingRule == ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM);
      }
      // Create the Uint8List with the calculated length
      encodedBytes = Uint8List(1 + lengthAsBytes.length + valueByteLength!);
      // Set the tag
      encodedBytes![0] = tag!;
      // Set the length bytes
      encodedBytes!.setRange(1, 1 + lengthAsBytes.length, lengthAsBytes, 0);
      // Set the value bytes
      encodedBytes!.setRange(
          1 + lengthAsBytes.length, encodedBytes!.length, valueBytes!, 0);
    }
    return encodedBytes!;
  }

  ///
  /// The total length of this object, including its value bytes, the encoded tag and length bytes.
  ///
  int get totalEncodedByteLength => valueStartPosition + valueByteLength!;

  ///
  /// Creates a readable dump from the current ASN1Object.
  ///
  /// **Important note**: Subclasses need to override this method. If the ASN1Object is constructed and has child elements, dump() has to be called for each child element.
  ///
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    if (tag == 0xA0 || tag == 0xA3) {
      sb.write('[$tag]');
      var parser = ASN1Parser(valueBytes);
      if (parser.hasNext()) {
        var next = parser.nextObject();
        var dump = next.dump(spaces: spaces + dumpIndent);
        sb.write('\n$dump');
      } else {
        sb.write(' (0 elem)');
      }
    }
    return sb.toString();
  }
}
