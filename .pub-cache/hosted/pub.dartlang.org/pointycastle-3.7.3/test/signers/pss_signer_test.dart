// See file LICENSE for more information.

library test.signers.pss_signer_test;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  // Example 1: A 1024-bit RSA keypair
  var pub1 = RSAPublicKey(
    BigInt.parse(
        'a56e4a0e701017589a5187dc7ea841d156f2ec0e36ad52a44dfeb1e61f7ad991d8c51056ffedb162b4c0f283a12a88a394dff526ab7291cbb307ceabfce0b1dfd5cd9508096d5b2b8b6df5d671ef6377c0921cb23c270a70e2598e6ff89d19f105acc2d3f0cb35f29280e1386b6f64c4ef22e1e1f20d0ce8cffb2249bd9a2137',
        radix: 16),
    BigInt.parse('010001', radix: 16),
  );
  var prv1 = RSAPrivateKey(
    BigInt.parse(
        'a56e4a0e701017589a5187dc7ea841d156f2ec0e36ad52a44dfeb1e61f7ad991d8c51056ffedb162b4c0f283a12a88a394dff526ab7291cbb307ceabfce0b1dfd5cd9508096d5b2b8b6df5d671ef6377c0921cb23c270a70e2598e6ff89d19f105acc2d3f0cb35f29280e1386b6f64c4ef22e1e1f20d0ce8cffb2249bd9a2137',
        radix: 16),
    BigInt.parse(
        '33a5042a90b27d4f5451ca9bbbd0b44771a101af884340aef9885f2a4bbe92e894a724ac3c568c8f97853ad07c0266c8c6a3ca0929f1e8f11231884429fc4d9ae55fee896a10ce707c3ed7e734e44727a39574501a532683109c2abacaba283c31b4bd2f53c3ee37e352cee34f9e503bd80c0622ad79c6dcee883547c6a3b325',
        radix: 16),
    BigInt.parse(
        'e7e8942720a877517273a356053ea2a1bc0c94aa72d55c6e86296b2dfc967948c0a72cbccca7eacb35706e09a1df55a1535bd9b3cc34160b3b6dcd3eda8e6443',
        radix: 16),
    BigInt.parse(
        'b69dca1cf7d4d7ec81e75b90fcca874abcde123fd2700180aa90479b6e48de8d67ed24f9f19d85ba275874f542cd20dc723e6963364a1f9425452b269a6799fd',
        radix: 16),
  );

  var slt1a =
      createUint8ListFromHexString('dee959c7e06411361420ff80185ed57f3e6776af');
  var msg1a = createUint8ListFromHexString(
      'cdc87da223d786df3b45e0bbbc721326d1ee2af806cc315475cc6f0d9c66e1b62371d45ce2392e1ac92844c310102f156a0d8d52c1f4c40ba3aa65095786cb769757a6563ba958fed0bcc984e8b517a3d5f515b23b8a41e74aa867693f90dfb061a6e86dfaaee64472c00e5f20945729cbebe77f06ce78e08f4098fba41f9d6193c0317e8b60d4b6084acb42d29e3808a3bc372d85e331170fcbf7cc72d0b71c296648b3a4d10f416295d0807aa625cab2744fd9ea8fd223c42537029828bd16be02546f130fd2e33b936d2676e08aed1b73318b750a0167d0');
  var sig1a = createUint8ListFromHexString(
      '9074308fb598e9701b2294388e52f971faac2b60a5145af185df5287b5ed2887e57ce7fd44dc8634e407c8e0e4360bc226f3ec227f9d9e54638e8d31f5051215df6ebb9c2f9579aa77598a38f914b5b9c1bd83c4e2f9f382a0d0aa3542ffee65984a601bc69eb28deb27dca12c82c2d4c3f66cd500f1ff2b994d8a4e30cbb33c');

  var msg1b = createUint8ListFromHexString(
      '851384cdfe819c22ed6c4ccb30daeb5cf059bc8e1166b7e3530c4c233e2b5f8f71a1cca582d43ecc72b1bca16dfc7013226b9e');
  var slt1b =
      createUint8ListFromHexString('ef2869fa40c346cb183dab3d7bffc98fd56df42d');
  var sig1b = createUint8ListFromHexString(
      '3ef7f46e831bf92b32274142a585ffcefbdca7b32ae90d10fb0f0c729984f04ef29a9df0780775ce43739b97838390db0a5505e63de927028d9d29b219ca2c4517832558a55d694a6d25b9dab66003c4cccd907802193be5170d26147d37b93590241be51c25055f47ef62752cfbe21418fafe98c22c4d4d47724fdb5669e843');

  // Example 2: A 1025-bit RSA keypair
  var pub2 = RSAPublicKey(
      BigInt.parse(
          '01d40c1bcf97a68ae7cdbd8a7bf3e34fa19dcca4ef75a47454375f94514d88fed006fb829f8419ff87d6315da68a1ff3a0938e9abb3464011c303ad99199cf0c7c7a8b477dce829e8844f625b115e5e9c4a59cf8f8113b6834336a2fd2689b472cbb5e5cabe674350c59b6c17e176874fb42f8fc3d176a017edc61fd326c4b33c9',
          radix: 16),
      BigInt.parse('010001', radix: 16));
  var prv2 = RSAPrivateKey(
    BigInt.parse(
        '01d40c1bcf97a68ae7cdbd8a7bf3e34fa19dcca4ef75a47454375f94514d88fed006fb829f8419ff87d6315da68a1ff3a0938e9abb3464011c303ad99199cf0c7c7a8b477dce829e8844f625b115e5e9c4a59cf8f8113b6834336a2fd2689b472cbb5e5cabe674350c59b6c17e176874fb42f8fc3d176a017edc61fd326c4b33c9',
        radix: 16),
    BigInt.parse(
        '027d147e4673057377fd1ea201565772176a7dc38358d376045685a2e787c23c15576bc16b9f444402d6bfc5d98a3e88ea13ef67c353eca0c0ddba9255bd7b8bb50a644afdfd1dd51695b252d22e7318d1b6687a1c10ff75545f3db0fe602d5f2b7f294e3601eab7b9d1cecd767f64692e3e536ca2846cb0c2dd486a39fa75b1',
        radix: 16),
    BigInt.parse(
        '016601e926a0f8c9e26ecab769ea65a5e7c52cc9e080ef519457c644da6891c5a104d3ea7955929a22e7c68a7af9fcad777c3ccc2b9e3d3650bce404399b7e59d1',
        radix: 16),
    BigInt.parse(
        '014eafa1d4d0184da7e31f877d1281ddda625664869e8379e67ad3b75eae74a580e9827abd6eb7a002cb5411f5266797768fb8e95ae40e3e8a01f35ff89e56c079',
        radix: 16),
  );

  var msg2a = createUint8ListFromHexString(
      'daba032066263faedb659848115278a52c44faa3a76f37515ed336321072c40a9d9b53bc05014078adf520875146aae70ff060226dcb7b1f1fc27e9360');
  var slt2a =
      createUint8ListFromHexString('57bf160bcb02bb1dc7280cf0458530b7d2832ff7');
  var sig2a = createUint8ListFromHexString(
      '014c5ba5338328ccc6e7a90bf1c0ab3fd606ff4796d3c12e4b639ed9136a5fec6c16d8884bdd99cfdc521456b0742b736868cf90de099adb8d5ffd1deff39ba4007ab746cefdb22d7df0e225f54627dc65466131721b90af445363a8358b9f607642f78fab0ab0f43b7168d64bae70d8827848d8ef1e421c5754ddf42c2589b5b3');

  var msg2b = createUint8ListFromHexString(
      'e4f8601a8a6da1be34447c0959c058570c3668cfd51dd5f9ccd6ad4411fe8213486d78a6c49f93efc2ca2288cebc2b9b60bd04b1e220d86e3d4848d709d032d1e8c6a070c6af9a499fcf95354b14ba6127c739de1bb0fd16431e46938aec0cf8ad9eb72e832a7035de9b7807bdc0ed8b68eb0f5ac2216be40ce920c0db0eddd3860ed788efaccaca502d8f2bd6d1a7c1f41ff46f1681c8f1f818e9c4f6d91a0c7803ccc63d76a6544d843e084e363b8acc55aa531733edb5dee5b5196e9f03e8b731b3776428d9e457fe3fbcb3db7274442d785890e9cb0854b6444dace791d7273de1889719338a77fe');
  var slt2b =
      createUint8ListFromHexString('7f6dd359e604e60870e898e47b19bf2e5a7b2a90');
  var sig2b = createUint8ListFromHexString(
      '010991656cca182b7f29d2dbc007e7ae0fec158eb6759cb9c45c5ff87c7635dd46d150882f4de1e9ae65e7f7d9018f6836954a47c0a81a8a6b6f83f2944d6081b1aa7c759b254b2c34b691da67cc0226e20b2f18b42212761dcd4b908a62b371b5918c5742af4b537e296917674fb914194761621cc19a41f6fb953fbcbb649dea');

  //  Example 4: A 1027-bit RSA key pair
  var pub4 = RSAPublicKey(
      BigInt.parse(
          '054adb7886447efe6f57e0368f06cf52b0a3370760d161cef126b91be7f89c421b62a6ec1da3c311d75ed50e0ab5fff3fd338acc3aa8a4e77ee26369acb81ba900fa83f5300cf9bb6c53ad1dc8a178b815db4235a9a9da0c06de4e615ea1277ce559e9c108de58c14a81aa77f5a6f8d1335494498848c8b95940740be7bf7c3705',
          radix: 16),
      BigInt.parse('010001', radix: 16));
  var prv4 = RSAPrivateKey(
    BigInt.parse(
        '054adb7886447efe6f57e0368f06cf52b0a3370760d161cef126b91be7f89c421b62a6ec1da3c311d75ed50e0ab5fff3fd338acc3aa8a4e77ee26369acb81ba900fa83f5300cf9bb6c53ad1dc8a178b815db4235a9a9da0c06de4e615ea1277ce559e9c108de58c14a81aa77f5a6f8d1335494498848c8b95940740be7bf7c3705',
        radix: 16),
    BigInt.parse(
        'fa041f8cd9697ceed38ec8caa275523b4dd72b09a301d3541d72f5d31c05cbce2d6983b36183af10690bd46c46131e35789431a556771dd0049b57461bf060c1f68472e8a67c25f357e5b6b4738fa541a730346b4a07649a2dfa806a69c975b6aba64678acc7f5913e89c622f2d8abb1e3e32554e39df94ba60c002e387d9011',
        radix: 16),
    BigInt.parse(
        '029232336d2838945dba9dd7723f4e624a05f7375b927a87abe6a893a1658fd49f47f6c7b0fa596c65fa68a23f0ab432962d18d4343bd6fd671a5ea8d148413995',
        radix: 16),
    BigInt.parse(
        '020ef5efe7c5394aed2272f7e81a74f4c02d145894cb1b3cab23a9a0710a2afc7e3329acbb743d01f680c4d02afb4c8fde7e20930811bb2b995788b5e872c20bb1',
        radix: 16),
  );

  var msg4a = createUint8ListFromHexString('9fb03b827c8217d9');
  var slt4a =
      createUint8ListFromHexString('ed7c98c95f30974fbe4fbddcf0f28d6021c0e91d');
  var sig4a = createUint8ListFromHexString(
      '0323d5b7bf20ba4539289ae452ae4297080feff4518423ff4811a817837e7d82f1836cdfab54514ff0887bddeebf40bf99b047abc3ecfa6a37a3ef00f4a0c4a88aae0904b745c846c4107e8797723e8ac810d9e3d95dfa30ff4966f4d75d13768d20857f2b1406f264cfe75e27d7652f4b5ed3575f28a702f8c4ed9cf9b2d44948');

  var msg4b = createUint8ListFromHexString(
      '0ca2ad77797ece86de5bf768750ddb5ed6a3116ad99bbd17edf7f782f0db1cd05b0f677468c5ea420dc116b10e80d110de2b0461ea14a38be68620392e7e893cb4ea9393fb886c20ff790642305bf302003892e54df9f667509dc53920df583f50a3dd61abb6fab75d600377e383e6aca6710eeea27156e06752c94ce25ae99fcbf8592dbe2d7e27453cb44de07100ebb1a2a19811a478adbeab270f94e8fe369d90b3ca612f9f');
  var slt4b =
      createUint8ListFromHexString('22d71d54363a4217aa55113f059b3384e3e57e44');
  var sig4b = createUint8ListFromHexString(
      '049d0185845a264d28feb1e69edaec090609e8e46d93abb38371ce51f4aa65a599bdaaa81d24fba66a08a116cb644f3f1e653d95c89db8bbd5daac2709c8984000178410a7c6aa8667ddc38c741f710ec8665aa9052be929d4e3b16782c1662114c5414bb0353455c392fc28f3db59054b5f365c49e1d156f876ee10cb4fd70598');

  // Example 8: A 1031-bit RSA key pair
  var pub8 = RSAPublicKey(
      BigInt.parse(
          '495370a1fb18543c16d3631e3163255df62be6eee890d5f25509e4f778a8ea6fbbbcdf85dff64e0d972003ab3681fbba6dd41fd541829b2e582de9f2a4a4e0a2d0900bef4753db3cee0ee06c7dfae8b1d53b5953218f9cceea695b08668edeaadced9463b1d790d5ebf27e9115b46cad4d9a2b8efab0561b0810344739ada0733f',
          radix: 16),
      BigInt.parse('010001', radix: 16));
  var prv8 = RSAPrivateKey(
    BigInt.parse(
        '495370a1fb18543c16d3631e3163255df62be6eee890d5f25509e4f778a8ea6fbbbcdf85dff64e0d972003ab3681fbba6dd41fd541829b2e582de9f2a4a4e0a2d0900bef4753db3cee0ee06c7dfae8b1d53b5953218f9cceea695b08668edeaadced9463b1d790d5ebf27e9115b46cad4d9a2b8efab0561b0810344739ada0733f',
        radix: 16),
    BigInt.parse(
        '6c66ffe98980c38fcdeab5159898836165f4b4b817c4f6a8d486ee4ea9130fe9b9092bd136d184f95f504a607eac565846d2fdd6597a8967c7396ef95a6eeebb4578a643966dca4d8ee3de842de63279c618159c1ab54a89437b6a6120e4930afb52a4ba6ced8a4947ac64b30a3497cbe701c2d6266d517219ad0ec6d347dbe9',
        radix: 16),
    BigInt.parse(
        '08dad7f11363faa623d5d6d5e8a319328d82190d7127d2846c439b0ab72619b0a43a95320e4ec34fc3a9cea876422305bd76c5ba7be9e2f410c8060645a1d29edb',
        radix: 16),
    BigInt.parse(
        '0847e732376fc7900f898ea82eb2b0fc418565fdae62f7d9ec4ce2217b97990dd272db157f99f63c0dcbb9fbacdbd4c4dadb6df67756358ca4174825b48f49706d',
        radix: 16),
  );

  var msg8a = createUint8ListFromHexString(
      '81332f4be62948415ea1d899792eeacf6c6e1db1da8be13b5cea41db2fed467092e1ff398914c714259775f595f8547f735692a575e6923af78f22c6997ddb90fb6f72d7bb0dd5744a31decd3dc3685849836ed34aec596304ad11843c4f88489f209735f5fb7fdaf7cec8addc5818168f880acbf490d51005b7a8e84e43e54287977571dd99eea4b161eb2df1f5108f12a4142a83322edb05a75487a3435c9a78ce53ed93bc550857d7a9fb');
  var slt8a =
      createUint8ListFromHexString('1d65491d79c864b373009be6f6f2467bac4c78fa');
  var sig8a = createUint8ListFromHexString(
      '0262ac254bfa77f3c1aca22c5179f8f040422b3c5bafd40a8f21cf0fa5a667ccd5993d42dbafb409c520e25fce2b1ee1e716577f1efa17f3da28052f40f0419b23106d7845aaf01125b698e7a4dfe92d3967bb00c4d0d35ba3552ab9a8b3eef07c7fecdbc5424ac4db1e20cb37d0b2744769940ea907e17fbbca673b20522380c5');

  var msg8b = createUint8ListFromHexString(
      'e2f96eaf0e05e7ba326ecca0ba7fd2f7c02356f3cede9d0faabf4fcc8e60a973e5595fd9ea08');
  var slt8b =
      createUint8ListFromHexString('435c098aa9909eb2377f1248b091b68987ff1838');
  var sig8b = createUint8ListFromHexString(
      '2707b9ad5115c58c94e932e8ec0a280f56339e44a1b58d4ddcff2f312e5f34dcfe39e89c6a94dcee86dbbdae5b79ba4e0819a9e7bfd9d982e7ee6c86ee68396e8b3a14c9c8f34b178eb741f9d3f121109bf5c8172fada2e768f9ea1433032c004a8aa07eb990000a48dc94c8bac8aabe2b09b1aa46c0a2aa0e12f63fbba775ba7e');

  // Example 9: A 1536-bit RSA key pair
  var pub9 = RSAPublicKey(
      BigInt.parse(
          'e6bd692ac96645790403fdd0f5beb8b9bf92ed10007fc365046419dd06c05c5b5b2f48ecf989e4ce269109979cbb40b4a0ad24d22483d1ee315ad4ccb1534268352691c524f6dd8e6c29d224cf246973aec86c5bf6b1401a850d1b9ad1bb8cbcec47b06f0f8c7f45d3fc8f319299c5433ddbc2b3053b47ded2ecd4a4caefd614833dc8bb622f317ed076b8057fe8de3f84480ad5e83e4a61904a4f248fb397027357e1d30e463139815c6fd4fd5ac5b8172a45230ecb6318a04f1455d84e5a8b',
          radix: 16),
      BigInt.parse('010001', radix: 16));
  var prv9 = RSAPrivateKey(
    BigInt.parse(
        'e6bd692ac96645790403fdd0f5beb8b9bf92ed10007fc365046419dd06c05c5b5b2f48ecf989e4ce269109979cbb40b4a0ad24d22483d1ee315ad4ccb1534268352691c524f6dd8e6c29d224cf246973aec86c5bf6b1401a850d1b9ad1bb8cbcec47b06f0f8c7f45d3fc8f319299c5433ddbc2b3053b47ded2ecd4a4caefd614833dc8bb622f317ed076b8057fe8de3f84480ad5e83e4a61904a4f248fb397027357e1d30e463139815c6fd4fd5ac5b8172a45230ecb6318a04f1455d84e5a8b',
        radix: 16),
    BigInt.parse(
        '6a7fd84fb85fad073b34406db74f8d61a6abc12196a961dd79565e9da6e5187bce2d980250f7359575359270d91590bb0e427c71460b55d51410b191bcf309fea131a92c8e702738fa719f1e0041f52e40e91f229f4d96a1e6f172e15596b4510a6daec26105f2bebc53316b87bdf21311666070e8dfee69d52c71a976caae79c72b68d28580dc686d9f5129d225f82b3d615513a882b3db91416b48ce08888213e37eeb9af800d81cab328ce420689903c00c7b5fd31b75503a6d419684d629',
        radix: 16),
    BigInt.parse(
        'f8eb97e98df12664eefdb761596a69ddcd0e76daece6ed4bf5a1b50ac086f7928a4d2f8726a77e515b74da41988f220b1cc87aa1fc810ce99a82f2d1ce821edced794c6941f42c7a1a0b8c4d28c75ec60b652279f6154a762aed165d47dee367',
        radix: 16),
    BigInt.parse(
        'ed4d71d0a6e24b93c2e5f6b4bbe05f5fb0afa042d204fe3378d365c2f288b6a8dad7efe45d153eef40cacc7b81ff934002d108994b94a5e4728cd9c963375ae49965bda55cbf0efed8d6553b4027f2d86208a6e6b489c176128092d629e49d3d',
        radix: 16),
  );

  var msg9a = createUint8ListFromHexString(
      'a88e265855e9d7ca36c68795f0b31b591cd6587c71d060a0b3f7f3eaef43795922028bc2b6ad467cfc2d7f659c5385aa70ba3672cdde4cfe4970cc7904601b278872bf51321c4a972f3c95570f3445d4f57980e0f20df54846e6a52c668f1288c03f95006ea32f562d40d52af9feb32f0fa06db65b588a237b34e592d55cf979f903a642ef64d2ed542aa8c77dc1dd762f45a59303ed75e541ca271e2b60ca709e44fa0661131e8d5d4163fd8d398566ce26de8730e72f9cca737641c244159420637028df0a18079d6208ea8b4711a2c750f5');
  var slt9a =
      createUint8ListFromHexString('c0a425313df8d7564bd2434d311523d5257eed80');
  var sig9a = createUint8ListFromHexString(
      '586107226c3ce013a7c8f04d1a6a2959bb4b8e205ba43a27b50f124111bc35ef589b039f5932187cb696d7d9a32c0c38300a5cdda4834b62d2eb240af33f79d13dfbf095bf599e0d9686948c1964747b67e89c9aba5cd85016236f566cc5802cb13ead51bc7ca6bef3b94dcbdbb1d570469771df0e00b1a8a06777472d2316279edae86474668d4e1efff95f1de61c6020da32ae92bbf16520fef3cf4d88f61121f24bbd9fe91b59caf1235b2a93ff81fc403addf4ebdea84934a9cdaf8e1a9e');

  var msg9b = createUint8ListFromHexString(
      'c8c9c6af04acda414d227ef23e0820c3732c500dc87275e95b0d095413993c2658bc1d988581ba879c2d201f14cb88ced153a01969a7bf0a7be79c84c1486bc12b3fa6c59871b6827c8ce253ca5fefa8a8c690bf326e8e37cdb96d90a82ebab69f86350e1822e8bd536a2e');
  var slt9b =
      createUint8ListFromHexString('b307c43b4850a8dac2f15f32e37839ef8c5c0e91');
  var sig9b = createUint8ListFromHexString(
      '80b6d643255209f0a456763897ac9ed259d459b49c2887e5882ecb4434cfd66dd7e1699375381e51cd7f554f2c271704b399d42b4be2540a0eca61951f55267f7c2878c122842dadb28b01bd5f8c025f7e228418a673c03d6bc0c736d0a29546bd67f786d9d692ccea778d71d98c2063b7a71092187a4d35af108111d83e83eae46c46aa34277e06044589903788f1d5e7cee25fb485e92949118814d6f2c3ee361489016f327fb5bc517eb50470bffa1afa5f4ce9aa0ce5b8ee19bf5501b958');

  group('RSA/PSS', () {
    // TODO: Unify signer test infrastructure.
    group('example 1', () {
      _testSign('a', Signer('SHA-1/PSS'), prv1, pub1, msg1a, slt1a, sig1a);
      _testSign('b', Signer('SHA-1/PSS'), prv1, pub1, msg1b, slt1b, sig1b);
    });

    group('example 2', () {
      _testSign('a', Signer('SHA-1/PSS'), prv2, pub2, msg2a, slt2a, sig2a);
      _testSign('b', Signer('SHA-1/PSS'), prv2, pub2, msg2b, slt2b, sig2b);
    });

    group('example 4', () {
      _testSign('a', Signer('SHA-1/PSS'), prv4, pub4, msg4a, slt4a, sig4a);
      _testSign('b', Signer('SHA-1/PSS'), prv4, pub4, msg4b, slt4b, sig4b);
    });

    group('example 8', () {
      _testSign('a', Signer('SHA-1/PSS'), prv8, pub8, msg8a, slt8a, sig8a);
      _testSign('b', Signer('SHA-1/PSS'), prv8, pub8, msg8b, slt8b, sig8b);
    });

    group('example 9', () {
      _testSign('a', Signer('SHA-1/PSS'), prv9, pub9, msg9a, slt9a, sig9a);
      _testSign('b', Signer('SHA-1/PSS'), prv9, pub9, msg9b, slt9b, sig9b);
    });
  });
}

var pubParams = (RSAPublicKey pubk, Uint8List salt) => () => ParametersWithSalt(
      PublicKeyParameter<RSAPublicKey>(pubk),
      salt,
    );
var privParams = (RSAPrivateKey privk, Uint8List salt) =>
    () => ParametersWithSalt(PrivateKeyParameter<RSAPrivateKey>(privk), salt);

void _testSign(
    String testName,
    Signer signer,
    RSAPrivateKey privateKey,
    RSAPublicKey publicKey,
    Uint8List message,
    Uint8List salt,
    Uint8List expectedSignatureBytes) {
  test(testName, () {
    signer.init(true, privParams(privateKey, salt)());
    var signature = signer.generateSignature(message);
    var expectedSignature = PSSSignature(expectedSignatureBytes);
    expect(signature, equals(expectedSignature));

    signer.init(false, pubParams(publicKey, salt)());
    expect(signer.verifySignature(message, expectedSignature), isTrue);
  });
}
