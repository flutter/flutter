import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

void main() {
  var uuid = Uuid();

  // Generate a v1 (time-based) id
  var v1 = uuid.v1(); // -> '6c84fb90-12c4-11e1-840d-7b25c5ee775a'

  var v1_exact = uuid.v1(options: {
    'node': [0x01, 0x23, 0x45, 0x67, 0x89, 0xab],
    'clockSeq': 0x1234,
    'mSecs': DateTime.utc(2011, 11, 01).millisecondsSinceEpoch,
    'nSecs': 5678
  }); // -> '710b962e-041c-11e1-9234-0123456789ab'

  // Generate a v4 (random) id
  var v4 = uuid.v4(); // -> '110ec58a-a0f2-4ac4-8393-c866d813b8d1'

  // Generate a v4 (crypto-random) id
  var v4_crypto = uuid.v4(options: {'rng': UuidUtil.cryptoRNG});
  // -> '110ec58a-a0f2-4ac4-8393-c866d813b8d1'

  // Generate a v5 (namespace-name-sha1-based) id
  var v5 = uuid.v5(Uuid.NAMESPACE_URL, 'www.google.com');
  // -> 'c74a196f-f19d-5ea9-bffd-a2742432fc9c'

  print(v1);
  print(v1_exact);
  print(v4);
  print(v4_crypto);
  print(v5);
}
