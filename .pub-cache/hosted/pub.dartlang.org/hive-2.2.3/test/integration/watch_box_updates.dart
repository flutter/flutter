import 'dart:async';

import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'integration.dart';

Future<void> expectNextEvent(Stream<BoxEvent> stream, FutureOr Function() cb,
    {Object? key, Object? value, bool? deleted}) async {
  late StreamSubscription subscription;
  final completer = Completer();

  subscription = stream.listen((event) async {
    await subscription.cancel();
    try {
      if (key != null) expect(event.key, key);
      if (value != null) expect(event.value, value);
      if (deleted != null) expect(event.deleted, deleted);
    } finally {
      completer.complete();
    }
  });

  await cb();
  await completer.future;
}

void main() {
  group('watch() emits box updates when', () {
    late BoxBase box;

    setUp(() async {
      box = await openBox(false);
    });

    tearDown(() async {
      await box.close();
    });

    test('.put() is called', () async {
      await expectNextEvent(
        box.watch(),
        () async {
          await box.put('key', 'value');
        },
        key: 'key',
        value: 'value',
        deleted: false,
      );
    });

    test('.add() is called', () async {
      await expectNextEvent(
        box.watch(),
        () async {
          await box.add('value');
        },
        value: 'value',
        deleted: false,
      );
    });

    test('.putAt() is called', () async {
      await expectNextEvent(
        box.watch().skip(1),
        () async {
          await box.add(null);
          await box.putAt(0, 'value');
        },
        value: 'value',
        deleted: false,
      );
    });

    test('.delete() is called', () async {
      await expectNextEvent(
        box.watch().skip(1),
        () async {
          await box.put('key', 'value');
          await box.delete('key');
        },
        key: 'key',
        deleted: true,
      );
    });
  });
}
