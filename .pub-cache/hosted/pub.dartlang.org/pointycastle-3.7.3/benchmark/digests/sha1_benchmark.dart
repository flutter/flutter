// See file LICENSE for more information.

library benchmark.digests.sha1_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('SHA-1').report();
}
