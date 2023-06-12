// See file LICENSE for more information.

library benchmark.digests.ripemd160_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('RIPEMD-160').report();
}
