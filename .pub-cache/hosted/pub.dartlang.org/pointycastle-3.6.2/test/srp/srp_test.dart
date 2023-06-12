library test.srp_test;

import 'dart:typed_data';
import 'package:pointycastle/srp/srp6_client.dart';
import 'package:pointycastle/srp/srp6_server.dart';
import 'package:pointycastle/srp/srp6_standard_groups.dart';
import 'package:pointycastle/srp/srp6_util.dart';
import 'package:pointycastle/srp/srp6_verifier_generator.dart';

import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

void main() {
  group('SRP', () {
    group('rfc5054:', () {
      test('rfc5054AppendixBTestVectors', () {
        var I = Uint8List.fromList('alice'.codeUnits);
        var P = Uint8List.fromList('password123'.codeUnits);
        var s =
            Uint8List.fromList(hex.decode('BEB25379D1A8581EB5A727673A2441EE'));
        var N = SRP6StandardGroups.rfc5054_1024.N;
        var g = SRP6StandardGroups.rfc5054_1024.g;

        var expect_k =
            BigInt.parse('7556AA045AEF2CDD07ABAF0F665C3E818913186F', radix: 16);
        var expect_x =
            BigInt.parse('94B7555AABE9127CC58CCF4993DB6CF84D16C124', radix: 16);
        var expect_v = BigInt.parse(
            '7E273DE8696FFC4F4E337D05B4B375BEB0DDE1569E8FA00A9886D812'
            '9BADA1F1822223CA1A605B530E379BA4729FDC59F105B4787E5186F5'
            'C671085A1447B52A48CF1970B4FB6F8400BBF4CEBFBB168152E08AB5'
            'EA53D15C1AFF87B2B9DA6E04E058AD51CC72BFC9033B564E26480D78'
            'E955A5E29E7AB245DB2BE315E2099AFB',
            radix: 16);
        var expect_A = BigInt.parse(
            '61D5E490F6F1B79547B0704C436F523DD0E560F0C64115BB72557EC4'
            '4352E8903211C04692272D8B2D1A5358A2CF1B6E0BFCF99F921530EC'
            '8E39356179EAE45E42BA92AEACED825171E1E8B9AF6D9C03E1327F44'
            'BE087EF06530E69F66615261EEF54073CA11CF5858F0EDFDFE15EFEA'
            'B349EF5D76988A3672FAC47B0769447B',
            radix: 16);
        var expect_B = BigInt.parse(
            'BD0C61512C692C0CB6D041FA01BB152D4916A1E77AF46AE105393011'
            'BAF38964DC46A0670DD125B95A981652236F99D9B681CBF87837EC99'
            '6C6DA04453728610D0C6DDB58B318885D7D82C7F8DEB75CE7BD4FBAA'
            '37089E6F9C6059F388838E7A00030B331EB76840910440B1B27AAEAE'
            'EB4012B7D7665238A8E3FB004B117B58',
            radix: 16);
        var expect_u =
            BigInt.parse('CE38B9593487DA98554ED47D70A7AE5F462EF019', radix: 16);
        var expect_S = BigInt.parse(
            'B0DC82BABCF30674AE450C0287745E7990A3381F63B387AAF271A10D'
            '233861E359B48220F7C4693C9AE12B0A6F67809F0876E2D013800D6C'
            '41BB59B6D5979B5C00A172B4A2A5903A0BDCAF8A709585EB2AFAFA8F'
            '3499B200210DCC1F10EB33943CD67FC88A2F39A4BE5BEC4EC0A3212D'
            'C346D7E474B29EDE8A469FFECA686E5A',
            radix: 16);

        var k = SRP6Util.calculateK(Digest('SHA-1'), N, g);
        if (k.compareTo(expect_k) != 0) {
          fail("wrong value of 'k', expected $expect_k got $k");
        }

        var x = SRP6Util.calculateX(Digest('SHA-1'), N, s, I, P);
        if (x.compareTo(expect_x) != 0) {
          fail("wrong value of 'x'");
        }

        var gen = SRP6VerifierGenerator(
            group: SRP6StandardGroups.rfc5054_1024, digest: Digest('SHA-1'));
        var v = gen.generateVerifier(s, I, P);
        if (v.compareTo(expect_v) != 0) {
          fail("wrong value of 'v'");
        }

        var client = TestSRP6Client(
            group: SRP6StandardGroups.rfc5054_1024,
            digest: Digest('SHA-1'),
            random: random);

        var A = client.generateClientCredentials(s, I, P);
        if (A!.compareTo(expect_A) != 0) {
          fail("wrong value of 'A'");
        }

        var server = TestSRP6Server(
            group: SRP6StandardGroups.rfc5054_1024,
            v: v,
            digest: Digest('SHA-1'),
            random: random);

        var B = server.generateServerCredentials();
        if (B!.compareTo(expect_B) != 0) {
          fail("wrong value of 'B', expected $expect_B got $B");
        }

        var u = SRP6Util.calculateU(Digest('SHA-1'), N, A, B);
        if (u.compareTo(expect_u) != 0) {
          fail("wrong value of 'u'");
        }

        var clientS = client.calculateSecret(B);
        if (clientS!.compareTo(expect_S) != 0) {
          fail("wrong value of 'S' (client)");
        }

        var serverS = server.calculateSecret(A);
        if (serverS!.compareTo(expect_S) != 0) {
          fail("wrong value of 'S' (server)");
        }
      });
    });

    group('mutual verification:', () {
      test('testMutualVerificationWith1024', () {
        var I = Uint8List.fromList('username'.codeUnits);
        var P = Uint8List.fromList('password'.codeUnits);
        final key = Uint8List.fromList('keywithsixteenth'.codeUnits);
        final keyParam = KeyParameter(key);
        final params = ParametersWithIV(keyParam, Uint8List(16));

        random.seed(params);
        var s = random.nextBytes(16);

        var gen = SRP6VerifierGenerator(
            group: SRP6StandardGroups.rfc5054_1024, digest: Digest('SHA-256'));
        var v = gen.generateVerifier(s, I, P);

        var client = SRP6Client(
            group: SRP6StandardGroups.rfc5054_1024,
            digest: Digest('SHA-256'),
            random: random);

        var server = SRP6Server(
            group: SRP6StandardGroups.rfc5054_1024,
            v: v,
            digest: Digest('SHA-256'),
            random: random);

        var A = client.generateClientCredentials(s, I, P);
        var B = server.generateServerCredentials();

        var clientS = client.calculateSecret(B!);
        var serverS = server.calculateSecret(A!);

        if (clientS!.compareTo(serverS!) != 0) {
          fail(
              'SRP agreement failed - client/server calculated different secrets');
        }
      });

      test('testMutualVerificationWith2048', () {
        var I = Uint8List.fromList('username'.codeUnits);
        var P = Uint8List.fromList('password'.codeUnits);
        final key = Uint8List.fromList('keywithsixteenth'.codeUnits);
        final keyParam = KeyParameter(key);
        final params = ParametersWithIV(keyParam, Uint8List(16));

        random.seed(params);
        var s = random.nextBytes(16);

        var gen = SRP6VerifierGenerator(
            group: SRP6StandardGroups.rfc5054_2048, digest: Digest('SHA-256'));
        var v = gen.generateVerifier(s, I, P);

        var client = SRP6Client(
            group: SRP6StandardGroups.rfc5054_2048,
            digest: Digest('SHA-256'),
            random: random);

        var server = SRP6Server(
            group: SRP6StandardGroups.rfc5054_2048,
            v: v,
            digest: Digest('SHA-256'),
            random: random);

        var A = client.generateClientCredentials(s, I, P);
        var B = server.generateServerCredentials();

        var clientS = client.calculateSecret(B!);
        var serverS = server.calculateSecret(A!);

        if (clientS!.compareTo(serverS!) != 0) {
          fail(
              'SRP agreement failed - client/server calculated different secrets');
        }
        try {
          server.verifyClientEvidenceMessage(
              client.calculateClientEvidenceMessage()!);
        } catch (e) {
          fail("Evidence messages don't match");
        }
      });
    });

    group('client catches bad paramaters:', () {
      test('testClientCatchesBadB', () {
        var I = Uint8List.fromList('username'.codeUnits);
        var P = Uint8List.fromList('password'.codeUnits);
        final key = Uint8List.fromList('keywithsixteenth'.codeUnits);
        final keyParam = KeyParameter(key);
        final params = ParametersWithIV(keyParam, Uint8List(16));

        random.seed(params);
        var s = random.nextBytes(16);

        var standardsGroup = SRP6StandardGroups.rfc5054_1024;
        var client = SRP6Client(
            group: standardsGroup, digest: Digest('SHA-256'), random: random);

        client.generateClientCredentials(s, I, P);

        try {
          client.calculateSecret(BigInt.zero);
          fail("Client failed to detect invalid value for 'B'");
        } catch (e) {
          // Expected
        }

        try {
          client.calculateSecret(standardsGroup.N);
          fail("Client failed to detect invalid value for 'B'");
        } catch (e) {
          // Expected
        }
      });

      test('testServerCatchesBadA', () {
        var I = Uint8List.fromList('username'.codeUnits);
        var P = Uint8List.fromList('password'.codeUnits);
        final key = Uint8List.fromList('keywithsixteenth'.codeUnits);
        final keyParam = KeyParameter(key);
        final params = ParametersWithIV(keyParam, Uint8List(16));

        random.seed(params);
        var s = random.nextBytes(16);

        var standardsGroup = SRP6StandardGroups.rfc5054_1024;
        var gen = SRP6VerifierGenerator(
            digest: Digest('SHA-256'), group: standardsGroup);
        var v = gen.generateVerifier(s, I, P);

        var server = SRP6Server(
            digest: Digest('SHA-256'),
            group: standardsGroup,
            v: v,
            random: random);
        server.generateServerCredentials();

        try {
          server.calculateSecret(BigInt.zero);
          fail("Client failed to detect invalid value for 'A'");
        } catch (e) {
          // Expected
        }

        try {
          server.calculateSecret(standardsGroup.N);
          fail("Client failed to detect invalid value for 'A'");
        } catch (e) {
          // Expected
        }
      });
    });
  });
}

final random = SecureRandom('AES/CTR/AUTO-SEED-PRNG');

class TestSRP6Client extends SRP6Client {
  @override
  var a = BigInt.parse(
      '60975527035CF2AD1989806F0407210BC81EDC04E2762A56AFD529DDDA2D4393',
      radix: 16);

  TestSRP6Client({required SRP6GroupParameters group, digest, random})
      : super(group: group, digest: digest, random: random);

  @override
  BigInt? selectPrivateValue() {
    return a;
  }
}

class TestSRP6Server extends SRP6Server {
  @override
  var b = BigInt.parse(
      'E487CB59D31AC550471E81F00F6928E01DDA08E974A004F49E61F5D105284D20',
      radix: 16);

  TestSRP6Server({required SRP6GroupParameters group, v, digest, random})
      : super(group: group, v: v, digest: digest, random: random);

  @override
  BigInt? selectPrivateValue() {
    return b;
  }
}
