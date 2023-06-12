// See file LICENSE for more information.

library test.digests.sha224_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('SHA-224'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '10cffc69eddba6e8eafae57155284bd074778e0903e251ea9c8f9f62',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    'f62bf1175f02176cfb00c370aea1c7203ba45a91cf776535380ab1a5',
  ]);
}
