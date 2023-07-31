// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/summary/flat_buffers.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuilderTest);
  });
}

@reflectiveTest
class BuilderTest {
  void test_error_addInt32_withoutStartTable() {
    Builder builder = Builder();
    expect(() {
      builder.addInt32(0, 0);
    }, throwsStateError);
  }

  void test_error_addOffset_withoutStartTable() {
    Builder builder = Builder();
    expect(() {
      builder.addOffset(0, Offset(0));
    }, throwsStateError);
  }

  void test_error_endTable_withoutStartTable() {
    Builder builder = Builder();
    expect(() {
      builder.endTable();
    }, throwsStateError);
  }

  void test_error_startTable_duringTable() {
    Builder builder = Builder();
    builder.startTable();
    expect(() {
      builder.startTable();
    }, throwsStateError);
  }

  void test_error_writeString_duringTable() {
    Builder builder = Builder();
    builder.startTable();
    expect(() {
      builder.writeString('12345');
    }, throwsStateError);
  }

  void test_file_identifier() {
    Uint8List byteList;
    {
      Builder builder = Builder(initialSize: 0);
      builder.startTable();
      Offset offset = builder.endTable();
      byteList = builder.finish(offset, 'Az~ÿ');
    }
    // Convert byteList to a ByteData so that we can read data from it.
    ByteData byteData = byteList.buffer.asByteData(byteList.offsetInBytes);
    // First 4 bytes are an offset to the table data.
    int tableDataLoc = byteData.getUint32(0, Endian.little);
    // Next 4 bytes are the file identifier.
    expect(byteData.getUint8(4), 65); // 'a'
    expect(byteData.getUint8(5), 122); // 'z'
    expect(byteData.getUint8(6), 126); // '~'
    expect(byteData.getUint8(7), 255); // 'ÿ'
    // First 4 bytes of the table data are a backwards offset to the vtable.
    int vTableLoc =
        tableDataLoc - byteData.getInt32(tableDataLoc, Endian.little);
    // First 2 bytes of the vtable are the size of the vtable in bytes, which
    // should be 4.
    expect(byteData.getUint16(vTableLoc, Endian.little), 4);
    // Next 2 bytes are the size of the object in bytes (including the vtable
    // pointer), which should be 4.
    expect(byteData.getUint16(vTableLoc + 2, Endian.little), 4);
  }

