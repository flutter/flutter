// See file LICENSE for more information.

library benchmark.digests.sha512t_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('SHA-512/504').report();
}
