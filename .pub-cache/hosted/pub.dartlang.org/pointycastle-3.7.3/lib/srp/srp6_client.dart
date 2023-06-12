library impl.srp_client;

import 'dart:typed_data';

import 'package:pointycastle/srp/srp6_standard_groups.dart';
import 'package:pointycastle/srp/srp6_util.dart';
import 'package:pointycastle/api.dart';

class SRP6Client implements SRPClient {
  late BigInt N;
  late BigInt g;

  BigInt? a;
  BigInt? A;

  BigInt? B;

  BigInt? x;
  BigInt? u;
  BigInt? S;

  BigInt? M1;
  BigInt? M2;
  BigInt? Key;

  Digest digest;
  SecureRandom random;
  SRP6GroupParameters group;

  SRP6Client(
      {required this.group, required this.digest, required this.random}) {
    g = group.g;
    N = group.N;
  }

  @override
  BigInt? calculateClientEvidenceMessage() {
    // Verify pre-requirements
    if (A == null || B == null || S == null) {
      throw Exception(
          'Impossible to compute M1: some data are missing from the previous operations (A,B,S)');
    }
    // compute the client evidence message 'M1'
    M1 = SRP6Util.calculateM1(digest, N, A, B, S);
    return M1;
  }

  ///S = (B - kg^x) ^ (a + ux)
  BigInt? calculateS() {
    var k = SRP6Util.calculateK(digest, N, g);
    var exp = (u! * x!) + a!;
    var tmp = g.modPow(x!, N) * (k % N);

    return (B! - (tmp % (N))).modPow(exp, N);
  }

  @override
  BigInt? calculateSecret(BigInt serverB) {
    B = SRP6Util.validatePublicValue(N, serverB);
    u = SRP6Util.calculateU(digest, N, A, B);
    S = calculateS();
    return S;
  }

  @override
  BigInt? calculateSessionKey() {
    // Verify pre-requirements (here we enforce a previous calculation of M1 and M2)
    if (S == null || M1 == null || M2 == null) {
      throw Exception(
          'Impossible to compute Key: some data are missing from the previous operations (S,M1,M2)');
    }
    Key = SRP6Util.calculateKey(digest, N, S!);
    return Key;
  }

  @override
  BigInt? generateClientCredentials(
      Uint8List salt, Uint8List identity, Uint8List password) {
    x = SRP6Util.calculateX(digest, N, salt, identity, password);
    a = selectPrivateValue();
    A = g.modPow(a!, N);
    return A;
  }

  BigInt? selectPrivateValue() {
    return SRP6Util.generatePrivateValue(digest, N, g, random);
  }

  @override
  bool verifyServerEvidenceMessage(BigInt serverM2) {
    // Verify pre-requirements
    if (A == null || M1 == null || S == null) {
      throw Exception('Impossible to compute and verify M2: '
          'some data are missing from the previous operations (A,M1,S)');
    }
    // Compute the own server evidence message 'M2'
    var computedM2 = SRP6Util.calculateM2(digest, N, A, M1, S);
    if (computedM2.compareTo(serverM2) == 0) {
      M2 = serverM2;
      return true;
    }
    return false;
  }
}
