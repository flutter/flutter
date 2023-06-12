import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'integration.dart';

class _TestObject with HiveObjectMixin {
  String name;

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
    return _TestObject(reader.readString());
  }

  @override
  void write(BinaryWriter writer, _TestObject obj) {
    writer.writeString(obj.name);
  }
}

Future _performTest(bool lazy) async {
  var hive = await createHive();
  hive.registerAdapter<_TestObject>(_TestObjectAdapter());
  var box = await openBox(lazy, hive: hive);

  var obj1 = _TestObject('test1');
  await box.add(obj1);
  expect(obj1.key, 0);

  var obj2 = _TestObject('test2');
  await box.put('someKey', obj2);
  expect(obj2.key, 'someKey');

  box = await box.reopen();
  obj1 = await box.get(0) as _TestObject;
  obj2 = await box.get('someKey') as _TestObject;
  expect(obj1.name, 'test1');
  expect(obj2.name, 'test2');

  obj1.name = 'test1 updated';
  await obj1.save();
  await obj2.delete();

  box = await box.reopen();
  final newObj1 = await box.get(0) as _TestObject;
  final newObj2 = await box.get('someKey') as _TestObject?;
  expect(newObj1.name, 'test1 updated');
  expect(newObj2, null);

  await box.close();
}

void main() {
  group('use HiveObject to update and delete entries', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
