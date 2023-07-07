// See file LICENSE for more information.

library pointycastle.benchmark.all_benchmarks;

import './block/aes_benchmark.dart' as aes_benchmark;
import './digests/md2_benchmark.dart' as md2_benchmark;
import './digests/md4_benchmark.dart' as md4_benchmark;
import './digests/md5_benchmark.dart' as md5_benchmark;
import './digests/ripemd128_benchmark.dart' as ripemd128_benchmark;
import './digests/ripemd160_benchmark.dart' as ripemd160_benchmark;
import './digests/ripemd256_benchmark.dart' as ripemd256_benchmark;
import './digests/ripemd320_benchmark.dart' as ripemd320_benchmark;
import './digests/sha1_benchmark.dart' as sha1_benchmark;
import './digests/sha224_benchmark.dart' as sha224_benchmark;
import './digests/sha256_benchmark.dart' as sha256_benchmark;
import './digests/sha384_benchmark.dart' as sha384_benchmark;
import './digests/sha3_benchmark.dart' as sha3_benchmark;
import './digests/sha512_benchmark.dart' as sha512_benchmark;
import './digests/sha512t_benchmark.dart' as sha512t_benchmark;
import './digests/tiger_benchmark.dart' as tiger_benchmark;
import './digests/whirlpool_benchmark.dart' as whirlpool_benchmark;
import './src/ufixnum_benchmark.dart' as ufixnum_benchmark;
import './stream/salsa20_benchmark.dart' as salsa20_benchmark;

void main() {
  // api
  ufixnum_benchmark.main();

  // block ciphers
  aes_benchmark.main();

  // digests
  md2_benchmark.main();
  md4_benchmark.main();
  md5_benchmark.main();
  ripemd128_benchmark.main();
  ripemd160_benchmark.main();
  ripemd256_benchmark.main();
  ripemd320_benchmark.main();
  sha1_benchmark.main();
  sha224_benchmark.main();
  sha256_benchmark.main();
  sha3_benchmark.main();
  sha384_benchmark.main();
  sha512_benchmark.main();
  sha512t_benchmark.main();
  tiger_benchmark.main();
  whirlpool_benchmark.main();

  // stream ciphers
  salsa20_benchmark.main();
}
