// See file LICENSE for more information.

library benchmark.digests.sha512_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('SHA-512').report();
}