  void test_low() {
    Builder builder = Builder(initialSize: 0);
    builder.lowReset();
    expect((builder..lowWriteUint8(1)).lowFinish(), [1]);
    expect((builder..lowWriteUint32(2)).lowFinish(), [2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint8(3)).lowFinish(),
        [0, 0, 0, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint8(4)).lowFinish(),
        [0, 0, 4, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint8(5)).lowFinish(),
        [0, 5, 4, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint32(6)).lowFinish(),
        [6, 0, 0, 0, 0, 5, 4, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
  }

  void test_table_default() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      builder.startTable();
      builder.addInt32(0, 10, 10);
      builder.addInt32(1, 20, 10);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buffer = BufferContext.fromBytes(byteList);
    int objectOffset = buffer.derefObject(0);
    // was not written, so uses the new default value
    expect(const Int32Reader().vTableGet(buffer, objectOffset, 0, 15), 15);
    // has the written value
    expect(const Int32Reader().vTableGet(buffer, objectOffset, 1, 15), 20);
  }

  void test_table_format() {
    Uint8List byteList;
    {
      Builder builder = Builder(initialSize: 0);
      builder.startTable();
      builder.addInt32(0, 10);
      builder.addInt32(1, 20);
      builder.addInt32(2, 30);
      byteList = builder.finish(builder.endTable());
    }
    // Convert byteList to a ByteData so that we can read data from it.
    ByteData byteData = byteList.buffer.asByteData(byteList.offsetInBytes);
    // First 4 bytes are an offset to the table data.
    int tableDataLoc = byteData.getUint32(0, Endian.little);
    // First 4 bytes of the table data are a backwards offset to the vtable.
    int vTableLoc =
        tableDataLoc - byteData.getInt32(tableDataLoc, Endian.little);
    // First 2 bytes of the vtable are the size of the vtable in bytes, which
    // should be 10.
    expect(byteData.getUint16(vTableLoc, Endian.little), 10);
    // Next 2 bytes are the size of the object in bytes (including the vtable
    // pointer), which should be 16.
    expect(byteData.getUint16(vTableLoc + 2, Endian.little), 16);
    // Remaining 6 bytes are the offsets within the object where the ints are
    // located.
    for (int i = 0; i < 3; i++) {
      int offset = byteData.getUint16(vTableLoc + 4 + 2 * i, Endian.little);
      expect(
          byteData.getInt32(tableDataLoc + offset, Endian.little), 10 + 10 * i);
    }
  }

  void test_table_string() {
    String latinString = 'test';
    String unicodeString = 'Проба пера';
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset<String> latinStringOffset = builder.writeString(latinString);
      Offset<String> unicodeStringOffset = builder.writeString(unicodeString);
      builder.startTable();
      builder.addOffset(0, latinStringOffset);
      builder.addOffset(1, unicodeStringOffset);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    int objectOffset = buf.derefObject(0);
    expect(const StringReader().vTableGetOrNull(buf, objectOffset, 0),
        latinString);
    expect(const StringReader().vTableGetOrNull(buf, objectOffset, 1),
        unicodeString);
  }

  void test_table_types() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset<String> stringOffset = builder.writeString('12345');
      builder.startTable();
      builder.addBool(0, true);
      builder.addInt8(1, 10);
      builder.addInt32(2, 20);
      builder.addOffset(3, stringOffset);
      builder.addInt32(4, 40);
      builder.addUint32(5, 0x9ABCDEF0);
      builder.addUint8(6, 0x9A);
      builder.addFloat64(7, -12.34);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    int objectOffset = buf.derefObject(0);
    expect(const BoolReader().vTableGetOrNull(buf, objectOffset, 0), true);
    expect(const Int8Reader().vTableGetOrNull(buf, objectOffset, 1), 10);
    expect(const Int32Reader().vTableGetOrNull(buf, objectOffset, 2), 20);
    expect(const StringReader().vTableGetOrNull(buf, objectOffset, 3), '12345');
    expect(const Int32Reader().vTableGetOrNull(buf, objectOffset, 4), 40);
    expect(
        const Uint32Reader().vTableGetOrNull(buf, objectOffset, 5), 0x9ABCDEF0);
    expect(const Uint8Reader().vTableGetOrNull(buf, objectOffset, 6), 0x9A);
    expect(const Float64Reader().vTableGetOrNull(buf, objectOffset, 7), -12.34);
  }

  void test_writeList_of_Uint32() {
    List<int> values = <int>[10, 100, 12345, 0x9abcdef0];
    // write
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset offset = builder.writeListUint32(values);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<int> items = const Uint32ListReader().read(buf, 0);
    expect(items, hasLength(4));
    expect(items, orderedEquals(values));
  }

  void test_writeList_ofBool() {
    void verifyListBooleans(int len, List<int> trueBits) {
      // write
      List<int> byteList;
      {
        Builder builder = Builder(initialSize: 0);
        List<bool> values = List<bool>.filled(len, false);
        for (int bit in trueBits) {
          values[bit] = true;
        }
        Offset offset = builder.writeListBool(values);
        byteList = builder.finish(offset);
      }
      // read and verify
      BufferContext buf = BufferContext.fromBytes(byteList);
      List<bool> items = const BoolListReader().read(buf, 0);
      expect(items, hasLength(len));
      for (int i = 0; i < items.length; i++) {
        expect(items[i], trueBits.contains(i), reason: 'bit $i of $len');
      }
    }

    verifyListBooleans(0, <int>[]);
    verifyListBooleans(1, <int>[]);
    verifyListBooleans(1, <int>[0]);
    verifyListBooleans(31, <int>[0, 1]);
    verifyListBooleans(31, <int>[1, 2, 24, 25, 30]);
    verifyListBooleans(31, <int>[0, 30]);
    verifyListBooleans(32, <int>[1, 2, 24, 25, 31]);
    verifyListBooleans(33, <int>[1, 2, 24, 25, 32]);
    verifyListBooleans(33, <int>[1, 2, 24, 25, 31, 32]);
    verifyListBooleans(63, <int>[]);
    verifyListBooleans(63, <int>[0, 1, 2, 61, 62]);
    verifyListBooleans(63, List<int>.generate(63, (i) => i));
    verifyListBooleans(64, <int>[]);
    verifyListBooleans(64, <int>[0, 1, 2, 61, 62, 63]);
    verifyListBooleans(64, <int>[1, 2, 62]);
    verifyListBooleans(64, <int>[0, 1, 2, 63]);
    verifyListBooleans(64, List<int>.generate(64, (i) => i));
    verifyListBooleans(100, <int>[0, 3, 30, 60, 90, 99]);
  }

