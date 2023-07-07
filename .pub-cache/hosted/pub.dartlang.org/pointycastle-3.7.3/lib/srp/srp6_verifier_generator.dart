library src.srp_verifier_generator;

import 'dart:typed_data';

import 'package:pointycastle/srp/srp6_standard_groups.dart';
import 'package:pointycastle/srp/srp6_util.dart';
import 'package:pointycastle/pointycastle.dart';

/// Generates new SRP verifier for user
class SRP6VerifierGenerator {
  late BigInt N;
  late BigInt g;
  Digest digest;

  SRP6VerifierGenerator(
      {required SRP6GroupParameters group, required this.digest}) {
    N = group.N;
    g = group.g;
  }

  /// Creates a new SRP verifier
  /// [salt] The salt to use, generally should be large and random
  /// [identity] The user's identifying information (eg. username)
  /// [password] The user's password
  /// returns A new verifier for use in future SRP authentication
  BigInt generateVerifier(
      Uint8List salt, Uint8List identity, Uint8List password) {
    var x = SRP6Util.calculateX(digest, N, salt, identity, password);

    return g.modPow(x, N);
  }
}
