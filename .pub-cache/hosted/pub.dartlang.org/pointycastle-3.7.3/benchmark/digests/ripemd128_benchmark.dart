// See file LICENSE for more information.

library benchmark.digests.ripemd128_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('RIPEMD-128').report();
}
