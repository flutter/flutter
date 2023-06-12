// See file LICENSE for more information.

library test.digests.md4_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('MD4'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '1d6839cb198b77f5d9a027a5ed1989d7',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    '95cdeefe499f74582d2894436cfbb989',
  ]);
}
