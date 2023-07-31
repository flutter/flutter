import 'package:pool/pool.dart';

void main(List<String> args) async {
  var poolSize = args.isEmpty ? 5 : int.parse(args.first);
  print('Pool size: $poolSize');

  final pool = Pool(poolSize);
  final watch = Stopwatch()..start();
  final start = DateTime.now();

  DateTime? lastLog;
  Duration? fastest;
  late int fastestIteration;
  var i = 1;

  void log(bool force) {
    var now = DateTime.now();
    if (force ||
        lastLog == null ||
        now.difference(lastLog!) > const Duration(seconds: 1)) {
      lastLog = now;
      print([
        now.difference(start),
        i.toString().padLeft(10),
        fastestIteration.toString().padLeft(7),
        fastest!.inMicroseconds.toString().padLeft(9)
      ].join('   '));
    }
  }

  print(['Elapsed       ', 'Iterations', 'Fastest', 'Time (us)'].join('   '));

  for (;; i++) {
    watch.reset();

    var sum = await pool
        .forEach<int, int>(Iterable<int>.generate(100000), (i) => i)
        .reduce((a, b) => a + b);

    assert(sum == 4999950000, 'was $sum');

    var elapsed = watch.elapsed;
    if (fastest == null || fastest > elapsed) {
      fastest = elapsed;
      fastestIteration = i;
      log(true);
    } else {
      log(false);
    }
  }
}
