// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

void expectMuchFaster(Function fastFunction, Function slowFunction) {
  late Stopwatch fastStopWatch;
  late Stopwatch slowStopWatch;

  // Retry; we only need one good result to prove the performance
  // characteristics. Bad performance can come from machine load.
  for (var i = 0; i != 10; ++i) {
    fastStopWatch = Stopwatch()..start();
    fastFunction();
    fastStopWatch.stop();

    slowStopWatch = Stopwatch()..start();
    slowFunction();
    slowStopWatch.stop();

    if (fastStopWatch.elapsedMicroseconds * 10 <
        slowStopWatch.elapsedMicroseconds) {
      return;
    }
  }

  throw 'Expected first function to be at least 10x faster than second!'
      ' Measured: first=${fastStopWatch.elapsedMicroseconds}'
      ' second=${slowStopWatch.elapsedMicroseconds}';
}

void expectNotMuchFaster(Function notFastFunction, Function slowFunction) {
  late Stopwatch fastStopWatch;
  late Stopwatch slowStopWatch;

  // Retry; we only need one good result to prove the performance
  // characteristics. Bad performance can come from machine load.
  for (var i = 0; i != 10; ++i) {
    fastStopWatch = Stopwatch()..start();
    notFastFunction();
    fastStopWatch.stop();

    slowStopWatch = Stopwatch()..start();
    slowFunction();
    slowStopWatch.stop();

    if (fastStopWatch.elapsedMicroseconds * 10 >
        slowStopWatch.elapsedMicroseconds) {
      return;
    }
  }

  throw 'Expected first function to be less than 10x faster than second!'
      ' Measured: first=${fastStopWatch.elapsedMicroseconds}'
      ' second=${slowStopWatch.elapsedMicroseconds}';
}

class HashCodeSpy {
  int hashCodeSeen = 0;

  @override
  // ignore: hash_and_equals
  int get hashCode {
    ++hashCodeSeen;
    return 0;
  }
}
