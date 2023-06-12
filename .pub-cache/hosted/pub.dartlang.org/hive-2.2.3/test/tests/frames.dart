import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

export '../generated/frame_values.g.dart';
export '../generated/frame_values_encrypted.g.dart';
export '../generated/frames.g.dart';
export '../generated/frames_encrypted.g.dart';

TypeRegistry get testRegistry => HiveImpl();

class _HiveAesCipherStaticIV extends HiveAesCipher {
  _HiveAesCipherStaticIV() : super(Uint8List.fromList(List.filled(32, 1)));

  @override
  Uint8List generateIv() => Uint8List.fromList(List.filled(16, 4));
}

HiveCipher get testCipher => _HiveAesCipherStaticIV();

List<Frame> get testFrames => <Frame>[
      Frame.deleted(0),
      Frame.deleted(555),
      Frame(123, null),
      Frame(0, 'Int key1'),
      Frame(1, 'Int key2'),
      Frame(2 ^ 32 - 1, 'Int key3'),
      Frame.deleted('Tombstone frame'),
      Frame('Null frame', null),
      Frame('Int', 123123123),
      Frame('Large int', 2 ^ 32),
      Frame('Bool true', true),
      Frame('Bool false', false),
      Frame('Float', 12312.991283),
      Frame('Unicode string',
          'A few characters which are not ASCII: 🇵🇬 😀 🐝 걟 ＄ 乽 👨‍🚀'),
      Frame('Empty list', []),
      Frame('Byte list', Uint8List.fromList([1, 12, 123, 1234])),
      Frame('Byte list with mask', Uint8List.fromList([0x90, 0xA9, 1, 2, 3])),
      Frame('Int list', [123, 456, 129318238]),
      Frame('Bool list', [true, false, false, true]),
      Frame('Double list', [
        10.1723812,
        double.infinity,
        double.maxFinite,
        double.minPositive,
        double.negativeInfinity
      ]),
      Frame('String list', [
        'hello',
        '🧙‍♂️ 👨‍👨‍👧‍👦 ',
        ' ﻬ ﻭ ﻮ ﻯ ﻰ ﻱ',
        'അ ആ ഇ ',
        ' צּ קּ רּ שּ ',
        'ｩ ｪ ｫ ｬ ｭ ｮ ｯ ｰ '
      ]),
      Frame('List with null', ['This', 'is', 'a', 'test', null]),
      Frame('List with different types', [
        'List',
        [1, 2, 3],
        5.8,
        true,
        12341234,
        {'t': true, 'f': false},
      ]),
      Frame('Map', {
        'Bool': true,
        'Int': 1234,
        'Double': 15.7,
        'String': 'Hello',
        'List': [1, 2, null],
        'Null': null,
        'Map': {'Key': 'Val', 'Key2': 2}
      }),
      Frame('DateTime test', [
        DateTimeWithoutTZ.fromMillisecondsSinceEpoch(0),
        DateTimeWithoutTZ.fromMillisecondsSinceEpoch(1566656623020),
      ]),
      Frame('BigInt Test',
          BigInt.parse('1234567890123456789012345678901234567890'))
    ];

List<Frame> framesSetLengthOffset(List<Frame> frames, List<Uint8List> bytes) {
  var offset = 0;
  for (var i = 0; i < frames.length; i++) {
    var length = bytes[i].length;
    frames[i]
      ..offset = offset
      ..length = length;
    offset += length;
  }
  return frames;
}

List<Frame> lazyFrames(List<Frame> frames) {
  return frames.map((f) {
    if (f.deleted) {
      return f;
    } else {
      return Frame.lazy(f.key, offset: f.offset, length: f.length);
    }
  }).toList();
}

List<Frame> get valueTestFrames =>
    testFrames.where((it) => !it.deleted).toList();

Frame frameWithLength(Frame frame, int length) {
  if (frame.deleted) {
    return Frame.deleted(frame.key, length: length);
  } else {
    return Frame(frame.key, frame.value, length: length);
  }
}

Frame frameBodyWithLength(Frame frame, int length) {
  if (frame.deleted) {
    return Frame.deleted(null, length: length);
  } else {
    return Frame(null, frame.value, length: length);
  }
}

Frame lazyFrameWithLength(Frame frame, int length) {
  if (frame.deleted) {
    return Frame.deleted(frame.key, length: length);
  } else {
    return Frame.lazy(frame.key, length: length);
  }
}

void expectFrame(Frame f1, Frame f2) {
  expect(f1.key, f2.key);
  if (f1.value is double && f2.value is double) {
    if (f1.value.isNaN as bool && f1.value.isNaN as bool) return;
  }
  expect(f1.value, f2.value);
  expect(f1.length, f2.length);
  expect(f1.deleted, f2.deleted);
  expect(f1.lazy, f2.lazy);
}

void expectFrames(Iterable<Frame> f1, Iterable<Frame> f2) {
  var frames1 = f1.toList();
  var frames2 = f2.toList();

  expect(frames1.length, f2.length);
  for (var i = 0; i < frames2.length; i++) {
    expectFrame(frames1[i], frames2[i]);
  }
}

void buildGoldens() async {
  Future<void> generate(String fileName, String varName,
      Uint8List Function(Frame frame) transformer) async {
    var file = File('test/generated/$fileName.g.dart');
    await file.create();
    var code = StringBuffer();
    code.writeln("import 'dart:typed_data';\n");
    code.writeln('final $varName = [');
    for (var frame in testFrames) {
      code.writeln('// ${frame.key}');
      var bytes = transformer(frame);
      code.writeln('Uint8List.fromList(${bytes.toString()}),');
    }
    code.writeln('];');
    file.writeAsStringSync(code.toString(), flush: true);
  }

  await generate('frames', 'frameBytes', (f) {
    var writer = BinaryWriterImpl(testRegistry);
    writer.writeFrame(f);
    return writer.toBytes();
  });
  await generate('frame_values', 'frameValuesBytes', (f) {
    var writer = BinaryWriterImpl(HiveImpl())
      ..write(f.value, writeTypeId: false);
    return writer.toBytes();
  });
  await generate('frames_encrypted', 'frameBytesEncrypted', (f) {
    var writer = BinaryWriterImpl(testRegistry);
    writer.writeFrame(f, cipher: testCipher);
    return writer.toBytes();
  });
  await generate('frame_values_encrypted', 'frameValuesBytesEncrypted', (f) {
    var writer = BinaryWriterImpl(HiveImpl())
      ..writeEncrypted(f.value, testCipher, writeTypeId: false);
    return writer.toBytes();
  });
}
