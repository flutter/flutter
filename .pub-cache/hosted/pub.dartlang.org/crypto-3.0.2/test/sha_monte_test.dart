import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'utils.dart';

// See https://csrc.nist.gov/Projects/cryptographic-algorithm-validation-program/Secure-Hashing

void main() {
  group('Monte Vectors', () {
    monteTest(
      'sha224',
      sha224,
      'ed2b70d575d9d0b4196ae84a03eed940057ea89cdd729b95b7d4e6a5',
      [
        'cd94d7da13c030208b2d0d78fcfe9ea22fa8906df66aa9a1f42afa70',
        '555846e884633639565d5e0c01dd93ba58edb01ee18e68ccca28f7b8',
        '44d5f4a179b33231f24cc209ed2542ddb931391f2a2d604f80ed460b',
        '18678e3c151f05f92a89fc5b2ec56bfc6fafa66d73ffc1937fcab4d0',
        'b285f829b0499ff45f8454eda2d4e0997b3f438c2728f1a25cfbb05a',
      ],
    );
    monteTest(
      'sha256',
      sha256,
      '6d1e72ad03ddeb5de891e572e2396f8da015d899ef0e79503152d6010a3fe691',
      [
        'e93c330ae5447738c8aa85d71a6c80f2a58381d05872d26bdd39f1fcd4f2b788',
        '2e78f8c8772ea7c9331d41ed3f9cdf27d8f514a99342ee766ee3b8b0d0b121c0',
        'd6a23dff1b7f2eddc1a212f8a218397523a799b07386a30692fd6fe9d2bf0944',
        'fb0099a964fad5a88cf12952f2991ce256a4ac3049f3d389c3b9e6c00e585db4',
        'f9eba2a4cf6263826beaf6150057849eb975a9513c0b76ecad0f1c19ebbad89b',
      ],
    );
    monteTest(
      'sha384',
      sha384,
      'edff07255c71b54a9beae52cdfa083569a08be89949cbba73ddc8acf429359ca5e5be7a673633ca0d9709848f522a9df',
      [
        'e81b86c49a38feddfd185f71ca7da6732a053ed4a2640d52d27f53f9f76422650b0e93645301ac99f8295d6f820f1035',
        '1d6bd21713bffd50946a10c39a7742d740e8f271f0c8f643d4c95375094fd9bf29d89ee61a76053f22e44a4b058a64ed',
        '425167b66ae965bd7d68515b54ebfa16f33d2bdb2147a4eac515a75224cd19cea564d692017d2a1c41c1a3f68bb5a209',
        '9e7477ffd4baad1fcca035f4687b35ed47a57832fb27d131eb8018fcb41edf4d5e25874466d2e2d61ae3accdfc7aa364',
        'd7b4d4e779ca70c8d065630db1f9128ee43b4bde08a81bce13d48659b6ef47b6cfc802af6d8756f6cd43c709bb445bab',
      ],
    );
    monteTest(
      'sha512',
      sha512,
      '5c337de5caf35d18ed90b5cddfce001ca1b8ee8602f367e7c24ccca6f893802fb1aca7a3dae32dcd60800a59959bc540d63237876b799229ae71a2526fbc52cd',
      [
        'ada69add0071b794463c8806a177326735fa624b68ab7bcab2388b9276c036e4eaaff87333e83c81c0bca0359d4aeebcbcfd314c0630e0c2af68c1fb19cc470e',
        'ef219b37c24ae507a2b2b26d1add51b31fb5327eb8c3b19b882fe38049433dbeccd63b3d5b99ba2398920bcefb8aca98cd28a1ee5d2aaf139ce58a15d71b06b4',
        'c3d5087a62db0e5c6f5755c417f69037308cbce0e54519ea5be8171496cc6d18023ba15768153cfd74c7e7dc103227e9eed4b0f82233362b2a7b1a2cbcda9daf',
        'bb3a58f71148116e377505461d65d6c89906481fedfbcfe481b7aa8ceb977d252b3fe21bfff6e7fbf7575ceecf5936bd635e1cf52698c36ef6908ddbd5b6ae05',
        'b68f0cd2d63566b3934a50666dec6d62ca1db98e49d7733084c1f86d91a8a08c756fa7ece815e20930dd7cb66351bad8c087c2f94e8757cb98e7f4b86b21a8a8',
      ],
    );

    monteTest(
      'sha512/224',
      sha512224,
      '2e325bf8c98c0be54493d04c329e706343aebe4968fdd33b37da9c0a',
      [
        '9ee006873962aa0842d636c759646a4ef4b65bcbebcc35430b20f7f4',
        '87726eda4570734b396f4c253146ecb9770b8591739240f02a4f2a02',
        '7be0871653db5fa514b4ec1a0363df004657155575b0383bc9fdec35',
        '7a794a3a1ae255e67ffbf688a05b6aba7f231cebec64b4fc75092d49',
        'aaf5d4ecaf9426149821b15821b41c49e3900c0fc91664fb294216ea',
      ],
    );

    monteTest(
      'sha512/256',
      sha512256,
      'f41ece2613e4573915696b5adcd51ca328be3bf566a9ca99c9ceb0279c1cb0a7',
      [
        'b1d97a6536896aa01098fb2b9e15d8692621c84077051fc1f70a8a48baa6dfaf',
        'a008d2c5adce31a95b30397ac691d8606c6769a47b801441ba3afb7f727c8a9c',
        '8eb896cb2b309db019121eb72564b89c1a59f74d4e2f2f6773c87b98c1997d77',
        'ac71b694438cc300dde0f6f9f548d2304e2bdb6ea45e2b305af5fb3e4ec27761',
        'd47cca4ae027778fc285bc78fb2a9c1cc7cde498267c35157e86b05fc58e698d',
      ],
    );
  });
}

void monteTest(String name, Hash hash, String seed, List<String> expected) {
  test(name, () {
    Iterable<String> run() sync* {
      var _seed = bytesFromHexString(seed);
      for (var j = 0; j < expected.length; j++) {
        Uint8List md0, md1, md2;
        md0 = (Uint8List.fromList(_seed));
        md1 = (Uint8List.fromList(_seed));
        md2 = (Uint8List.fromList(_seed));
        late Digest mdI;
        for (var i = 3; i < 1003; i++) {
          var mI = [...md0, ...md1, ...md2];
          mdI = hash.convert(mI);
          md0.setAll(0, md1);
          md1.setAll(0, md2);
          md2.setAll(0, mdI.bytes);
        }
        yield '$mdI';
        _seed.setAll(0, md2);
      }
    }

    expect(run().toList(), expected);
  });
}
