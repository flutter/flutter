import 'package:hive/hive.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:test/test.dart';

import 'integration.dart';

class _TestObject extends HiveObject {
  String? name;

  HiveList<_TestObject>? list;

  _TestObject(this.name);

  @override
  bool operator ==(dynamic other) => other is _TestObject && other.name == name;

  @override
  int get hashCode => runtimeType.hashCode ^ name.hashCode;
}

class _TestObjectAdapter extends TypeAdapter<_TestObject> {
  @override
  int get typeId => 0;

  @override
  _TestObject read(BinaryReader reader) {
    return _TestObject(reader.read() as String?)
      ..list = (reader.read() as HiveList?)?.castHiveList();
  }

  @override
  void write(BinaryWriter writer, _TestObject obj) {
    writer.write(obj.name);
    writer.write(obj.list);
  }
}

void main() {
  test('add and remove objects to / from HiveList', () async {
    var hive = await createHive();
    hive.registerAdapter(_TestObjectAdapter());
    var box = await openBox<_TestObject>(false, hive: hive) as Box<_TestObject>;

    var obj = _TestObject('obj');
    obj.list = HiveListImpl(box);
    await box.put('obj', obj);

    for (var i = 0; i < 100; i++) {
      var element = _TestObject('element$i');
      await box.add(element);
      obj.list!.add(element);
    }

    await obj.save();

    box = (await box.reopen()) as Box<_TestObject>;
    obj = box.get('obj')!;
    (obj.list as HiveListImpl).debugHive = hive;

    for (var i = 0; i < 100; i++) {
      expect(obj.list![i].name, 'element$i');
    }

    await obj.list![99].delete();
    expect(obj.list!.length, 99);

    await obj.list![50].delete();
    expect(obj.list![50].name, 'element51');

    await obj.list![0].delete();
    expect(obj.list![0].name, 'element1');
  }, timeout: longTimeout);
}
