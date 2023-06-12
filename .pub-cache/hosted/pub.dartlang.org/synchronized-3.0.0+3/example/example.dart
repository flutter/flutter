import 'dart:async';
import 'dart:io';
import 'package:synchronized/synchronized.dart';

class Demo {
  Future<void> runNotSynchronized() async {
    stdout.writeln('not synchronized');
    // this should print 11223344
    // ignore: unawaited_futures
    write1234();
    // ignore: unawaited_futures
    write1234();

    await Future.delayed(const Duration(milliseconds: 50));
    stdout.writeln();
  }

  Future<void> runSynchronized() async {
    stdout.writeln('synchronized');

    final lock = Lock();
    // this should print 12341234
    // ignore: unawaited_futures
    lock.synchronized(write1234);
    // ignore: unawaited_futures
    lock.synchronized(write1234);

    await Future.delayed(const Duration(milliseconds: 50));

    stdout.writeln();
  }
}

Future<void> main() async {
  var demo = Demo();

  await demo.runNotSynchronized();
  await demo.runSynchronized();
}

/// write an int
Future<void> writeSlow(int value) async {
  await Future.delayed(const Duration(milliseconds: 1));
  stdout.write(value);
}

/// write a list of int, 1 char every 1 ms
Future<void> write(List<int> values) async {
  for (var value in values) {
    await writeSlow(value);
  }
}

Future<void> write1234() async {
  await write([1, 2, 3, 4]);
}
