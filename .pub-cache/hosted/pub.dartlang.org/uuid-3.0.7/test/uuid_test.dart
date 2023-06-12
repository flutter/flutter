import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

void main() {
  var uuid = Uuid();
  const TIME = 1321644961388;

  group('[Version 1 Tests]', () {
    test('IDs created at same mSec are different', () {
      expect(uuid.v1(options: {'mSecs': TIME}),
          isNot(equals(uuid.v1(options: {'mSecs': TIME}))));
    });

    test('Exception thrown when > 10K ids created in 1 ms', () {
      var thrown = false;
      try {
        uuid.v1(options: {'mSecs': TIME, 'nSecs': 10000});
      } catch (e) {
        thrown = true;
      }
      expect(thrown, equals(true));
    });

    test('Clock regression by msec increments the clockseq - mSec', () {
      var uidt = uuid.v1(options: {'mSecs': TIME});
      var uidtb = uuid.v1(options: {'mSecs': TIME - 1});

      expect(
          (int.parse("0x${uidtb.split('-')[3]}") -
              int.parse("0x${uidt.split('-')[3]}")),
          anyOf(equals(1), equals(-16383)));
    });

    test('Clock regression by msec increments the clockseq - nSec', () {
      var uidt = uuid.v1(options: {'mSecs': TIME, 'nSecs': 10});
      var uidtb = uuid.v1(options: {'mSecs': TIME, 'nSecs': 9});

      expect(
          (int.parse("0x${uidtb.split('-')[3]}") -
              int.parse("0x${uidt.split('-')[3]}")),
          equals(1));
    });

    test('Explicit options produce expected id', () {
      var id = uuid.v1(options: {
        'mSecs': 1321651533573,
        'nSecs': 5432,
        'clockSeq': 0x385c,
        'node': [0x61, 0xcd, 0x3c, 0xbb, 0x32, 0x10]
      });

      expect(id, equals('d9428888-122b-11e1-b85c-61cd3cbb3210'));
    });

    test('Ids spanning 1ms boundary are 100ns apart', () {
      var u0 = uuid.v1(options: {'mSecs': TIME, 'nSecs': 9999});
      var u1 = uuid.v1(options: {'mSecs': TIME + 1, 'nSecs': 0});

      var before = u0.split('-')[0], after = u1.split('-')[0];
      var dt = int.parse('0x$after') - int.parse('0x$before');

      expect(dt, equals(1));
    });

    test('Generate lots of codes to see if we get v1 collisions.', () {
      var uuids = <dynamic>{};
      var collisions = 0;
      for (var i = 0; i < 10000000; i++) {
        var code = uuid.v1();
        if (uuids.contains(code)) {
          collisions++;
          print('Collision of code: $code');
        } else {
          uuids.add(code);
        }
      }

      expect(collisions, equals(0));
      expect(uuids.length, equals(10000000));
    });

    test(
        'Generate lots of codes to check we don\'t generate variant 2 V1 codes.',
        () {
      for (var i = 0; i < 10000; i++) {
        var code = Uuid().v1();
        expect(code[19], isNot(equals('d')));
        expect(code[19], isNot(equals('c')));
      }
    });

    test('Using buffers', () {
      var buffer = Uint8List(16);
      var options = {'mSecs': TIME, 'nSecs': 0};

      var wihoutBuffer = uuid.v1(options: options);
      uuid.v1buffer(buffer, options: options);

      expect(Uuid.unparse(buffer), equals(wihoutBuffer));
    });

    test('Using Objects', () {
      var options = {'mSecs': TIME, 'nSecs': 0};

      var regular = uuid.v1(options: options);
      var obj = uuid.v1obj(options: options);

      expect(obj.uuid, equals(regular));
    });
  });

  group('[Version 4 Tests]', () {
    test('Check if V4 is consistent using a static seed', () {
      var u0 = uuid.v4(options: {
        'rng': UuidUtil.mathRNG,
        'namedArgs': Map.fromIterables([const Symbol('seed')], [1])
      });
      var u1 = 'a473ff7b-b3cd-4899-a04d-ea0fbd30a72e';
      expect(u0, equals(u1));
    });

    test('Consistency check with buffer', () {
      var buffer = Uint8List(16);
      uuid.v4buffer(buffer, options: {
        'rng': UuidUtil.mathRNG,
        'namedArgs': Map.fromIterables([const Symbol('seed')], [1])
      });

      var u1 = 'a473ff7b-b3cd-4899-a04d-ea0fbd30a72e';
      expect(Uuid.unparse(buffer), equals(u1));
    });

    test('Using Objects', () {
      var regular = uuid.v4(options: {
        'rng': UuidUtil.mathRNG,
        'namedArgs': Map.fromIterables([const Symbol('seed')], [1])
      });
      var obj = uuid.v4obj(options: {
        'rng': UuidUtil.mathRNG,
        'namedArgs': Map.fromIterables([const Symbol('seed')], [1])
      });

      expect(obj.uuid, equals(regular));
    });

    test('Return same output as entered for "random" option', () {
      var u0 = uuid.v4(options: {
        'random': [
          0x10,
          0x91,
          0x56,
          0xbe,
          0xc4,
          0xfb,
          0xc1,
          0xea,
          0x71,
          0xb4,
          0xef,
          0xe1,
          0x67,
          0x1c,
          0x58,
          0x36
        ]
      });
      var u1 = '109156be-c4fb-41ea-b1b4-efe1671c5836';
      expect(u0, equals(u1));
    });

    test('Make sure that really fast uuid.v4 doesn\'t produce duplicates', () {
      var list = List.filled(1000, null).map((something) => uuid.v4()).toList();
      var setList = list.toSet();
      expect(list.length, equals(setList.length));
    });

    test(
        'Another round of testing uuid.v4 to make sure it doesn\'t produce duplicates on high amounts of entries.',
        () {
      final numToGenerate = 3 * 1000 * 1000;
      final values = <String>{}; // set of strings
      var generator = Uuid();

      var numDuplicates = 0;
      for (var i = 0; i < numToGenerate; i++) {
        final uuid = generator.v4();

        if (!values.contains(uuid)) {
          values.add(uuid);
        } else {
          numDuplicates++;
        }
      }

      expect(numDuplicates, equals(0), reason: 'duplicate UUIDs generated');
    });

    test('Check if V4 supports Microsoft Guid', () {
      var guidString = '2400ee73-282c-4334-e153-08d8f922d1f9';

      var isValidDefault = Uuid.isValidUUID(fromString: guidString);
      expect(isValidDefault, false);

      var isValidRFC = Uuid.isValidUUID(
          fromString: guidString, validationMode: ValidationMode.strictRFC4122);
      expect(isValidRFC, false);

      var isValidNonStrict = Uuid.isValidUUID(
          fromString: guidString, validationMode: ValidationMode.nonStrict);
      expect(isValidNonStrict, true);
    });
  });

  group('[Version 5 Tests]', () {
    test('Using URL namespace and custom name', () {
      var u0 = uuid.v5(Uuid.NAMESPACE_URL, 'www.google.com');
      var u1 = uuid.v5(Uuid.NAMESPACE_URL, 'www.google.com');

      expect(u0, equals(u1));
    });

    test('Using Random namespace and custom name', () {
      var u0 = uuid.v5(null, 'www.google.com');
      var u1 = uuid.v5(null, 'www.google.com');

      expect(u0, isNot(equals(u1)));
    });

    test('Using buffers', () {
      var buffer = Uint8List(16);
      var wihoutBuffer =
          uuid.v5(null, 'www.google.com', options: {'randomNamespace': false});
      uuid.v5buffer(null, 'www.google.com', buffer,
          options: {'randomNamespace': false});

      expect(Uuid.unparse(buffer), equals(wihoutBuffer));
    });

    test('Using Objects', () {
      var regular =
          uuid.v5(null, 'www.google.com', options: {'randomNamespace': false});
      var obj = uuid
          .v5obj(null, 'www.google.com', options: {'randomNamespace': false});

      expect(obj.uuid, equals(regular));
    });
  });

  group('[Parse/Unparse Tests]', () {
    test('Parsing a short/cut-off UUID', () {
      var id = '00112233445566778899aabbccddeeff';
      expect(() => Uuid.parse(id.substring(0, 10)),
          throwsA(isA<FormatException>()));
    });

    test('Parsing a dirty string with a UUID in it', () {
      var id = '00112233445566778899aabbccddeeff';
      expect(() => Uuid.unparse(Uuid.parse('(this is the uuid -> $id$id')),
          throwsA(isA<FormatException>()));
    });

    group('buffer:', () {
      const size = 64;
      final buffer = Uint8List(size);

      group('offset good:', () {
        for (final testCase in {
          'offset=0': 0,
          'offset=1': 1,
          'offset in the middle': 32,
          'offset 16 bytes before the end': size - 16,
        }.entries) {
          test(testCase.key, () {
            final v = Uuid.parse(Uuid.NAMESPACE_OID,
                buffer: buffer, offset: testCase.value);

            expect(Uuid.unparse(v, offset: testCase.value),
                equals(Uuid.NAMESPACE_OID));
          });
        }
      });

      group('offset bad:', () {
        for (final testCase in {
          'offset 15 bytes before end': size - 15,
          'offset at end of buffer': size,
          'offset after end of buffer': size + 1,
          'offset is negative': -1
        }.entries) {
          test(testCase.key, () {
            expect(
                () => Uuid.parse(Uuid.NAMESPACE_OID,
                    buffer: buffer, offset: testCase.value),
                throwsA(isA<RangeError>()));
          });
        }
      });
    });
  });

  group('[UuidValue]', () {
    test('Construct UuidValue instance', () {
      const VALID_UUID = '87cd4eb3-cb88-449b-a1da-e468fd829310';
      expect(Uuid.isValidUUID(fromString: VALID_UUID), true);
      final uuidval = UuidValue(VALID_UUID, true);
      expect(uuidval.uuid, VALID_UUID);
    });

    test('Pass invalid Uuid to constructor', () {
      const INVALID_UUID = 'For sure not a valid UUID';
      expect(Uuid.isValidUUID(fromString: INVALID_UUID), false);
      expect(
          () => UuidValue(INVALID_UUID, true), throwsA(isA<FormatException>()));

      final uuidval = UuidValue(INVALID_UUID, false);
      expect(uuidval.uuid, INVALID_UUID.toLowerCase());
    });

    test('Pass valid Guid to constructor without validation mode', () {
      const VALID_GUID = '2400ee73-282c-4334-e153-08d8f922d1f9';
      expect(Uuid.isValidUUID(fromString: VALID_GUID), false);
      expect(
          () => UuidValue(VALID_GUID, true),
          throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'The provided UUID is not RFC4122 compliant. It seems you might be using a Microsoft GUID. Try setting `validationMode = ValidationMode.nonStrict`',
          )));

      final uuidval = UuidValue(VALID_GUID, false);
      expect(uuidval.uuid, VALID_GUID.toLowerCase());
    });

    test('Pass valid Guid to constructor with validation mode nonStrict', () {
      const VALID_GUID = '2400ee73-282c-4334-e153-08d8f922d1f9';
      expect(
          Uuid.isValidUUID(
              fromString: VALID_GUID, validationMode: ValidationMode.nonStrict),
          true);

      final uuidval = UuidValue(VALID_GUID, true, ValidationMode.nonStrict);
      expect(uuidval.uuid, VALID_GUID.toLowerCase());
    });
  });

  group('[global options]', () {
    final customCalls = <List<int>>[];
    Uint8List customRng(int pos, {required int named}) {
      customCalls.add([pos, named]);
      return Uint8List.fromList(List.filled(16, pos + named));
    }

    var customUuid = Uuid(options: {
      'grng': customRng,
      'gPositionalArgs': const [10],
      'gNamedArgs': const <Symbol, dynamic>{
        #named: 5,
      },
      'v1rng': customRng,
      'v1rngPositionalArgs': const [15],
      'v1rngNamedArgs': const <Symbol, dynamic>{
        #named: 20,
      },
    });

    Matcher containsPair(int pos, int named) => contains(
          allOf(
            hasLength(2),
            predicate<List<int>>(
              (data) => data[0] == pos,
              'first element is $pos',
            ),
            predicate<List<int>>(
              (data) => data[1] == named,
              'second element is $named',
            ),
          ),
        );

    setUp(() {
      customCalls.clear();
    });

    test('uses custom v4 generator', () {
      final v4Uuid = customUuid.v4();

      expect(v4Uuid, '0f0f0f0f-0f0f-4f0f-8f0f-0f0f0f0f0f0f');

      expect(customCalls, containsPair(10, 5));
    });

    test('uses v4 call options over global options', () {
      final v4Uuid = customUuid.v4(options: {
        'rng': (int arg) => customRng(arg, named: arg + 1),
        'positionalArgs': const [3],
      });

      expect(v4Uuid, '07070707-0707-4707-8707-070707070707');

      expect(customCalls, containsPair(3, 4));
    });

    test('uses custom v1 generator', () {
      final v1Uuid = customUuid.v1();

      expect(v1Uuid, endsWith('-232323232323'));

      expect(customCalls, containsPair(15, 20));
    });
  });
}
