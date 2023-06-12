// See file LICENSE for more information.

library benchmark.digests.md2_benchmark;

import '../benchmark/digest_benchmark.dart';

void main() {
  DigestBenchmark('MD2', 256 * 1024).report();
}
