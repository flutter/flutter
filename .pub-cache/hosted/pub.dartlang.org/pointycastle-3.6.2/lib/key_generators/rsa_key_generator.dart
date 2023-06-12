// See file LICENSE for more information.

library impl.key_generator.rsa_key_generator;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/src/registry/registry.dart';

bool _testBit(BigInt i, int n) {
  return (i & (BigInt.one << n)) != BigInt.zero;
}

class RSAKeyGenerator implements KeyGenerator {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(KeyGenerator, 'RSA', () => RSAKeyGenerator());

  late SecureRandom _random;
  late RSAKeyGeneratorParameters _params;

  @override
  String get algorithmName => 'RSA';

  @override
  void init(CipherParameters params) {
    if (params is ParametersWithRandom) {
      _random = params.random;
      _params = params.parameters as RSAKeyGeneratorParameters;
    } else {
      _random = SecureRandom();
      _params = params as RSAKeyGeneratorParameters;
    }

    if (_params.bitStrength < 12) {
      throw ArgumentError('key bit strength cannot be smaller than 12');
    }

    if (!_testBit(_params.publicExponent, 0)) {
      throw ArgumentError('Public exponent cannot be even');
    }
  }

  @override
  AsymmetricKeyPair generateKeyPair() {
    BigInt p, q, n, e;

    // p and q values should have a length of half the strength in bits
    var strength = _params.bitStrength;
    var pbitlength = (strength + 1) ~/ 2;
    var qbitlength = strength - pbitlength;
    var mindiffbits = strength ~/ 3;

    e = _params.publicExponent;

    // TODO Consider generating safe primes for p, q (see DHParametersHelper.generateSafePrimes)
    // (then p-1 and q-1 will not consist of only small factors - see "Pollard's algorithm")

    // generate p, prime and (p-1) relatively prime to e
    while (true) {
      p = generateProbablePrime(pbitlength, 1, _random);

      if (p % e == BigInt.one) {
        continue;
      }

      if (!_isProbablePrime(p, _params.certainty)) {
        continue;
      }

      if (e.gcd(p - BigInt.one) == BigInt.one) {
        break;
      }
    }

    // generate a modulus of the required length
    while (true) {
      // generate q, prime and (q-1) relatively prime to e, and not equal to p
      while (true) {
        q = generateProbablePrime(qbitlength, 1, _random);

        if ((q - p).abs().bitLength < mindiffbits) {
          continue;
        }

        if (q % e == BigInt.one) {
          continue;
        }

        if (!_isProbablePrime(q, _params.certainty)) {
          continue;
        }

        if (e.gcd(q - BigInt.one) == BigInt.one) {
          break;
        }
      }

      // calculate the modulus
      n = (p * q);

      if (n.bitLength == _params.bitStrength) {
        break;
      }

      // if we get here our primes aren't big enough, make the largest of the two p and try again
      p = (p.compareTo(q) > 0) ? p : q;
    }

    // Swap p and q if necessary
    if (p < q) {
      var swap = p;
      p = q;
      q = swap;
    }

    // calculate the private exponent
    var pSub1 = (p - BigInt.one);
    var qSub1 = (q - BigInt.one);
    var phi = (pSub1 * qSub1);
    var d = e.modInverse(phi);

    return AsymmetricKeyPair(RSAPublicKey(n, e), RSAPrivateKey(n, d, p, q, e));
  }
}

/// [List] of low primes
final List<BigInt> _lowprimes = [
  BigInt.from(2),
  BigInt.from(3),
  BigInt.from(5),
  BigInt.from(7),
  BigInt.from(11),
  BigInt.from(13),
  BigInt.from(17),
  BigInt.from(19),
  BigInt.from(23),
  BigInt.from(29),
  BigInt.from(31),
  BigInt.from(37),
  BigInt.from(41),
  BigInt.from(43),
  BigInt.from(47),
  BigInt.from(53),
  BigInt.from(59),
  BigInt.from(61),
  BigInt.from(67),
  BigInt.from(71),
  BigInt.from(73),
  BigInt.from(79),
  BigInt.from(83),
  BigInt.from(89),
  BigInt.from(97),
  BigInt.from(101),
  BigInt.from(103),
  BigInt.from(107),
  BigInt.from(109),
  BigInt.from(113),
  BigInt.from(127),
  BigInt.from(131),
  BigInt.from(137),
  BigInt.from(139),
  BigInt.from(149),
  BigInt.from(151),
  BigInt.from(157),
  BigInt.from(163),
  BigInt.from(167),
  BigInt.from(173),
  BigInt.from(179),
  BigInt.from(181),
  BigInt.from(191),
  BigInt.from(193),
  BigInt.from(197),
  BigInt.from(199),
  BigInt.from(211),
  BigInt.from(223),
  BigInt.from(227),
  BigInt.from(229),
  BigInt.from(233),
  BigInt.from(239),
  BigInt.from(241),
  BigInt.from(251),
  BigInt.from(257),
  BigInt.from(263),
  BigInt.from(269),
  BigInt.from(271),
  BigInt.from(277),
  BigInt.from(281),
  BigInt.from(283),
  BigInt.from(293),
  BigInt.from(307),
  BigInt.from(311),
  BigInt.from(313),
  BigInt.from(317),
  BigInt.from(331),
  BigInt.from(337),
  BigInt.from(347),
  BigInt.from(349),
  BigInt.from(353),
  BigInt.from(359),
  BigInt.from(367),
  BigInt.from(373),
  BigInt.from(379),
  BigInt.from(383),
  BigInt.from(389),
  BigInt.from(397),
  BigInt.from(401),
  BigInt.from(409),
  BigInt.from(419),
  BigInt.from(421),
  BigInt.from(431),
  BigInt.from(433),
  BigInt.from(439),
  BigInt.from(443),
  BigInt.from(449),
  BigInt.from(457),
  BigInt.from(461),
  BigInt.from(463),
  BigInt.from(467),
  BigInt.from(479),
  BigInt.from(487),
  BigInt.from(491),
  BigInt.from(499),
  BigInt.from(503),
  BigInt.from(509)
];

