import 'package:pointycastle/export.dart';

import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  group('RC4 Engine', () {
    streamCipherTest(
        0,
        RC4Engine(),
        KeyParameter(
          createUint8ListFromHexString('0123456789ABCDEF'),
        ),
        '4e6f772069732074',
        '3afbb5c77938280d');
    streamCipherTest(
        1,
        RC4Engine(),
        KeyParameter(
          createUint8ListFromHexString('0123456789ABCDEF'),
        ),
        '68652074696d6520',
        '1cf1e29379266d59');
    streamCipherTest(
        3,
        RC4Engine(),
        KeyParameter(
          createUint8ListFromHexString('0123456789ABCDEF'),
        ),
        '666f7220616c6c20',
        '12fbb0c771276459');
  });
}
