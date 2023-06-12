// See file LICENSE for more information.

library test.digests.md5_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('MD5'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    'b4dbd72756e62ad118c9759446956d15',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    'dc4381c2a676fdcd92fad9ba4b97116d',
  ]);
}
