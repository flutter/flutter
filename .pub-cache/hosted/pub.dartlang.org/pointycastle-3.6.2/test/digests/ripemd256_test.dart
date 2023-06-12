// See file LICENSE for more information.

library test.digests.ripemd256_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('RIPEMD-256'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '5bca9a62d8c446acea2716a6634bed99ae9c240ebadf584b277397028bbe74de',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    'b12cc8c54ad8e14e9cbaa8bdd1d78139880fc824a2af19c67699d64fb4322cc2',
  ]);
}
