library impl.srp_server;

import 'package:pointycastle/srp/srp6_standard_groups.dart';
import 'package:pointycastle/srp/srp6_util.dart';
import 'package:pointycastle/api.dart';

class SRP6Server implements SRPServer {
  late BigInt N;
  late BigInt g;

  BigInt v;
  SecureRandom random;
  Digest digest;

  BigInt? A;

  BigInt? b;
  BigInt? B;

  BigInt? u;
  BigInt? S;
  BigInt? M1;
  BigInt? M2;
  BigInt? Key;

  SRP6Server(
      {required SRP6GroupParameters group,
      required this.v,
      required this.digest,
      required this.random}) {
    g = group.g;
    N = group.N;
  }

  @override
  BigInt? calculateSecret(BigInt clientA) {
    A = SRP6Util.validatePublicValue(N, clientA);
    u = SRP6Util.calculateU(digest, N, A, B);
    S = _calculateS();

    return S;
  }

  @override
  BigInt? calculateServerEvidenceMessage() {
    // Verify pre-requirements
    if (A == null || M1 == null || S == null) {
      throw Exception(
          'Impossible to compute M2: some data are missing from the previous operations (A,M1,S)');
    }

    // Compute the server evidence message 'M2'
    M2 = SRP6Util.calculateM2(digest, N, A!, M1!, S!);
    return M2;
  }

  @override
  BigInt? calculateSessionKey() {
    // Verify pre-requirements
    if (S == null || M1 == null || M2 == null) {
      throw Exception(
          'Impossible to compute Key: some data are missing from the previous operations (S,M1,M2)');
    }
    Key = SRP6Util.calculateKey(digest, N, S);
    return Key;
  }

  @override
  BigInt? generateServerCredentials() {
    var k = SRP6Util.calculateK(digest, N, g);
    b = selectPrivateValue();
    B = ((k * v + g.modPow(b!, N)) % N);

    return B;
  }

  BigInt? selectPrivateValue() {
    return SRP6Util.generatePrivateValue(digest, N, g, random);
  }

  @override
  bool verifyClientEvidenceMessage(BigInt clientM1) {
    // Verify pre-requirements
    if (A == null || B == null || S == null) {
      throw Exception(
          'Impossible to compute and verify M1: some data are missing from the previous operations (A,B,S)');
    }

    // Compute the own client evidence message 'M1'
    var computedM1 = SRP6Util.calculateM1(digest, N, A, B, S);
    if (computedM1.compareTo(clientM1) == 0) {
      M1 = clientM1;
      return true;
    }
    return false;
  }

  BigInt _calculateS() {
    return ((v.modPow(u!, N) * A!) % N).modPow(b!, N);
  }
}
