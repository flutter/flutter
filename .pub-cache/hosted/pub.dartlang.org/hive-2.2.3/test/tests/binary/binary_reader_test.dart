import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../frames.dart';

BinaryReader fromByteData(ByteData byteData) {
  return BinaryReaderImpl(byteData.buffer.asUint8List(), TypeRegistryImpl());
}

BinaryReaderImpl fromBytes(List<int> bytes) {
  return BinaryReaderImpl(Uint8List.fromList(bytes), TypeRegistryImpl());
}

void main() {
  group('BinaryReader', () {
    test('.skip()', () {
      var byteData = ByteData(20);
      var br = fromByteData(byteData);

      expect(br.availableBytes, 20);
      expect(br.usedBytes, 0);

      br.skip(5);
      expect(br.availableBytes, 15);
      expect(br.usedBytes, 5);

      br.skip(0);
      expect(br.availableBytes, 15);
      expect(br.usedBytes, 5);

      br.skip(15);
      expect(br.availableBytes, 0);
      expect(br.usedBytes, 20);

      expect(() => br.skip(1), throwsA(anything));
    });

    test('.readByte()', () {
      var byteData = ByteData(3)
        ..setUint8(0, 0)
        ..setUint8(1, 17)
        ..setUint8(2, 255);
      var br = fromByteData(byteData);

      expect(br.readByte(), 0);
      expect(br.readByte(), 17);
      expect(br.readByte(), 255);
      expect(() => br.readByte(), throwsA(anything));
    });

    test('.viewBytes()', () {
      var byteData = ByteData(3)
        ..setUint8(0, 0)
        ..setUint8(1, 17)
        ..setUint8(2, 255);
      var br = fromByteData(byteData);

      var bytes = br.viewBytes(3);
      expect(bytes, [0, 17, 255]);

      byteData.setUint8(1, 57);
      expect(bytes, [0, 57, 255]);

      expect(() => br.viewBytes(1), throwsA(anything));
    });

    test('.peekBytes()', () {
      var byteData = ByteData(3)
        ..setUint8(0, 0)
        ..setUint8(1, 17)
        ..setUint8(2, 255);
      var br = fromByteData(byteData);

      expect(br.peekBytes(3), [0, 17, 255]);
      expect(br.viewBytes(3), [0, 17, 255]);
    });

    test('.readWord()', () {
      var byteData = ByteData(4)
        ..setUint16(0, 0, Endian.little)
        ..setUint16(2, 65535, Endian.little);
      var br = fromByteData(byteData);

      expect(br.readWord(), 0);
      expect(br.readWord(), 65535);
      expect(() => br.readWord(), throwsA(anything));
    });

    test('.readInt32()', () {
      var byteData = ByteData(12)
        ..setInt32(0, 0, Endian.little)
        ..setInt32(4, 65535, Endian.little)
        ..setInt32(8, -65536, Endian.little);
      var br = fromByteData(byteData);

      expect(br.readInt32(), 0);
      expect(br.readInt32(), 65535);
      expect(br.readInt32(), -65536);
      expect(() => br.readInt32(), throwsA(anything));
    });

    test('.readUint32()', () {
      var byteData = ByteData(8)
        ..setUint32(0, 0, Endian.little)
        ..setUint32(4, 4294967295, Endian.little);
      var br = fromByteData(byteData);

      expect(br.readUint32(), 0);
      expect(br.readUint32(), 4294967295);
      expect(() => br.readUint32(), throwsA(anything));
    });

    test('.readInt()', () {
      var byteData = ByteData(24)
        ..setFloat64(0, 0, Endian.little)
        ..setFloat64(8, (2 ^ 53).toDouble(), Endian.little)
        ..setFloat64(16, (-2 ^ 53).toDouble(), Endian.little);
      var br = fromByteData(byteData);

      expect(br.readInt(), 0);
      expect(br.readInt(), 2 ^ 53);
      expect(br.readInt(), -2 ^ 53);
      expect(() => br.readInt(), throwsA(anything));
    });

    test('.readDouble()', () {
      var byteData = ByteData(48)
        ..setFloat64(0, 0, Endian.little)
        ..setFloat64(8, double.nan, Endian.little)
        ..setFloat64(16, double.infinity, Endian.little)
        ..setFloat64(24, double.negativeInfinity, Endian.little)
        ..setFloat64(32, double.maxFinite, Endian.little)
        ..setFloat64(40, double.minPositive, Endian.little);
      var br = fromByteData(byteData);

      expect(br.readDouble(), 0);
      expect(br.readDouble().isNaN, true);
      expect(br.readDouble(), double.infinity);
      expect(br.readDouble(), double.negativeInfinity);
      expect(br.readDouble(), double.maxFinite);
      expect(br.readDouble(), double.minPositive);
      expect(() => br.readDouble(), throwsA(anything));
    });

    test('.readBool()', () {
      var byteData = ByteData(3)
        ..setUint8(0, 1)
        ..setUint8(1, 0)
        ..setUint8(2, 2);
      var br = fromByteData(byteData);

      expect(br.readBool(), true);
      expect(br.readBool(), false);
      expect(br.readBool(), true);
      expect(() => br.readBool(), throwsA(anything));
    });

    test('.readString()', () {
      var br = fromBytes([0, 0, 0, 0]);
      expect(br.readString(), '');

      br = fromBytes([]);
      expect(br.readString(0), '');

      br = fromBytes([
        12, 0, 0, 0, 0xf0, 0xa0, 0x81, 0xa0, 0xf0, //
        0x9f, 0x87, 0xac, 0xf0, 0x9f, 0x87, 0xb5 //
      ]);
      expect(br.readString(), '𠁠🇬🇵');

      br = fromBytes([
        0xf0, 0x9f, 0x91, 0xa8, 0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa8, //
        0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa7, 0xe2, 0x80, 0x8d, 0xf0, //
        0x9f, 0x91, 0xa6 //
      ]);
      expect(br.readString(25), '👨‍👨‍👧‍👦');

      expect(() => br.readString(), throwsRangeError);
    });

    test('.readByteList()', () {
      var br = fromBytes([0, 0, 0, 0]);
      expect(br.readByteList(), []);

      br = fromBytes([]);
      expect(br.readByteList(0), []);

      br = fromBytes([4, 0, 0, 0, 1, 2, 3, 4]);
      expect(br.readByteList(), [1, 2, 3, 4]);

      br = fromBytes([1, 2, 3, 4]);
      expect(br.readByteList(4), [1, 2, 3, 4]);

      expect(() => br.readByteList(1), throwsRangeError);
    });

    test('.readIntList()', () {
      var br = fromBytes([0, 0, 0, 0]);
      expect(br.readIntList(), []);

      br = fromBytes([]);
      expect(br.readIntList(0), []);

      br = fromBytes([
        2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 240, 63, //
        0, 0, 0, 0, 0, 0, 0, 64
      ]);
      expect(br.readIntList(), [1, 2]);

      br = fromBytes([0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 64]);
      expect(br.readIntList(2), [1, 2]);

      expect(() => br.readIntList(), throwsRangeError);
    });

    test('.readDoubleList()', () {
      var br = fromBytes([0, 0, 0, 0]);
      expect(br.readDoubleList(), []);

      br = fromBytes([]);
      expect(br.readDoubleList(0), []);

      br = fromBytes([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 240, 63]);
      expect(br.readDoubleList(), [1.0]);

      br = fromBytes([0, 0, 0, 0, 0, 0, 240, 63]);
      expect(br.readDoubleList(1), [1.0]);

      expect(() => br.readDoubleList(), throwsRangeError);
    });

    test('.readBoolList()', () {
      var br = fromBytes([0, 0, 0, 0]);
      expect(br.readBoolList(), []);

      br = fromBytes([]);
      expect(br.readBoolList(0), []);

      br = fromBytes([3, 0, 0, 0, 1, 0, 25]);
      expect(br.readBoolList(), [true, false, true]);

      br = fromBytes([1, 0, 136]);
      expect(br.readBoolList(3), [true, false, true]);

      expect(() => br.readBoolList(), throwsRangeError);
    });

    test('.readStringList()', () {
      var br = fromBytes([0, 0, 0, 0]);
      expect(br.readStringList(), []);

      br = fromBytes([]);
      expect(br.readStringList(0), []);

      br = fromBytes([
        2, 0, 0, 0, 1, 0, 0, 0, 97, 13, 0, 0, 0, 0xf0, 0x9f, 0xa7, 0x99, //
        0xe2, 0x80, 0x8d, 0xe2, 0x99, 0x82, 0xef, 0xb8, 0x8f //
      ]);
      expect(br.readStringList(), ['a', '🧙‍♂️']);

      br = fromBytes([1, 0, 0, 0, 97, 2, 0, 0, 0, 97, 98]);
      expect(br.readStringList(2), ['a', 'ab']);

      expect(() => br.readStringList(), throwsRangeError);
    });

    test('.readList()', () {
      var br = fromBytes([
        2, 0, 0, 0, FrameValueType.boolT, 1, //
        FrameValueType.stringT, 2, 0, 0, 0, 104, 105 //
      ]);
      expect(br.readList(), [true, 'hi']);

      br = fromBytes([
        FrameValueType.boolT, 1, //
        FrameValueType.stringT, 2, 0, 0, 0, 104, 105 //
      ]);
      expect(br.readList(2), [true, 'hi']);

      expect(() => br.readList(), throwsRangeError);
    });

    test('.readMap()', () {
      var br = fromBytes([
        2, 0, 0, 0, //
        FrameValueType.stringT, 2, 0, 0, 0, 104, 105, //
        FrameValueType.boolT, 1, //
        FrameValueType.boolT, 0, //
        FrameValueType.stringT, 2, 0, 0, 0, 104, 105 //
      ]);
      expect(br.readMap(), {'hi': true, false: 'hi'});

      br = fromBytes([
        FrameValueType.stringT, 2, 0, 0, 0, 104, 105, //
        FrameValueType.boolT, 1, //
        FrameValueType.boolT, 0, //
        FrameValueType.stringT, 2, 0, 0, 0, 104, 105 //
      ]);
      expect(br.readMap(2), {'hi': true, false: 'hi'});

      expect(() => br.readMap(), throwsA(anything));
    });

    group('.readKey()', () {
      test('int key', () {
        var br = fromBytes([0, 123, 0, 0, 0]);
        expect(br.readKey(), 123);
      });

      test('string key', () {
        var br = fromBytes([1, 2, 104, 105]);
        expect(br.readKey(), 'hi');
      });

      test('wrong key type', () {
        var br = fromBytes([2, 0, 0, 0, 0]);
        expect(() => br.readKey(), throwsHiveError('unsupported key type'));
      });
    });

    group('.readHiveList()', () {
      test('read length', () {
        var br = fromBytes([
          2, 0, 0, 0, //
          3, 66, 111, 120, //
          0, 123, 0, 0, 0, //
          1, 2, 104, 105, //
        ]);
        var hiveList = br.readHiveList() as HiveListImpl;
        expect(hiveList.boxName, 'Box');
        expect(hiveList.keys, [123, 'hi']);
      });

      test('given length', () {
        var br = fromBytes([
          3, 66, 111, 120, //
          0, 123, 0, 0, 0, //
          1, 2, 104, 105, //
        ]);
        var hiveList = br.readHiveList(2) as HiveListImpl;
        expect(hiveList.boxName, 'Box');
        expect(hiveList.keys, [123, 'hi']);
      });
    });

    group('.readFrame()', () {
      final List<Uint8List> nullFramesBytes = [
        // availableBytes < 4
        // there is ONLY 3 bytes provided
        Uint8List.fromList([8, 0, 0]),
        // frameLength < 8
        // frame is 7 length
        Uint8List.fromList([7, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        // availableBytes < frameLength - 4
        // frame is 10 length however ONLY 9 bytes provided
        Uint8List.fromList([10, 0, 0, 0, 0, 0, 0, 0, 0]),
        // computedCrc != crc
        // 0, 0, 0, 0 crc is: 0 and computedCrc is: 274301637
        Uint8List.fromList([10, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      ];

      test('null', () {
        for (final bytes in nullFramesBytes) {
          final reader = BinaryReaderImpl(bytes, testRegistry);
          final frame = reader.readFrame(lazy: false);

          expect(frame, null);
        }
      });

      test('null lazy', () {
        for (final bytes in nullFramesBytes) {
          final reader = BinaryReaderImpl(bytes, testRegistry);
          final frame = reader.readFrame(lazy: true);

          expect(frame, null);
        }
      });

      test('normal', () {
        var frames = framesSetLengthOffset(testFrames, frameBytes);
        var offset = 0;
        for (var i = 0; i < frames.length; i++) {
          final frame = frames[i];
          var reader = BinaryReaderImpl(frameBytes[i], testRegistry);
          expectFrame(
            reader.readFrame(lazy: false, frameOffset: offset)!,
            frame,
          );
          offset += frameBytes[i].length;
        }
      });

      test('lazy', () {
        var frames = framesSetLengthOffset(testFrames, frameBytes);
        var offset = 0;
        for (var i = 0; i < frames.length; i++) {
          final frame = frames[i];
          var reader = BinaryReaderImpl(frameBytes[i], testRegistry);
          expectFrame(
            reader.readFrame(lazy: true, frameOffset: offset)!,
            frame.toLazy(),
          );
          offset += frameBytes[i].length;
        }
      });

      test('encrypted', () {
        var frames = framesSetLengthOffset(testFrames, frameBytesEncrypted);
        var offset = 0;
        for (var i = 0; i < frames.length; i++) {
          final frame = frames[i];
          var reader = BinaryReaderImpl(frameBytesEncrypted[i], testRegistry);
          expectFrame(
            reader.readFrame(
              lazy: false,
              frameOffset: offset,
              cipher: testCipher,
            )!,
            frame,
          );
          offset += frameBytesEncrypted[i].length;
        }
      });

      test('encrypted lazy', () {
        var frames = framesSetLengthOffset(testFrames, frameBytesEncrypted);
        var offset = 0;
        for (var i = 0; i < frames.length; i++) {
          final frame = frames[i];
          var reader = BinaryReaderImpl(frameBytesEncrypted[i], testRegistry);
          expectFrame(
            reader.readFrame(
              lazy: true,
              frameOffset: offset,
              cipher: testCipher,
            )!,
            frame.toLazy(),
          );
          offset += frameBytesEncrypted[i].length;
        }
      });
    });

    group('.read()', () {
      test('null', () {
        var br = fromBytes([]);
        expect(br.read(FrameValueType.nullT), null);

        br = fromBytes([FrameValueType.nullT]);
        expect(br.read(), null);
      });

      test('int', () {
        var byteData = ByteData(8)..setFloat64(0, 12345, Endian.little);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.intT), 12345);

        byteData = ByteData(9)
          ..setUint8(0, FrameValueType.intT)
          ..setFloat64(1, 12345, Endian.little);
        br = fromByteData(byteData);
        expect(br.read(), 12345);
      });

      test('double', () {
        var byteData = ByteData(8)..setFloat64(0, 234.99283, Endian.little);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.doubleT), 234.99283);

        byteData = ByteData(9)
          ..setUint8(0, FrameValueType.doubleT)
          ..setFloat64(1, 234.99283, Endian.little);
        br = fromByteData(byteData);
        expect(br.read(), 234.99283);
      });

      test('bool', () {
        var byteData = ByteData(2)..setUint8(0, 1);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.boolT), true);

        byteData = ByteData(2)
          ..setUint8(0, FrameValueType.boolT)
          ..setInt8(1, 1);
        br = fromByteData(byteData);
        expect(br.read(), true);
      });

      test('string', () {
        var br = fromBytes([2, 0, 0, 0, 104, 105]);
        expect(br.read(FrameValueType.stringT), 'hi');

        br = fromBytes([FrameValueType.stringT, 2, 0, 0, 0, 104, 105]);
        expect(br.read(), 'hi');
      });

      test('byte list', () {
        var br = fromBytes([
          5, 0, 0, 0, //
          1, 2, 3, 4, 5, //
        ]);
        expect(br.read(FrameValueType.byteListT), [1, 2, 3, 4, 5]);

        br = fromBytes([
          FrameValueType.byteListT, //
          5, 0, 0, 0, //
          1, 2, 3, 4, 5, //
        ]);
        expect(br.read(), [1, 2, 3, 4, 5]);
      });

      test('int list', () {
        var byteData = ByteData(20)
          ..setUint32(0, 2, Endian.little)
          ..setFloat64(4, 12345, Endian.little)
          ..setFloat64(12, 123, Endian.little);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.intListT), [12345, 123]);

        byteData = ByteData(21)
          ..setUint8(0, FrameValueType.intListT)
          ..setUint32(1, 2, Endian.little)
          ..setFloat64(5, 12345, Endian.little)
          ..setFloat64(13, 123, Endian.little);
        br = fromByteData(byteData);
        expect(br.read(), [12345, 123]);
      });

      test('double list', () {
        var byteData = ByteData(20)
          ..setUint32(0, 2, Endian.little)
          ..setFloat64(4, 11.11, Endian.little)
          ..setFloat64(12, 12.12, Endian.little);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.doubleListT), [11.11, 12.12]);

        byteData = ByteData(21)
          ..setUint8(0, FrameValueType.doubleListT)
          ..setUint32(1, 2, Endian.little)
          ..setFloat64(5, 11.11, Endian.little)
          ..setFloat64(13, 12.12, Endian.little);
        br = fromByteData(byteData);
        expect(br.read(), [11.11, 12.12]);
      });

      test('bool list', () {
        var byteData = ByteData(6)
          ..setUint32(0, 2, Endian.little)
          ..setUint8(4, 0)
          ..setUint8(5, 1);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.boolListT), [false, true]);

        byteData = ByteData(7)
          ..setUint8(0, FrameValueType.boolListT)
          ..setUint32(1, 2, Endian.little)
          ..setUint8(5, 0)
          ..setUint8(6, 1);
        br = fromByteData(byteData);
        expect(br.read(), [false, true]);
      });

      test('string list', () {
        var br = fromBytes([2, 0, 0, 0, 2, 0, 0, 0, 104, 105, 1, 0, 0, 0, 104]);
        expect(br.read(FrameValueType.stringListT), ['hi', 'h']);

        br = fromBytes([
          FrameValueType.stringListT,
          2, 0, 0, 0, 2, 0, 0, 0, 104, 105, 1, 0, 0, 0, 104 //
        ]);
        expect(br.read(), ['hi', 'h']);
      });

      test('list with null', () {
        var byteData = ByteData(23)
          ..setUint32(0, 3, Endian.little)
          ..setUint8(4, FrameValueType.intT)
          ..setFloat64(5, 12345, Endian.little)
          ..setUint8(13, FrameValueType.intT)
          ..setFloat64(14, 123, Endian.little)
          ..setUint8(22, FrameValueType.nullT);
        var br = fromByteData(byteData);
        expect(br.read(FrameValueType.listT), [12345, 123, null]);

        byteData = ByteData(24)
          ..setInt8(0, FrameValueType.listT)
          ..setUint32(1, 3, Endian.little)
          ..setUint8(5, FrameValueType.intT)
          ..setFloat64(6, 12345, Endian.little)
          ..setUint8(14, FrameValueType.intT)
          ..setFloat64(15, 123, Endian.little)
          ..setUint8(23, FrameValueType.nullT);
        br = fromByteData(byteData);
        expect(br.read(), [12345, 123, null]);
      });

      test('HiveList', () {
        var br = fromBytes([
          FrameValueType.hiveListT, 2, 0, 0, 0, //
          3, 66, 111, 120, //
          0, 123, 0, 0, 0, //
          1, 2, 104, 105, //
        ]);

        var hiveList = br.read() as HiveListImpl;
        expect(hiveList.boxName, 'Box');
        expect(hiveList.keys, [123, 'hi']);
      });
    });
  });
}
