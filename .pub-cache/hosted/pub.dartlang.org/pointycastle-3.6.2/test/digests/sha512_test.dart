// See file LICENSE for more information.

library test.digests.sha512_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('SHA-512'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '7a61cb16b6c459d0894ba7ce01a50a43036da9f77e9a27c2e17d563c7eca877fa9e1d91968f5c61552a62f72deb07c5f6c00f8f43d0c3dccd46dfcc248b29b0e',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    'f221fdceac5a63b712f303b444cf8aeacdc5a58835c340469772075430ddc43d983891458e543b0abd8c4acb71d69a808e292a86eaef1c1b1ddc83a567d8a346',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...Lorem ipsum dolor sit amet, consectetur adipiscing elit...Lorem ipsum dolor sit amet, consectetur adipiscing elit...Lorem ipsum dolor sit amet, consectetur adipiscing elit...Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '04e576a2c557a86d7ee178d4fe8adde77ab9c9b0ce8f3a5c51818f6e52b0a79fc79131ba7fda51a26c9ed6533a6954fc46ad31f90dce9c7c9671c47426296d7e',
  ]);
}
