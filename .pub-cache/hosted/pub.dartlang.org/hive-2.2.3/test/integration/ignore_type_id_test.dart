import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'integration.dart';

class TestObject {
  TestObject(this.value);

  final int value;
}

class TestAdapter extends TypeAdapter<TestObject> {
  TestAdapter();

  @override
  final int typeId = 10;

  @override
  TestObject read(BinaryReader reader) {
    return TestObject(reader.readInt32());
  }

  @override
  void write(BinaryWriter writer, obj) {
    writer.writeInt32(obj.value);
  }
}

void main() {
  test('ignore typeId with IgnoredTypeAdapter', () async {
    var hive = await createHive();
    var box1 = await hive.openBox('test');

    hive.registerAdapter(TestAdapter());

    await box1.put(1, TestObject(5));
    await box1.put(2, 42);
    await box1.put(3, 78);
    await box1.close();

    hive.resetAdapters();
    hive.ignoreTypeId(10);

    var box2 = await hive.openBox('test');

    expect(box2, isNotNull);
    expect(box2.get(1), null);
    expect(box2.get(2), 42);
    expect(box2.get(3), 78);
  });
}
