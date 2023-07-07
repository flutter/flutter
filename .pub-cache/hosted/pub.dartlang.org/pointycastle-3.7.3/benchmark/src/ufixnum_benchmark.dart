// See file LICENSE for more information.

library benchmark.api.ufixnum_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/src/ufixnum.dart';
import '../benchmark/operation_benchmark.dart';

void main() {
  _benchmarkSum();
  _benchmarkUnpack();
}

void _benchmarkSum() {
  final x8 = 0xFF;
  final y8 = 0x80;
  final x32 = 0xFF00FF00;
  final y32 = 0x80808080;
  final x64 = 0xFF00FF00FF00FF00;
  final y64 = 0x8080808080808080;
  final dx = 0xFF00FF00.toDouble();
  final dy = 0x08080808.toDouble();
  final rx64 = Register64(0xFF00FF00, 0xFF00FF00);
  final ry64 = Register64(0x80808080, 0x80808080);
  final bix = BigInt.parse('FF00FF00', radix: 16);
  final biy = BigInt.parse('08080808', radix: 16);

  OperationBenchmark('sum | smi   ', () => x32 + y32).report();
  OperationBenchmark('sum | double', () => dx + dy).report();
  OperationBenchmark('sum | sum8  ', () => sum8(x8, y8)).report();
  OperationBenchmark('sum | sum32 ', () => sum32(x32, y32)).report();
  OperationBenchmark('sum | Reg64 ', () => rx64.sum(ry64)).report();
  OperationBenchmark('sum | bigint', () => x64 + y64).report();
  OperationBenchmark('sum | bignum', () => bix + biy).report();
}

void _benchmarkUnpack() {
  var bytes = Uint8List(8);
  var view = ByteData.view(bytes.buffer);
  var r64 = Register64();
  OperationBenchmark('unpack | ByteData           ', () {
    view.getUint32(0, Endian.little);
  }).report();
  OperationBenchmark('unpack | unpack32(ByteData) ', () {
    unpack32(view, 0, Endian.little);
  }).report();
  OperationBenchmark('unpack | unpack32(Uint8List)', () {
    unpack32(bytes, 0, Endian.little);
  }).report();
  OperationBenchmark('unpack | unpack64(ByteData) ', () {
    r64.unpack(view, 0, Endian.little);
  }).report();
  OperationBenchmark('unpack | unpack64(Uint8List)', () {
    r64.unpack(bytes, 0, Endian.little);
  }).report();
}
