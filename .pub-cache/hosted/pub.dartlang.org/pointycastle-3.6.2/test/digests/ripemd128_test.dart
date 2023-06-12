// See file LICENSE for more information.

library test.digests.ripemd128_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('RIPEMD-128'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '3e67e64143573d714263ed98b8d85c1d',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    '6a022533ba64455b63cdadbdc57dcc3d',
  ]);
}
