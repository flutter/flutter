import 'dart:async';
import 'dart:html';
import 'package:synchronized/synchronized.dart';

PreElement? outElement;

void print(dynamic msg) {
  outElement ??= querySelector('#output') as PreElement?;
  var existing = outElement?.text ?? '';
  outElement?.text = '$existing$msg\n';
}

Future<void> writeSlow(int value) async {
  await Future.delayed(const Duration(milliseconds: 1));
  print(value);
}

Future<void> write(List<int> values) async {
  for (var value in values) {
    await writeSlow(value);
  }
}

Future<void> write1234() async {
  await write([1, 2, 3, 4]);
}

class Demo {
  Future<void> test1() async {
    print('not synchronized');
    //await Future.wait([write1234(), write1234()]);
    // ignore: unawaited_futures
    write1234();
    // ignore: unawaited_futures
    write1234();

    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> test2() async {
    print('synchronized');
    var lock = Lock();

    // ignore: unawaited_futures
    lock.synchronized(write1234);
    // ignore: unawaited_futures
    lock.synchronized(write1234);

    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> test3() async {
    print('lock.synchronized');

    var lock = Lock();
    // ignore: unawaited_futures
    lock.synchronized(write1234);
    // ignore: unawaited_futures
    lock.synchronized(write1234);

    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> test4() async {
    print('basic');
    var lock = Lock();
    await lock.synchronized(() async {
      // do you stuff
      // await ...
    });
  }

  Future<void> readme1() async {
    var lock = Lock();

    // ...
    await lock.synchronized(() async {
      // do some stuff
    });
  }

  Future<void> readme2() async {
    var lock = Lock();
    if (!lock.locked) {
      await lock.synchronized(() async {
        // do some stuff
      });
    }
  }

  Future<void> readme3() async {
    var lock = Lock();

    var value = await lock.synchronized(() {
      return 1;
    });
    print('got value: $value');
  }
}

Future<void> main() async {
  var demo = Demo();

  await demo.test1();
  await demo.test2();
  await demo.test3();
  await demo.test4();
  await demo.readme1();
  await demo.readme1();
  await demo.readme3();
}