  void test_writeList_ofFloat64() {
    List<double> values = <double>[-1.234567, 3.4E+9, -5.6E-13, 7.8, 12.13];
    // write
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset offset = builder.writeListFloat64(values);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<double> items = const Float64ListReader().read(buf, 0);
    expect(items, hasLength(5));
    expect(items, orderedEquals(values));
  }

  void test_writeList_ofInt32() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset offset = builder.writeListInt32(<int>[1, 2, 3, 4, 5]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<int> items = const ListReader<int>(Int32Reader()).read(buf, 0);
    expect(items, hasLength(5));
    expect(items, orderedEquals(<int>[1, 2, 3, 4, 5]));
  }

  void test_writeList_ofObjects() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      // write the object #1
      Offset object1;
      {
        builder.startTable();
        builder.addInt32(0, 10);
        builder.addInt32(1, 20);
        object1 = builder.endTable();
      }
      // write the object #1
      Offset object2;
      {
        builder.startTable();
        builder.addInt32(0, 100);
        builder.addInt32(1, 200);
        object2 = builder.endTable();
      }
      // write the list
      Offset offset = builder.writeList([object1, object2]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<TestPointImpl> items =
        const ListReader<TestPointImpl>(TestPointReader()).read(buf, 0);
    expect(items, hasLength(2));
    expect(items[0].x, 10);
    expect(items[0].y, 20);
    expect(items[1].x, 100);
    expect(items[1].y, 200);
  }

  void test_writeList_ofStrings_asRoot() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset<String> str1 = builder.writeString('12345');
      Offset<String> str2 = builder.writeString('ABC');
      Offset offset = builder.writeList([str1, str2]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<String> items = const ListReader<String>(StringReader()).read(buf, 0);
    expect(items, hasLength(2));
    expect(items, contains('12345'));
    expect(items, contains('ABC'));
  }

  void test_writeList_ofStrings_inObject() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset listOffset = builder.writeList(
          [builder.writeString('12345'), builder.writeString('ABC')]);
      builder.startTable();
      builder.addOffset(0, listOffset);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    StringListWrapperImpl reader = StringListWrapperReader().read(buf, 0);
    List<String> items = reader.items!;
    expect(items, hasLength(2));
    expect(items, contains('12345'));
    expect(items, contains('ABC'));
  }

  void test_writeList_ofUint32() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset offset = builder.writeListUint32(<int>[1, 2, 0x9ABCDEF0]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<int> items = const Uint32ListReader().read(buf, 0);
    expect(items, hasLength(3));
    expect(items, orderedEquals(<int>[1, 2, 0x9ABCDEF0]));
  }

  void test_writeList_ofUint8() {
    List<int> byteList;
    {
      Builder builder = Builder(initialSize: 0);
      Offset offset = builder.writeListUint8(<int>[1, 2, 3, 4, 0x9A]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferContext buf = BufferContext.fromBytes(byteList);
    List<int> items = const Uint8ListReader().read(buf, 0);
    expect(items, hasLength(5));
    expect(items, orderedEquals(<int>[1, 2, 3, 4, 0x9A]));
  }
}

class StringListWrapperImpl {
  final BufferContext bp;
  final int offset;

  StringListWrapperImpl(this.bp, this.offset);

  List<String>? get items =>
      const ListReader<String>(StringReader()).vTableGetOrNull(bp, offset, 0);
}

class StringListWrapperReader extends TableReader<StringListWrapperImpl> {
  const StringListWrapperReader();

  @override
  StringListWrapperImpl createObject(BufferContext object, int offset) {
    return StringListWrapperImpl(object, offset);
  }
}

class TestPointImpl {
  final BufferContext bp;
  final int offset;

  TestPointImpl(this.bp, this.offset);

  int get x => const Int32Reader().vTableGet(bp, offset, 0, 0);

  int get y => const Int32Reader().vTableGet(bp, offset, 1, 0);
}

class TestPointReader extends TableReader<TestPointImpl> {
  const TestPointReader();

  @override
  TestPointImpl createObject(BufferContext object, int offset) {
    return TestPointImpl(object, offset);
  }
}
