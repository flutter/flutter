// See file LICENSE for more information.

library test.digests.md2_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('MD2'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '70bdf19ce16c171706e9ef02219f35a8',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    '2b6aa7a2fe344c9bd4844c73c306a26a',
  ]);
}