final BigInt _lplim = (BigInt.one << 26) ~/ _lowprimes.last;

final BigInt _bigTwo = BigInt.from(2);

/// return index of lowest 1-bit in x, x < 2^31
int _lbit(BigInt x) {
  // Implementation borrowed from bignum.BigIntegerDartvm.
  if (x == BigInt.zero) return -1;
  var r = 0;
  while ((x & BigInt.from(0xffffffff)) == BigInt.zero) {
    x >>= 32;
    r += 32;
  }
  if ((x & BigInt.from(0xffff)) == BigInt.zero) {
    x >>= 16;
    r += 16;
  }
  if ((x & BigInt.from(0xff)) == BigInt.zero) {
    x >>= 8;
    r += 8;
  }
  if ((x & BigInt.from(0xf)) == BigInt.zero) {
    x >>= 4;
    r += 4;
  }
  if ((x & BigInt.from(3)) == BigInt.zero) {
    x >>= 2;
    r += 2;
  }
  if ((x & BigInt.one) == BigInt.zero) ++r;
  return r;
}

/// true if probably prime (HAC 4.24, Miller-Rabin) */
bool _millerRabin(BigInt b, int t) {
  // Implementation borrowed from bignum.BigIntegerDartvm.
  var n1 = b - BigInt.one;
  var k = _lbit(n1);
  if (k <= 0) return false;
  var r = n1 >> k;
  t = (t + 1) >> 1;
  if (t > _lowprimes.length) t = _lowprimes.length;
  BigInt a;
  for (var i = 0; i < t; ++i) {
    a = _lowprimes[i];
    var y = a.modPow(r, b);
    if (y.compareTo(BigInt.one) != 0 && y.compareTo(n1) != 0) {
      var j = 1;
      while (j++ < k && y.compareTo(n1) != 0) {
        y = y.modPow(_bigTwo, b);
        if (y.compareTo(BigInt.one) == 0) return false;
      }
      if (y.compareTo(n1) != 0) return false;
    }
  }
  return true;
}

/// test primality with certainty >= 1-.5^t */
bool _isProbablePrime(BigInt b, int t) {
  // Implementation borrowed from bignum.BigIntegerDartvm.
  var i;
  var x = b.abs();
  if (b <= _lowprimes.last) {
    for (i = 0; i < _lowprimes.length; ++i) {
      if (b == _lowprimes[i]) return true;
    }
    return false;
  }
  if (x.isEven) return false;
  i = 1;
  while (i < _lowprimes.length) {
    var m = _lowprimes[i], j = i + 1;
    while (j < _lowprimes.length && m < _lplim) {
      m *= _lowprimes[j++];
    }
    m = x % m;
    while (i < j) {
      if (m % _lowprimes[i++] == BigInt.zero) {
        return false;
      }
    }
  }
  return _millerRabin(x, t);
}

BigInt generateProbablePrime(int bitLength, int certainty, SecureRandom rnd) {
  if (bitLength < 2) {
    return BigInt.one;
  }

  var candidate = rnd.nextBigInteger(bitLength);

  // force MSB set
  if (!_testBit(candidate, bitLength - 1)) {
    candidate |= BigInt.one << (bitLength - 1);
  }

  // force odd
  if (candidate.isEven) {
    candidate += BigInt.one;
  }

  while (!_isProbablePrime(candidate, certainty)) {
    candidate += _bigTwo;
    if (candidate.bitLength > bitLength) {
      candidate -= BigInt.one << (bitLength - 1);
    }
  }

  return candidate;
}
