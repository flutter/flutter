// See file LICENSE for more information.

library test.digests.tiger_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('Tiger'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    'c9a8c5f0ce21cd25d1158c7b9b9ef043437ef0e2bce65cca',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    '8edc9820300d6453f6784523bbf32d9e44ce20fbec7b07f8',
  ]);
}
