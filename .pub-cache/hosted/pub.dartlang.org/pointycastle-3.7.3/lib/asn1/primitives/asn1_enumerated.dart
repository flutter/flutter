import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';

///
/// An ASN1Enumerated object
///
class ASN1Enumerated extends ASN1Integer {
  ///
  /// Create an [ASN1Enumerated] entity with the given integer [i].
  ///
  ASN1Enumerated(int i, {int tag = ASN1Tags.ENUMERATED})
      : super(BigInt.from(i), tag: tag);

  ///
  /// Creates an [ASN1Enumerated] entity from the given [encodedBytes].
  ///
  ASN1Enumerated.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes);
}
