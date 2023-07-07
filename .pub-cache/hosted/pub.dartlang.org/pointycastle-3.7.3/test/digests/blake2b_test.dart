// See file LICENSE for more information.

library test.digests.blake2b_test;

import 'dart:typed_data';

import 'package:pointycastle/digests/blake2b.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/runners/digest.dart';
import '../test/src/helpers.dart';

void main() {
  group('PR108 regression test', () {
    test("vectors from: https://blake2.net/blake2b-test.txt", () {
      var vec = [
        [
          '',
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f',
          '10ebb67700b1868efb4417987acf4690ae9d972fb7a590c2f02871799aaa4786b5e996e8f0f4eb981fc214b005f42d2ff4233499391653df7aefcbc13fc51568',
        ],
        [
          '00',
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f',
          '961f6dd1e4dd30f63901690c512e78e4b45e4742ed197c3c5e45c549fd25f2e4187b0bc9fe30492b16b0d0bc4ef9b0f34c7003fac09a5ef1532e69430234cebd',
        ],
        [
          '0001',
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f',
          'da2cfbe2d8409a0f38026113884f84b50156371ae304c4430173d08a99d9fb1b983164a3770706d537f49e0c916d9f32b95cc37a95b99d857436f0232c88a965'
        ],
        [
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d',
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f',
          'f1aa2b044f8f0c638a3f362e677b5d891d6fd2ab0765f6ee1e4987de057ead357883d9b405b9d609eea1b869d97fb16d9b51017c553f3b93c0a1e0f1296fedcd'
        ],
        [
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3',
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f',
          'c230f0802679cb33822ef8b3b21bf7a9a28942092901d7dac3760300831026cf354c9232df3e084d9903130c601f63c1f4a4a4b8106e468cd443bbe5a734f45f'
        ],
        [
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfe',
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f',
          '142709d62e28fcccd0af97fad0f8465b971e82201dc51070faa0372aa43e92484be1c1e73ba10906d5d1853db6a4106e0a7bf9800d373d6dee2d46d62ef2a461'
        ]
      ];

      vec.forEach((set) {
        var input = createUint8ListFromHexString(set[0]);
        var key = createUint8ListFromHexString(set[1]);
        var dig = Blake2bDigest(key: key);
        dig.update(input, 0, input.length);
        var res = Uint8List(64);
        dig.doFinal(res, 0);
        var expected = createUint8ListFromHexString(set[2]);
        expect(res, equals(expected));
      });
    });
  });

  runDigestTests(Digest('Blake2b'), [
    '',
    '786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    'b26dc06e2a96f3a2d16313b8633e79c438317ba399ed143aa0a695c2c14df01bf7870ad2ee09b3ef7f0d36bba5c98541cbce3c6e802790b402534f757d2085d3',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
    'c782dabd3cabf2e74f2b6e9854fc6f274583cb77003e20625ec19efad78993480c237594841cef9933ac7a675a526426460d87bc0ef4538ed08d0e2744a22900',
    'Lorem ipsum dolor sit amet, ex has ignota maluisset persecuti. Cum ad integre splendide adipiscing. An sit ipsum possim, dicunt ',
    'ee370c9780381c360feeedc04fff3caa17687cde31e8a541d0a0053c3b92c0195d0f64e27126cba2e79f1b007f3ec9ab66f5fd9bca416654a05cfd94cb8da2be',
    'Lorem ipsum dolor sit amet, ex has ignota maluisset persecuti. Cum ad integre splendide adipiscing. An sit ipsum possim, dicunt eirmod habemus mea at, in sea alii dolorem deterruisset. An habeo fabellas facilisis eum, aperiri imperdiet definitiones eum no. Aeque delicata eos et. Fierent platonem cum id.',
    '79ca22680c4a9b72299eb22d173222b309d9f2b90f9f16bc170a143482d62b23029b6712758bf6135659adeeeaf8ad472b746674b5e10b7a4cb6b803b88c19db',
  ]);
}
