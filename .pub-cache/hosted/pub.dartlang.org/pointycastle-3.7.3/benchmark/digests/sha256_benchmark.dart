// See file LICENSE for more information.

library benchmark.digests.sha256_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('SHA-256').report();
}
