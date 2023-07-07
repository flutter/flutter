// See file LICENSE for more information.

library test.digests.sha512t_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/digest.dart';

void main() {
  runDigestTests(Digest('SHA-512/224'), [
    '',
    '6ed0dd02806fa89e25de060c19d3ac86cabb87d6a0ddd05c333b84f4',
    'abc',
    '4634270f707b6a54daae7530460842e20e37ed265ceee9a43e8924aa',
    'abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu',
    '23fec5bb94d60b23308192640b0c453335d664734fe40e7268674af9',
  ]);

  runDigestTests(Digest('SHA-512/256'), [
    '',
    'c672b8d1ef56ed28ab87c3622c5114069bdd3ad7b8f9737498d0c01ecef0967a',
    'abc',
    '53048e2681941ef99b2e29b76b4c7dabe4c2d0c634fc6d46e0e2f13107e7af23',
    'abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu',
    '3928e184fb8690f840da3988121d31be65cb9d3ef83ee6146feac861e19b563a',
  ]);

  runDigestTests(Digest('SHA-512/488'), [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '77c5a401110133e531d1acf33ea6010d8d8149f9804310b6d32a69033aee079e88603166478069b1d4622030a508930a062199150f66462e26063266e5',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    '149a6a1e7f9741b56186b01c9195e1c5a003197ff559604653ea176c6d6e75c7cd117d3105cf10bc8d1f24e46c98c5a8b2fa2e53c16e95ada867b20ea1',
  ]);
}
