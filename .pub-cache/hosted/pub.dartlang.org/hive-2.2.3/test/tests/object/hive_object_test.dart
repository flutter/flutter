import 'package:hive/src/object/hive_object.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../mocks.dart';

void main() {
  group('HiveObject', () {
    group('.init()', () {
      test('adds key and box to HiveObject', () {
        var obj = TestHiveObject();
        var box = MockBox();

        obj.init('someKey', box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('does nothing if old key and box are equal to new key and box', () {
        var obj = TestHiveObject();
        var box = MockBox();

        obj.init('someKey', box);
        obj.init('someKey', box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('throws exception if object is already in a different box', () {
        var obj = TestHiveObject();
        var box1 = MockBox();
        var box2 = MockBox();

        obj.init('someKey', box1);
        expect(() => obj.init('someKey', box2),
            throwsHiveError('two different boxes'));
      });

      test('throws exception if object has already different key', () {
        var obj = TestHiveObject();
        var box = MockBox();

        obj.init('key1', box);
        expect(
            () => obj.init('key2', box), throwsHiveError('two different keys'));
      });
    });

    group('.dispose()', () {
      test('removes key and box', () {
        var obj = TestHiveObject();
        var box = MockBox();

        obj.init('key', box);
        obj.dispose();

        expect(obj.key, null);
        expect(obj.box, null);
      });

      test('notifies remote HiveLists', () {
        var obj = TestHiveObject();
        var box = MockBox();
        obj.init('key', box);

        var list = MockHiveListImpl();
        obj.linkHiveList(list);
        obj.dispose();

        verify(() => list.invalidate());
      });
    });

    test('.linkHiveList()', () {
      var box = MockBox();
      var obj = TestHiveObject();
      obj.init('key', box);
      var hiveList = MockHiveListImpl();

      obj.linkHiveList(hiveList);
      expect(obj.debugHiveLists, {hiveList: 1});
      obj.linkHiveList(hiveList);
      expect(obj.debugHiveLists, {hiveList: 2});
    });

    test('.unlinkHiveList()', () {
      var box = MockBox();
      var obj = TestHiveObject();
      obj.init('key', box);
      var hiveList = MockHiveListImpl();

      obj.linkHiveList(hiveList);
      obj.linkHiveList(hiveList);
      expect(obj.debugHiveLists, {hiveList: 2});

      obj.unlinkHiveList(hiveList);
      expect(obj.debugHiveLists, {hiveList: 1});
      obj.unlinkHiveList(hiveList);
      expect(obj.debugHiveLists, {});
    });

    group('.save()', () {
      test('updates object in box', () {
        var obj = TestHiveObject();
        var box = MockBox();
        returnFutureVoid(when(() => box.put('key', obj)));

        obj.init('key', box);
        verifyZeroInteractions(box);

        obj.save();
        verify(() => box.put('key', obj));
      });

      test('throws HiveError if object is not in a box', () async {
        var obj = TestHiveObject();
        await expectLater(() => obj.save(), throwsHiveError('not in a box'));
      });
    });

    group('.delete()', () {
      test('removes object from box', () {
        var obj = TestHiveObject();
        var box = MockBox();
        returnFutureVoid(when(() => box.delete('key')));

        obj.init('key', box);
        verifyZeroInteractions(box);

        obj.delete();
        verify(() => box.delete('key'));
      });

      test('throws HiveError if object is not in a box', () async {
        var obj = TestHiveObject();
        await expectLater(() => obj.delete(), throwsHiveError('not in a box'));
      });
    });

    group('.isInBox', () {
      test('returns false if box is not set', () {
        var obj = TestHiveObject();
        expect(obj.isInBox, false);
      });

      test('returns true if object is in normal box', () {
        var obj = TestHiveObject();
        var box = MockBox();
        when(() => box.lazy).thenReturn(false);
        obj.init('key', box);

        expect(obj.isInBox, true);
      });

      test('returns the result ob box.containsKey() if object is in lazy box',
          () {
        var obj = TestHiveObject();
        var box = MockBox();
        when(() => box.lazy).thenReturn(true);
        obj.init('key', box);

        when(() => box.containsKey('key')).thenReturn(true);
        expect(obj.isInBox, true);

        when(() => box.containsKey('key')).thenReturn(false);
        expect(obj.isInBox, false);
      });
    });
  });
}
