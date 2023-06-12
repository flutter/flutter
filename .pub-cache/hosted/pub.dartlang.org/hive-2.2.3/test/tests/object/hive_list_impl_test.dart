import 'dart:typed_data';

import 'package:hive/src/object/hive_list_impl.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../integration/integration.dart';
import '../common.dart';
import '../mocks.dart';

HiveObject _getHiveObject(String key, MockBox box) {
  var hiveObject = TestHiveObject();
  hiveObject.init(key, box);
  when(() => box.get(key,
          defaultValue: captureAny(that: isNotNull, named: 'defaultValue')))
      .thenReturn(hiveObject);
  when(() => box.get(key)).thenReturn(hiveObject);
  return hiveObject;
}

MockBox _mockBox() {
  var box = MockBox();
  // The HiveListImpl constructor sets the boxName property to box.name,
  // therefore we need to return an valid String on sound null safety.
  when(() => box.name).thenReturn('testBox');
  return box;
}

void main() {
  group('HiveListImpl', () {
    test('HiveListImpl()', () {
      var box = _mockBox();

      var item1 = _getHiveObject('item1', box);
      var item2 = _getHiveObject('item2', box);
      var list = HiveListImpl(box, objects: [item1, item2, item1]);

      expect(item1.debugHiveLists, {list: 2});
      expect(item2.debugHiveLists, {list: 1});
    });

    test('HiveListImpl.lazy()', () {
      var list = HiveListImpl.lazy('testBox', ['key1', 'key2']);
      expect(list.boxName, 'testBox');
      expect(list.keys, ['key1', 'key2']);
    });

    group('.box', () {
      test('throws HiveError if box is not open', () async {
        var hive = await createHive();
        var hiveList = HiveListImpl.lazy('someBox', [])..debugHive = hive;
        expect(() => hiveList.box, throwsHiveError('you have to open the box'));
      });

      test('returns the box', () async {
        var hive = await createHive();
        var box = await hive.openBox<int>('someBox', bytes: Uint8List(0));
        var hiveList = HiveListImpl.lazy('someBox', [])..debugHive = hive;
        expect(hiveList.box, box);
      });
    });

    group('.delegate', () {
      test('throws exception if HiveList is disposed', () {
        var list = HiveListImpl.lazy('box', []);
        list.dispose();
        expect(() => list.delegate, throwsHiveError('already been disposed'));
      });

      test('removes correct elements if invalidated', () {
        var box = _mockBox();
        var item1 = _getHiveObject('item1', box);
        var item2 = _getHiveObject('item2', box);
        var list = HiveListImpl(box, objects: [item1, item2, item1]);

        item1.debugHiveLists.clear();
        expect(list.delegate, [item1, item2, item1]);
        list.invalidate();
        expect(list.delegate, [item2]);
      });

      test('creates delegate and links HiveList if delegate == null', () {
        var hive = MockHiveImpl();
        var box = _mockBox();
        when(() => box.containsKey('item1')).thenReturn(true);
        when(() => box.containsKey('item2')).thenReturn(true);
        when(() => box.containsKey('none')).thenReturn(false);
        when(() => hive.getBoxWithoutCheckInternal('box')).thenReturn(box);

        var item1 = _getHiveObject('item1', box);
        var item2 = _getHiveObject('item2', box);

        var list = HiveListImpl.lazy('box', ['item1', 'none', 'item2', 'item1'])
          ..debugHive = hive;
        expect(list.delegate, [item1, item2, item1]);
        expect(item1.debugHiveLists, {list: 2});
        expect(item2.debugHiveLists, {list: 1});
      });
    });

    group('.dispose()', () {
      test('unlinks remote HiveObjects if delegate exists', () {
        var box = _mockBox();
        var item1 = _getHiveObject('item1', box);
        var item2 = _getHiveObject('item2', box);

        var list = HiveListImpl(box, objects: [item1, item2, item1]);
        list.dispose();

        expect(item1.debugHiveLists, {});
        expect(item2.debugHiveLists, {});
      });
    });

    test('set length', () {
      var box = _mockBox();
      var item1 = _getHiveObject('item1', box);
      var item2 = _getHiveObject('item2', box);

      var list = HiveListImpl(box, objects: [item1, item2]);
      list.length = 1;

      expect(item2.debugHiveLists, {});
      expect(list, [item1]);
    });

    group('operator []=', () {
      test('sets key at index', () {
        var box = _mockBox();
        var oldItem = _getHiveObject('old', box);
        var newItem = _getHiveObject('new', box);

        var list = HiveListImpl(box, objects: [oldItem]);
        list[0] = newItem;

        expect(oldItem.debugHiveLists, {});
        expect(newItem.debugHiveLists, {list: 1});
        expect(list, [newItem]);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var box = _mockBox();
        var oldItem = _getHiveObject('old', box);
        var newItem = _getHiveObject('new', MockBox());

        var list = HiveListImpl(box, objects: [oldItem]);
        expect(() => list[0] = newItem, throwsHiveError());
      });
    });

    group('.add()', () {
      test('adds key', () {
        var box = _mockBox();
        var item1 = _getHiveObject('item1', box);
        var item2 = _getHiveObject('item2', box);

        var list = HiveListImpl(box, objects: [item1]);
        list.add(item2);

        expect(item2.debugHiveLists, {list: 1});
        expect(list, [item1, item2]);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var box = _mockBox();
        var item = _getHiveObject('item', MockBox());
        var list = HiveListImpl(box);
        expect(() => list.add(item), throwsHiveError('needs to be in the box'));
      });
    });

    group('.addAll()', () {
      test('adds keys', () {
        var box = _mockBox();
        var item1 = _getHiveObject('item1', box);
        var item2 = _getHiveObject('item2', box);

        var list = HiveListImpl(box, objects: [item1]);
        list.addAll([item2, item2]);

        expect(item2.debugHiveLists, {list: 2});
        expect(list, [item1, item2, item2]);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var box = _mockBox();
        var item = _getHiveObject('item', MockBox());

        var list = HiveListImpl(box);
        expect(() => list.addAll([item]),
            throwsHiveError('needs to be in the box'));
      });
    });
  });
}
