// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

const Duration kBenchmarkTime = Duration(seconds: 15);

Future<List<double>> runBuildBenchmark(ValueGetter<Widget> buildApp) async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  // We control the framePolicy below to prevent us from scheduling frames in
  // the engine, so that the engine does not interfere with our timings.
  final LiveTestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as LiveTestWidgetsFlutterBinding;

  final Stopwatch watch = Stopwatch();
  int iterations = 0;
  final List<double> values = <double>[];

  await benchmarkWidgets((WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Cannot use expects/asserts here since this is running outside of a test
    // in release mode.
    final int numberOfSizedBoxes = find.byType(SizedBox).evaluate().length;
    if (numberOfSizedBoxes != 30) {
      throw StateError('Expected 30 SizedBox widgets, but only found $numberOfSizedBoxes.');
    }
    if (find.text('testToken').evaluate().length != 1) {
      throw StateError('Did not find expected leaf widget.');
    }

    final Element rootWidget = tester.element(find.byKey(rootKey));
    Duration elapsed = Duration.zero;

    final LiveTestWidgetsFlutterBindingFramePolicy defaultPolicy = binding.framePolicy;
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

    while (elapsed < kBenchmarkTime) {
      watch.reset();
      watch.start();
      rootWidget.markNeedsBuild();
      await tester.pumpBenchmark(Duration(milliseconds: iterations * 16));
      watch.stop();
      iterations += 1;
      elapsed += Duration(microseconds: watch.elapsedMicroseconds);
      values.add(watch.elapsedMicroseconds.toDouble());
    }

    binding.framePolicy = defaultPolicy;
  });
  return values;
}

double calculateMean(List<double> values) {
  return values.reduce((double x, double y) => x + y) / values.length;
}

Future<void> main() async {
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  final double constMean = calculateMean(await runBuildBenchmark(() => ConstApp(key: rootKey)));
  final double nonConstMean = calculateMean(await runBuildBenchmark(() => NonConstApp(key: rootKey)));
  printer.addResult(
    description: 'const app build',
    value: constMean,
    unit: 'µs per iteration',
    name: 'const_app_build_iteration',
  );
  printer.addResult(
    description: 'non-const app build',
    value: nonConstMean,
    unit: 'µs per iteration',
    name: 'non_const_app_build_iteration',
  );
  printer.addResult(
    description: 'const speed-up (vs. non-const)',
    value: ((nonConstMean - constMean) / constMean) * 100,
    unit: '%',
    name: 'const_speed_up',
  );
  printer.printToStdout();
}

final Key rootKey = UniqueKey();

class ConstApp extends StatelessWidget {
  const ConstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      child: SizedBox(
        child: SizedBox(
          child: SizedBox(
            child: SizedBox(
              child: SizedBox(
                child: SizedBox(
                  child: SizedBox(
                    child: SizedBox(
                      child: SizedBox(
                        child: SizedBox(
                          child: SizedBox(
                            child: SizedBox(
                              child: SizedBox(
                                child: SizedBox(
                                  child: SizedBox(
                                    child: SizedBox(
                                      child: SizedBox(
                                        child: SizedBox(
                                          child: SizedBox(
                                            child: SizedBox(
                                              child: SizedBox(
                                                child: SizedBox(
                                                  child: SizedBox(
                                                    child: SizedBox(
                                                      child: SizedBox(
                                                        child: SizedBox(
                                                          child: SizedBox(
                                                            child: SizedBox(
                                                              child: SizedBox(
                                                                child: Text('testToken', textDirection: TextDirection.ltr),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NonConstApp extends StatelessWidget {
  const NonConstApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The explicit goal is to test the performance of non-const widgets,
    // hence all these ignores.
    return SizedBox( // ignore: prefer_const_constructors
      child: SizedBox( // ignore: prefer_const_constructors
        child: SizedBox( // ignore: prefer_const_constructors
          child: SizedBox( // ignore: prefer_const_constructors
            child: SizedBox( // ignore: prefer_const_constructors
              child: SizedBox( // ignore: prefer_const_constructors
                child: SizedBox( // ignore: prefer_const_constructors
                  child: SizedBox( // ignore: prefer_const_constructors
                    child: SizedBox( // ignore: prefer_const_constructors
                      child: SizedBox( // ignore: prefer_const_constructors
                        child: SizedBox( // ignore: prefer_const_constructors
                          child: SizedBox( // ignore: prefer_const_constructors
                            child: SizedBox( // ignore: prefer_const_constructors
                              child: SizedBox( // ignore: prefer_const_constructors
                                child: SizedBox( // ignore: prefer_const_constructors
                                  child: SizedBox( // ignore: prefer_const_constructors
                                    child: SizedBox( // ignore: prefer_const_constructors
                                      child: SizedBox( // ignore: prefer_const_constructors
                                        child: SizedBox( // ignore: prefer_const_constructors
                                          child: SizedBox( // ignore: prefer_const_constructors
                                            child: SizedBox( // ignore: prefer_const_constructors
                                              child: SizedBox( // ignore: prefer_const_constructors
                                                child: SizedBox( // ignore: prefer_const_constructors
                                                  child: SizedBox( // ignore: prefer_const_constructors
                                                    child: SizedBox( // ignore: prefer_const_constructors
                                                      child: SizedBox( // ignore: prefer_const_constructors
                                                        child: SizedBox( // ignore: prefer_const_constructors
                                                          child: SizedBox( // ignore: prefer_const_constructors
                                                            child: SizedBox( // ignore: prefer_const_constructors
                                                              child: SizedBox( // ignore: prefer_const_constructors
                                                                child: Text('testToken', textDirection: TextDirection.ltr), // ignore: prefer_const_constructors
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
