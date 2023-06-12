import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common.dart';

class StreamControllerMock<T> extends Mock implements StreamController<T> {}

void main() {
  group('ChangeNotifier', () {
    test('.watch()', () async {
      var notifier = ChangeNotifier();

      var allEvents = <BoxEvent>[];
      notifier.watch().listen((e) {
        allEvents.add(e);
      });

      var filteredEvents = <BoxEvent>[];
      notifier.watch(key: 'key1').listen((e) {
        filteredEvents.add(e);
      });

      notifier.notify(Frame.deleted('key1'));
      notifier.notify(Frame('key1', 'newVal'));
      notifier.notify(Frame('key2', 'newVal2'));

      await Future.delayed(Duration(milliseconds: 1));

      expect(allEvents, [
        BoxEvent('key1', null, true),
        BoxEvent('key1', 'newVal', false),
        BoxEvent('key2', 'newVal2', false),
      ]);

      expect(filteredEvents, [
        BoxEvent('key1', null, true),
        BoxEvent('key1', 'newVal', false),
      ]);
    });

    test('close', () async {
      var controller = StreamControllerMock<BoxEvent>();
      returnFutureVoid(when(() => controller.close()));
      var notifier = ChangeNotifier.debug(controller);

      await notifier.close();
      verify(() => controller.close());
    });
  });
}
