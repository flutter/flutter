import 'package:rxdart/rxdart.dart';

/// generate n-amount of fibonacci numbers
///
/// for example: dart fibonacci.dart 10
/// outputs:
/// 1: 1
/// 2: 1
/// 3: 2
/// 4: 3
/// 5: 5
/// 6: 8
/// 7: 13
/// 8: 21
/// 9: 34
/// 10: 55
/// done!
void main(List<String> arguments) {
  // read the command line argument, if none provided, default to 10
  var n = (arguments.length == 1) ? int.parse(arguments.first) : 10;

  // seed value: this value will be used as the
  // starting value for the [scan] method
  const seed = IndexedPair(1, 1, 0);

  Rx
          // amount of numbers to compute
          .range(1, n)
      // accumulator: computes a new accumulated
      // value each time a [Stream] event occurs
      // in this case, the accumulated value is always
      // the latest Fibonacci number
      .scan((IndexedPair seq, _, __) => IndexedPair.next(seq), seed)
      // finally, print the output
      .listen(print, onDone: () => print('done!'));
}

class IndexedPair {
  final int n1, n2, index;

  const IndexedPair(this.n1, this.n2, this.index);

  factory IndexedPair.next(IndexedPair prev) => IndexedPair(
      prev.n2, prev.index <= 1 ? prev.n1 : prev.n1 + prev.n2, prev.index + 1);

  @override
  String toString() => '$index: $n2';
}
