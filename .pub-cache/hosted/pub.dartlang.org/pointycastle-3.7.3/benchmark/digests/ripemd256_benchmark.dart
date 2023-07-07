// See file LICENSE for more information.

library benchmark.digests.ripemd256_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('RIPEMD-256').report();
}
