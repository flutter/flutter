#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.11

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import '../out/protos/duplicate_names_import.pb.dart';
import '../out/protos/google/protobuf/unittest.pb.dart';
import '../out/protos/google/protobuf/unittest_import.pb.dart';
import '../out/protos/google/protobuf/unittest_optimize_for.pb.dart';
import '../out/protos/multiple_files_test.pb.dart';
import '../out/protos/package1.pb.dart' as p1;
import '../out/protos/package2.pb.dart' as p2;
import '../out/protos/package3.pb.dart' as p3;
import '../out/protos/reserved_names.pb.dart';
import '../out/protos/reserved_names_extension.pb.dart';
import '../out/protos/reserved_names_message.pb.dart';
import '../out/protos/toplevel.pb.dart';
import '../out/protos/toplevel_import.pb.dart' as t;
import 'test_util.dart';

void main() {
  final throwsInvalidProtocolBufferException =
      throwsA(TypeMatcher<InvalidProtocolBufferException>());
  test('testProtosShareRepeatedArraysIfDidntChange', () {
    var value1 = TestAllTypes()
      ..repeatedInt32.add(100)
      ..repeatedImportEnum.add(ImportEnum.IMPORT_BAR)
      ..repeatedForeignMessage.add(ForeignMessage());

    var value2 = value1.deepCopy();

    expect(value2.repeatedInt32, value1.repeatedInt32);
    expect(value2.repeatedImportEnum, value1.repeatedImportEnum);
    expect(value2.repeatedForeignMessage, value1.repeatedForeignMessage);
  });

  test('testSettersRejectNull', () {
    var message = TestAllTypes();
    expect(() {
      message.optionalString = null;
    }, throwsArgumentError);
    expect(() {
      message.optionalBytes = null;
    }, throwsArgumentError);
    expect(() {
      message.optionalNestedMessage = null;
    }, throwsArgumentError);
    expect(() {
      message.optionalNestedMessage = null;
    }, throwsArgumentError);
    expect(() {
      message.optionalNestedEnum = null;
    }, throwsArgumentError);
    expect(() {
      message.repeatedString.add(null);
    }, throwsArgumentError);
    expect(() {
      message.repeatedBytes.add(null);
    }, throwsArgumentError);
    expect(() {
      message.repeatedNestedMessage.add(null);
    }, throwsArgumentError);
    expect(() {
      message.repeatedNestedMessage.add(null);
    }, throwsArgumentError);
    expect(() {
      message.repeatedNestedEnum.add(null);
    }, throwsArgumentError);
  });

  test('testDefaultMessageIsReadOnly', () {
    var message = TestAllTypes();
    expect(message.optionalNestedMessage,
        same(TestAllTypes_NestedMessage.getDefault()));
    expect(() {
      message.optionalNestedMessage.bb = 123;
    }, throwsUnsupportedError);

    message = TestAllTypes.getDefault();
    expect(() {
      message.clear();
    }, throwsUnsupportedError);
    expect(() {
      message.optionalString = '123';
    }, throwsUnsupportedError);
    expect(() {
      message.clearOptionalString();
    }, throwsUnsupportedError);
    expect(() {
      message.repeatedString.add('123');
    }, throwsUnsupportedError);
    expect(() {
      message.repeatedString.clear();
    }, throwsUnsupportedError);
    expect(() {
      message.unknownFields.clear();
    }, throwsUnsupportedError);
  });

  test('testRepeatedSetters', () {
    var message = getAllSet();
    modifyRepeatedFields(message);
    assertRepeatedFieldsModified(message);
  });

  test('testRepeatedSettersRejectNull', () {
    var message = TestAllTypes();

    message.repeatedString.addAll(['one', 'two']);
    expect(() {
      message.repeatedString[1] = null;
    }, throwsArgumentError);

    message.repeatedBytes.addAll(['one'.codeUnits, 'two'.codeUnits]);
    expect(() {
      message.repeatedBytes[1] = null;
    }, throwsArgumentError);

    message.repeatedNestedMessage.addAll([
      TestAllTypes_NestedMessage()..bb = 318,
      TestAllTypes_NestedMessage()..bb = 456
    ]);
    expect(() {
      message.repeatedNestedMessage[1] = null;
    }, throwsArgumentError);

    message.repeatedNestedEnum
        .addAll([TestAllTypes_NestedEnum.FOO, TestAllTypes_NestedEnum.BAR]);
    expect(() {
      message.repeatedNestedEnum[1] = null;
    }, throwsArgumentError);
  });

  test('testRepeatedAppend', () {
    var message = TestAllTypes()
      ..repeatedInt32.addAll([1, 2, 3, 4])
      ..repeatedForeignEnum.addAll([ForeignEnum.FOREIGN_BAZ])
      ..repeatedForeignMessage.addAll([ForeignMessage()..c = 12]);

    expect(message.repeatedInt32, [1, 2, 3, 4]);
    expect(message.repeatedForeignEnum, [ForeignEnum.FOREIGN_BAZ]);
    expect(message.repeatedForeignMessage.length, 1);
    expect(message.repeatedForeignMessage[0].c, 12);
  });

  test('testRepeatedAppendRejectsNull', () {
    var message = TestAllTypes();

    expect(() {
      message.repeatedForeignMessage.addAll([ForeignMessage()..c = 12, null]);
    }, throwsArgumentError);

    expect(() {
      message.repeatedForeignEnum.addAll([ForeignEnum.FOREIGN_BAZ, null]);
    }, throwsArgumentError);

    expect(() {
      message.repeatedString.addAll(['one', null]);
    }, throwsArgumentError);

    expect(() {
      message.repeatedBytes.addAll(['one'.codeUnits, null]);
    }, throwsArgumentError);
  });

  test('testSettingForeignMessage', () {
    var message = TestAllTypes()
      ..optionalForeignMessage = (ForeignMessage()..c = 123);

    var expectedMessage = TestAllTypes()
      ..optionalForeignMessage = (ForeignMessage()..c = 123);

    expect(message, expectedMessage);
  });

  test('testSettingRepeatedForeignMessage', () {
    var message = TestAllTypes()
      ..repeatedForeignMessage.add(ForeignMessage()..c = 456);

    var expectedMessage = TestAllTypes()
      ..repeatedForeignMessage.add(ForeignMessage()..c = 456);

    expect(message, expectedMessage);
  });

  test('testDefaults', () {
    assertClear(TestAllTypes());

    var message = TestExtremeDefaultValues();

    expect(message.utf8String, '\u1234');
    expect(message.infDouble, same(double.infinity));
    expect(message.negInfDouble, same(double.negativeInfinity));
    expect(message.nanDouble, same(double.nan));
    expect(message.infFloat, same(double.infinity));
    expect(message.negInfFloat, same(double.negativeInfinity));
    expect(message.nanFloat, same(double.nan));
    expect(message.cppTrigraph, '? ? ?? ?? ??? ??/ ??-');
    expect(message.smallInt64.toRadixString(16).toUpperCase(),
        '-7FFFFFFFFFFFFFFF');
  });

  test('testClear', () {
    var message = TestAllTypes();

    assertClear(message);
    setAllFields(message);
    message.clear();
    assertClear(message);
  });

  test('test ensure method', () {
    var message = TestAllTypes();
    expect(message.hasOptionalNestedMessage(), isFalse);
    expect(message.ensureOptionalNestedMessage(), TestAllTypes_NestedMessage());
    expect(message.hasOptionalNestedMessage(), isTrue);
  });

  // void testReflectionGetters() {} // UNSUPPORTED -- until reflection
  // void testReflectionSetters() {} // UNSUPPORTED -- until reflection
  // void testReflectionSettersRejectNull() {} // UNSUPPORTED - reflection
  // void testReflectionRepeatedSetters() {} // UNSUPPORTED -- reflection
  // void testReflectionRepeatedSettersRejectNull() {} // UNSUPPORTED
  // void testReflectionDefaults() {} // UNSUPPORTED -- until reflection

  test('testEnumInterface', () {
    expect(TestAllTypes().defaultNestedEnum, TypeMatcher<ProtobufEnum>());
  });

  test('testEnumMap', () {
    for (var value in ForeignEnum.values) {
      expect(ForeignEnum.valueOf(value.value), value);
    }
    expect(ForeignEnum.valueOf(12345), isNull);
  });

  test('testParsePackedToUnpacked', () {
    var message = TestUnpackedTypes.fromBuffer(getPackedSet().writeToBuffer());
    assertUnpackedFieldsSet(message);
  });

  test('testParseUnpackedToPacked', () {
    var message = TestPackedTypes.fromBuffer(getUnpackedSet().writeToBuffer());
    assertPackedFieldsSet(message);
  });

  test('testIgnoreJavaMultipleFilesOption', () {
    // UNSUPPORTED getFile
    // We mostly just want to check that things compile.
    var message = MessageWithNoOuter()
      ..nested = (MessageWithNoOuter_NestedMessage()..i = 1)
      ..foreign.add(TestAllTypes()..optionalInt32 = 1)
      ..nestedEnum = MessageWithNoOuter_NestedEnum.BAZ
      ..foreignEnum = EnumWithNoOuter.BAR;

    expect(MessageWithNoOuter.fromBuffer(message.writeToBuffer()), message);

    // Not currently supported in Dart protobuf.
    // expect(MessageWithNoOuter.getDescriptor().getFile(),
    //        MultipleFilesTestProto.getDescriptor());

    var tagNumber = message.getTagNumber('foreignEnum');
    expect(tagNumber, isNotNull);
    expect(message.getField(tagNumber), EnumWithNoOuter.BAR);

    // Not currently supported in Dart protobuf.
    // expect(ServiceWithNoOuter.getDescriptor().getFile()
    //        MultipleFilesTestProto.getDescriptor());

    expect(
        TestAllExtensions()
            .hasExtension(Multiple_files_test.extensionWithOuter),
        isFalse);
  });

  test('testOptionalFieldWithRequiredSubfieldsOptimizedForSize', () {
    expect(TestOptionalOptimizedForSize().isInitialized(), isTrue);

    expect(
        (TestOptionalOptimizedForSize()..o = TestRequiredOptimizedForSize())
            .isInitialized(),
        isFalse);

    expect(
        (TestOptionalOptimizedForSize()
              ..o = (TestRequiredOptimizedForSize()..x = 5))
            .isInitialized(),
        isTrue);
  });

  test('testSetAllFieldsAndClone', () {
    var message = getAllSet();
    assertAllFieldsSet(message);
    assertAllFieldsSet(message.deepCopy());
  });

  test('testReadWholeMessage', () {
    var message = getAllSet();
    List<int> rawBytes = message.writeToBuffer();
    assertAllFieldsSet(TestAllTypes.fromBuffer(rawBytes));
  });

  test('testReadHugeBlob', () {
    // Allocate and initialize a 1MB blob.
    var blob = List<int>.generate(1 << 20, (i) => i % 256);

    // Make a message containing it.
    var message = getAllSet();
    message.optionalBytes = blob;

    var message2 = TestAllTypes.fromBuffer(message.writeToBuffer());
    expect(message2.optionalBytes, message.optionalBytes);
  });

  test('testRecursiveMessageDefaultInstance', () {
    var message = TestRecursiveMessage();
    expect(message.a, isNotNull);
    expect(message, message.a);
  });

  test('testMaliciousRecursion', () {
    TestRecursiveMessage _makeRecursiveMessage(int depth) {
      return depth == 0
          ? (TestRecursiveMessage()..i = 5)
          : (TestRecursiveMessage()..a = _makeRecursiveMessage(depth - 1));
    }

    void _assertMessageDepth(TestRecursiveMessage message, int depth) {
      if (depth == 0) {
        expect(message.hasA(), isFalse);
        expect(message.i, 5);
      } else {
        expect(message.hasA(), isTrue);
        _assertMessageDepth(message.a, depth - 1);
      }
    }

    List<int> data64 = _makeRecursiveMessage(64).writeToBuffer();
    List<int> data65 = _makeRecursiveMessage(65).writeToBuffer();

    _assertMessageDepth(TestRecursiveMessage.fromBuffer(data64), 64);

    expect(() {
      TestRecursiveMessage.fromBuffer(data65);
    }, throwsInvalidProtocolBufferException);

    var input = CodedBufferReader(data64, recursionLimit: 8);
    expect(() {
      // Uncomfortable alternative to below...
      TestRecursiveMessage().mergeFromCodedBufferReader(input);
    }, throwsInvalidProtocolBufferException);
  });

  test('testSizeLimit', () {
    var input = CodedBufferReader(getAllSet().writeToBuffer(), sizeLimit: 16);

    expect(() {
      // Uncomfortable alternative to below...
      TestAllTypes().mergeFromCodedBufferReader(input);
    }, throwsInvalidProtocolBufferException);
  });
  test('testSerialize', () {
    var expected = getAllSet();
    List<int> out = expected.writeToBuffer();
    var actual = TestAllTypes.fromBuffer(out);
    expect(actual, expected);
  });

  test('testEnumValues', () {
    expect(TestAllTypes_NestedEnum.values, [
      TestAllTypes_NestedEnum.FOO,
      TestAllTypes_NestedEnum.BAR,
      TestAllTypes_NestedEnum.BAZ
    ]);
    expect(TestAllTypes_NestedEnum.FOO.value, 1);
    expect(TestAllTypes_NestedEnum.BAR.value, 2);
    expect(TestAllTypes_NestedEnum.BAZ.value, 3);
  });

  test('testWriteWholeMessage', () {
    var goldenMessage = const <int>[
      // no `dart format`
      0x08, 0x65, 0x10, 0x66, 0x18, 0x67, 0x20, 0x68, 0x28, 0xd2, 0x01, 0x30,
      0xd4, 0x01, 0x3d, 0x6b, 0x00, 0x00, 0x00, 0x41, 0x6c, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x4d, 0x6d, 0x00, 0x00, 0x00, 0x51, 0x6e, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5d, 0x00, 0x00, 0xde, 0x42, 0x61,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5c, 0x40, 0x68, 0x01, 0x72, 0x03,
      0x31, 0x31, 0x35, 0x7a, 0x03, 0x31, 0x31, 0x36, 0x83, 0x01, 0x88, 0x01,
      0x75, 0x84, 0x01, 0x92, 0x01, 0x02, 0x08, 0x76, 0x9a, 0x01, 0x02, 0x08,
      0x77, 0xa2, 0x01, 0x02, 0x08, 0x78, 0xa8, 0x01, 0x03, 0xb0, 0x01, 0x06,
      0xb8, 0x01, 0x09, 0xc2, 0x01, 0x03, 0x31, 0x32, 0x34, 0xca, 0x01, 0x03,
      0x31, 0x32, 0x35, 0xf8, 0x01, 0xc9, 0x01, 0xf8, 0x01, 0xad, 0x02, 0x80,
      0x02, 0xca, 0x01, 0x80, 0x02, 0xae, 0x02, 0x88, 0x02, 0xcb, 0x01, 0x88,
      0x02, 0xaf, 0x02, 0x90, 0x02, 0xcc, 0x01, 0x90, 0x02, 0xb0, 0x02, 0x98,
      0x02, 0x9a, 0x03, 0x98, 0x02, 0xe2, 0x04, 0xa0, 0x02, 0x9c, 0x03, 0xa0,
      0x02, 0xe4, 0x04, 0xad, 0x02, 0xcf, 0x00, 0x00, 0x00, 0xad, 0x02, 0x33,
      0x01, 0x00, 0x00, 0xb1, 0x02, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0xb1, 0x02, 0x34, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbd,
      0x02, 0xd1, 0x00, 0x00, 0x00, 0xbd, 0x02, 0x35, 0x01, 0x00, 0x00, 0xc1,
      0x02, 0xd2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc1, 0x02, 0x36,
      0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcd, 0x02, 0x00, 0x00, 0x53,
      0x43, 0xcd, 0x02, 0x00, 0x80, 0x9b, 0x43, 0xd1, 0x02, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x80, 0x6a, 0x40, 0xd1, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x80, 0x73, 0x40, 0xd8, 0x02, 0x01, 0xd8, 0x02, 0x00, 0xe2, 0x02, 0x03,
      0x32, 0x31, 0x35, 0xe2, 0x02, 0x03, 0x33, 0x31, 0x35, 0xea, 0x02, 0x03,
      0x32, 0x31, 0x36, 0xea, 0x02, 0x03, 0x33, 0x31, 0x36, 0xf3, 0x02, 0xf8,
      0x02, 0xd9, 0x01, 0xf4, 0x02, 0xf3, 0x02, 0xf8, 0x02, 0xbd, 0x02, 0xf4,
      0x02, 0x82, 0x03, 0x03, 0x08, 0xda, 0x01, 0x82, 0x03, 0x03, 0x08, 0xbe,
      0x02, 0x8a, 0x03, 0x03, 0x08, 0xdb, 0x01, 0x8a, 0x03, 0x03, 0x08, 0xbf,
      0x02, 0x92, 0x03, 0x03, 0x08, 0xdc, 0x01, 0x92, 0x03, 0x03, 0x08, 0xc0,
      0x02, 0x98, 0x03, 0x02, 0x98, 0x03, 0x03, 0xa0, 0x03, 0x05, 0xa0, 0x03,
      0x06, 0xa8, 0x03, 0x08, 0xa8, 0x03, 0x09, 0xb2, 0x03, 0x03, 0x32, 0x32,
      0x34, 0xb2, 0x03, 0x03, 0x33, 0x32, 0x34, 0xba, 0x03, 0x03, 0x32, 0x32,
      0x35, 0xba, 0x03, 0x03, 0x33, 0x32, 0x35, 0xe8, 0x03, 0x91, 0x03, 0xf0,
      0x03, 0x92, 0x03, 0xf8, 0x03, 0x93, 0x03, 0x80, 0x04, 0x94, 0x03, 0x88,
      0x04, 0xaa, 0x06, 0x90, 0x04, 0xac, 0x06, 0x9d, 0x04, 0x97, 0x01, 0x00,
      0x00, 0xa1, 0x04, 0x98, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xad,
      0x04, 0x99, 0x01, 0x00, 0x00, 0xb1, 0x04, 0x9a, 0x01, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0xbd, 0x04, 0x00, 0x80, 0xcd, 0x43, 0xc1, 0x04, 0x00,
      0x00, 0x00, 0x00, 0x00, 0xc0, 0x79, 0x40, 0xc8, 0x04, 0x00, 0xd2, 0x04,
      0x03, 0x34, 0x31, 0x35, 0xda, 0x04, 0x03, 0x34, 0x31, 0x36, 0x88, 0x05,
      0x01, 0x90, 0x05, 0x04, 0x98, 0x05, 0x07, 0xa2, 0x05, 0x03, 0x34, 0x32,
      0x34, 0xaa, 0x05, 0x03, 0x34, 0x32, 0x35
    ];
    expect(getAllSet().writeToBuffer(), goldenMessage);
  });

  test('testWriteWholePackedFieldsMessage', () {
    var goldenPackedMessage = const <int>[
      // no `dart format`
      0xd2, 0x05, 0x04, 0xd9, 0x04, 0xbd, 0x05, 0xda, 0x05, 0x04, 0xda, 0x04,
      0xbe, 0x05, 0xe2, 0x05, 0x04, 0xdb, 0x04, 0xbf, 0x05, 0xea, 0x05, 0x04,
      0xdc, 0x04, 0xc0, 0x05, 0xf2, 0x05, 0x04, 0xba, 0x09, 0x82, 0x0b, 0xfa,
      0x05, 0x04, 0xbc, 0x09, 0x84, 0x0b, 0x82, 0x06, 0x08, 0x5f, 0x02, 0x00,
      0x00, 0xc3, 0x02, 0x00, 0x00, 0x8a, 0x06, 0x10, 0x60, 0x02, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0xc4, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x92, 0x06, 0x08, 0x61, 0x02, 0x00, 0x00, 0xc5, 0x02, 0x00, 0x00, 0x9a,
      0x06, 0x10, 0x62, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc6, 0x02,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa2, 0x06, 0x08, 0x00, 0xc0, 0x18,
      0x44, 0x00, 0xc0, 0x31, 0x44, 0xaa, 0x06, 0x10, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x20, 0x83, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x86, 0x40,
      0xb2, 0x06, 0x02, 0x01, 0x00, 0xba, 0x06, 0x02, 0x05, 0x06
    ];
    expect(getPackedSet().writeToBuffer(), goldenPackedMessage);
  });

  test('testWriteMessageWithNegativeEnumValue', () {
    var message = SparseEnumMessage()..sparseEnum = TestSparseEnum.SPARSE_E;
    expect(message.sparseEnum.value < 0, isTrue,
        reason: 'enum.value should be -53452');
    var message2 = SparseEnumMessage.fromBuffer(message.writeToBuffer());
    expect(message2.sparseEnum, TestSparseEnum.SPARSE_E,
        reason: 'should resolve back to SPARSE_E');
  });

  test('testReservedNamesOptional', () {
    var message = ReservedNamesOptional();
    message.hashCode_1 = 1;
    expect(message.hashCode_1, 1);
    expect(message.hasHashCode_1(), isTrue);
    message.clearHashCode_1();

    message.noSuchMethod_2 = 1;
    message.runtimeType_3 = 1;
    message.toString_4 = 1;
    message.fromBuffer_10 = 1;
    message.fromJson_11 = 1;
    message.hasRequiredFields_12 = 1;
    message.isInitialized_13 = 1;
    message.clear_14 = 1;
    message.getTagNumber_15 = 1;
    message.check_16 = 1;
    message.writeToBuffer_17 = 1;
    message.writeToCodedBufferWriter_18 = 1;
    message.mergeFromCodedBufferReader_19 = 1;
    message.mergeFromBuffer_20 = 1;
    message.writeToJson_21 = 1;
    message.mergeFromJson_22 = 1;
    message.addExtension_23 = 1;
    message.getExtension_24 = 1;
    message.setExtension_25 = 1;
    message.hasExtension_26 = 1;
    message.clearExtension_27 = 1;
    message.getField_28 = 1;
    message.setField_29 = 1;
    message.hasField_30 = 1;
    message.clearField_31 = 1;
    message.extensionsAreInitialized_32 = 1;
    message.mergeFromMessage_33 = 1;
    message.mergeUnknownFields_34 = 1;
    message.hashCode1 = 1;
    message.x = 1;
    message.hasX_51 = 1;
    message.clearX_53 = 1;
    message.hasX51 = 1;
    message.clearX53 = 1;
  });

  test('testReservedNamesRepeated', () {
    var message = ReservedNamesRepeated();
    message.hashCode_1.clear();
    message.noSuchMethod_2.clear();
    message.runtimeType_3.clear();
    message.toString_4.clear();
    message.fromBuffer_10.clear();
    message.fromJson_11.clear();
    message.hasRequiredFields_12.clear();
    message.isInitialized_13.clear();
    message.clear_14.clear();
    message.getTagNumber_15.clear();
    message.check_16.clear();
    message.writeToBuffer_17.clear();
    message.writeToCodedBufferWriter_18.clear();
    message.mergeFromCodedBufferReader_19.clear();
    message.mergeFromBuffer_20.clear();
    message.writeToJson_21.clear();
    message.mergeFromJson_22.clear();
    message.addExtension_23.clear();
    message.getExtension_24.clear();
    message.setExtension_25.clear();
    message.hasExtension_26.clear();
    message.clearExtension_27.clear();
    message.getField_28.clear();
    message.setField_29.clear();
    message.hasField_30.clear();
    message.clearField_31.clear();
    message.extensionsAreInitialized_32.clear();
    message.mergeFromMessage_33.clear();
    message.mergeUnknownFields_34.clear();
    message.hashCode1.clear();
    message.x.clear();
    message.hasX.clear();
    message.clearX.clear();
    message.hasX51.clear();
    message.clearX53.clear();
  });

  test('testReservedNamesRequired', () {
    var message = ReservedNamesRequired();
    message.hashCode_1 = 1;
    expect(message.hashCode_1, 1);
    expect(message.hasHashCode_1(), isTrue);
    message.clearHashCode_1();

    message.noSuchMethod_2 = 1;
    message.runtimeType_3 = 1;
    message.toString_4 = 1;
    message.fromBuffer_10 = 1;
    message.fromJson_11 = 1;
    message.hasRequiredFields_12 = 1;
    message.isInitialized_13 = 1;
    message.clear_14 = 1;
    message.getTagNumber_15 = 1;
    message.check_16 = 1;
    message.writeToBuffer_17 = 1;
    message.writeToCodedBufferWriter_18 = 1;
    message.mergeFromCodedBufferReader_19 = 1;
    message.mergeFromBuffer_20 = 1;
    message.writeToJson_21 = 1;
    message.mergeFromJson_22 = 1;
    message.addExtension_23 = 1;
    message.getExtension_24 = 1;
    message.setExtension_25 = 1;
    message.hasExtension_26 = 1;
    message.clearExtension_27 = 1;
    message.getField_28 = 1;
    message.setField_29 = 1;
    message.hasField_30 = 1;
    message.clearField_31 = 1;
    message.extensionsAreInitialized_32 = 1;
    message.mergeFromMessage_33 = 1;
    message.mergeUnknownFields_34 = 1;
    message.hashCode1 = 1;
    message.x = 1;
    message.hasX_51 = 1;
    message.clearX_53 = 1;
    message.hasX51 = 1;
    message.clearX53 = 1;
  });

  test('testReservedWordsOptional', () {
    var message = ReservedWordsOptional();
    message.assert_1 = 1;
    message.break_2 = 1;
    message.case_3 = 1;
    message.catch_4 = 1;
    message.class_5 = 1;
    message.const_6 = 1;
    message.continue_7 = 1;
    message.default_8 = 1;
    message.do_9 = 1;
    message.else_10 = 1;
    message.enum_11 = 1;
    message.extends_12 = 1;
    message.false_13 = 1;
    message.final_14 = 1;
    message.finally_15 = 1;
    message.for_16 = 1;
    message.if_17 = 1;
    message.in_18 = 1;
    message.is_19 = 1;
    message.new_20 = 1;
    message.null_21 = 1;
    message.rethrow_22 = 1;
    message.return_23 = 1;
    message.super_24 = 1;
    message.switch_25 = 1;
    message.this_26 = 1;
    message.throw_27 = 1;
    message.true_28 = 1;
    message.try_29 = 1;
    message.var_30 = 1;
    message.void_31 = 1;
    message.while_32 = 1;
    message.with_33 = 1;
  });

  test('testReservedWordsRepeated', () {
    var message = ReservedWordsRepeated();
    message.assert_1.clear();
    message.break_2.clear();
    message.case_3.clear();
    message.catch_4.clear();
    message.class_5.clear();
    message.const_6.clear();
    message.continue_7.clear();
    message.default_8.clear();
    message.do_9.clear();
    message.else_10.clear();
    message.enum_11.clear();
    message.extends_12.clear();
    message.false_13.clear();
    message.final_14.clear();
    message.finally_15.clear();
    message.for_16.clear();
    message.if_17.clear();
    message.in_18.clear();
    message.is_19.clear();
    message.new_20.clear();
    message.null_21.clear();
    message.rethrow_22.clear();
    message.return_23.clear();
    message.super_24.clear();
    message.switch_25.clear();
    message.this_26.clear();
    message.throw_27.clear();
    message.true_28.clear();
    message.try_29.clear();
    message.var_30.clear();
    message.void_31.clear();
    message.while_32.clear();
    message.with_33.clear();
  });

  test('testReservedWordsRequired', () {
    var message = ReservedWordsRequired();
    message.assert_1 = 1;
    message.break_2 = 1;
    message.case_3 = 1;
    message.catch_4 = 1;
    message.class_5 = 1;
    message.const_6 = 1;
    message.continue_7 = 1;
    message.default_8 = 1;
    message.do_9 = 1;
    message.else_10 = 1;
    message.enum_11 = 1;
    message.extends_12 = 1;
    message.false_13 = 1;
    message.final_14 = 1;
    message.finally_15 = 1;
    message.for_16 = 1;
    message.if_17 = 1;
    message.in_18 = 1;
    message.is_19 = 1;
    message.new_20 = 1;
    message.null_21 = 1;
    message.rethrow_22 = 1;
    message.return_23 = 1;
    message.super_24 = 1;
    message.switch_25 = 1;
    message.this_26 = 1;
    message.throw_27 = 1;
    message.true_28 = 1;
    message.try_29 = 1;
    message.var_30 = 1;
    message.void_31 = 1;
    message.while_32 = 1;
    message.with_33 = 1;
  });

  test('testReservedWordsRequired', () {
    var message = MessageWithReservedEnum();
    message.enum_1 = ReservedEnum.assert_;
    message.enum_1 = ReservedEnum.break_;
    message.enum_1 = ReservedEnum.case_;
    message.enum_1 = ReservedEnum.catch_;
    message.enum_1 = ReservedEnum.class_;
    message.enum_1 = ReservedEnum.const_;
    message.enum_1 = ReservedEnum.continue_;
    message.enum_1 = ReservedEnum.default_;
    message.enum_1 = ReservedEnum.do_;
    message.enum_1 = ReservedEnum.else_;
    message.enum_1 = ReservedEnum.enum_;
    message.enum_1 = ReservedEnum.extends_;
    message.enum_1 = ReservedEnum.false_;
    message.enum_1 = ReservedEnum.final_;
    message.enum_1 = ReservedEnum.finally_;
    message.enum_1 = ReservedEnum.for_;
    message.enum_1 = ReservedEnum.if_;
    message.enum_1 = ReservedEnum.in_;
    message.enum_1 = ReservedEnum.is_;
    message.enum_1 = ReservedEnum.new_;
    message.enum_1 = ReservedEnum.null_;
    message.enum_1 = ReservedEnum.rethrow_;
    message.enum_1 = ReservedEnum.return_;
    message.enum_1 = ReservedEnum.super_;
    message.enum_1 = ReservedEnum.switch_;
    message.enum_1 = ReservedEnum.this_;
    message.enum_1 = ReservedEnum.throw_;
    message.enum_1 = ReservedEnum.true_;
    message.enum_1 = ReservedEnum.try_;
    message.enum_1 = ReservedEnum.var_;
    message.enum_1 = ReservedEnum.void_;
    message.enum_1 = ReservedEnum.while_;
    message.enum_1 = ReservedEnum.with_;
  });

  test('testReservedWordsExtension', () {
    var message = ExtendMe();
    message.setExtension(Reserved_names_extension.assert_1001, 1);
    message.setExtension(Reserved_names_extension.break_1002, 1);
    message.setExtension(Reserved_names_extension.case_1003, 1);
    message.setExtension(Reserved_names_extension.catch_1004, 1);
    message.setExtension(Reserved_names_extension.class_1005, 1);
    message.setExtension(Reserved_names_extension.const_1006, 1);
    message.setExtension(Reserved_names_extension.continue_1007, 1);
    message.setExtension(Reserved_names_extension.default_1008, 1);
    message.setExtension(Reserved_names_extension.do_1009, 1);
    message.setExtension(Reserved_names_extension.else_1010, 1);
    message.setExtension(Reserved_names_extension.enum_1011, 1);
    message.setExtension(Reserved_names_extension.extends_1012, 1);
    message.setExtension(Reserved_names_extension.false_1013, 1);
    message.setExtension(Reserved_names_extension.final_1014, 1);
    message.setExtension(Reserved_names_extension.finally_1015, 1);
    message.setExtension(Reserved_names_extension.for_1016, 1);
    message.setExtension(Reserved_names_extension.if_1017, 1);
    message.setExtension(Reserved_names_extension.in_1018, 1);
    message.setExtension(Reserved_names_extension.is_1019, 1);
    message.setExtension(Reserved_names_extension.new_1020, 1);
    message.setExtension(Reserved_names_extension.null_1021, 1);
    message.setExtension(Reserved_names_extension.rethrow_1022, 1);
    message.setExtension(Reserved_names_extension.return_1023, 1);
    message.setExtension(Reserved_names_extension.super_1024, 1);
    message.setExtension(Reserved_names_extension.switch_1025, 1);
    message.setExtension(Reserved_names_extension.this_1026, 1);
    message.setExtension(Reserved_names_extension.throw_1027, 1);
    message.setExtension(Reserved_names_extension.true_1028, 1);
    message.setExtension(Reserved_names_extension.try_1029, 1);
    message.setExtension(Reserved_names_extension.var_1030, 1);
    message.setExtension(Reserved_names_extension.void_1031, 1);
    message.setExtension(Reserved_names_extension.while_1032, 1);
    message.setExtension(Reserved_names_extension.with_1033, 1);
  });

  test('testReservedWordsMessage', () {
    assert_();
    break_();
    case_();
    catch_();
    class_();
    const_();
    continue_();
    default_();
    do_();
    else_();
    enum_();
    extends_();
    false_();
    final_();
    finally_();
    for_();
    if_();
    in_();
    is_();
    new_();
    null_();
    rethrow_();
    return_();
    super_();
    switch_();
    this_();
    throw_();
    true_();
    try_();
    var_();
    void_();
    while_();
    with_();
  });

  test('testImportDuplicatenames', () {
    var message = M();
    message.m1 = p1.M();
    message.m1M = p1.M_M();
    message.m2 = p2.M();
    message.m2M = p2.M_M();
    message.m3 = p3.M();
    message.m3M = p3.M_M();
  });

  test('testToplevel', () {
    var message = t.M();
    message.t = T();
    t.SApi(null);
  });

  test('to toDebugString', () {
    var value1 = TestAllTypes()..optionalString = 'test 123';
    expect(value1.toString(), 'optionalString: test 123\n');
  });

  test('operator== and hashCode works for bytes', () {
    final t1 = TestAllTypes()..optionalBytes = [1];
    final t2 = TestAllTypes()..optionalBytes = [1];
    final t3 = TestAllTypes.fromBuffer(t1.writeToBuffer());
    expect(t1, equals(t2));
    expect(t1.hashCode, equals(t2.hashCode));
    expect(t1, equals(t3));
    expect(t1.hashCode, equals(t3.hashCode));
  });

  test('rebuild updates value', () {
    final value1 = TestAllTypes()
      ..optionalForeignMessage = (ForeignMessage()..c = 18)
      ..freeze();
    final value2 = value1.rebuild((v) {
      v.optionalFloat = 50.1;
      v.optionalForeignMessage =
          v.optionalForeignMessage.rebuild((o) => o.c = 10);
    });
    expect(value2.isFrozen, true);
    expect(value2.optionalFloat, 50.1);
    expect(value2.optionalForeignMessage.isFrozen, true);
  });

  test('rebuild requires a frozen message', () {
    final value = TestAllTypes();
    expect(() => value.rebuild((x) {}), throwsArgumentError);
  });

  test('rebuild shares structure', () {
    final value1 = TestAllTypes()
      ..optionalForeignMessage = (ForeignMessage()..c = 18)
      ..freeze();
    final value2 = value1.rebuild((v) {
      v.optionalFloat = 50.1;
    });
    expect(value2.isFrozen, true);
    expect(value2.optionalFloat, 50.1);
    expect(value1.optionalForeignMessage.isFrozen, true);
    expect(value1.optionalForeignMessage, same(value2.optionalForeignMessage));
  });

  test('deepCopy', () {
    final value1 = getAllSet();
    // TODO(sigurdm): Use the implicit syntax after resolution of https://github.com/dart-lang/sdk/issues/39160
    final value2 = value1.deepCopy();
    assertAllFieldsSet(value2);
    expect(value2, isNot(same(value1)));
    expect(value2.optionalForeignMessage,
        isNot(same(value1.optionalForeignMessage)));
  });

  test('deepCopy extensions', () {
    final value1 = TestAllExtensions();
    setAllExtensions(value1);
    final value2 = value1.deepCopy();
    assertAllExtensionsSet(value2);
  });

  test('named arguments in constructor', () {
    final value = TestAllTypes(
      optionalInt32: 101,
      optionalInt64: make64(102),
      optionalUint32: 103,
      optionalUint64: make64(104),
      optionalSint32: 105,
      optionalSint64: make64(106),
      optionalFixed32: 107,
      optionalFixed64: make64(108),
      optionalSfixed32: 109,
      optionalSfixed64: make64(110),
      optionalFloat: 111.0,
      optionalDouble: 112.0,
      optionalBool: true,
      optionalString: '115',
      optionalBytes: '116'.codeUnits,
      optionalGroup: TestAllTypes_OptionalGroup(a: 117),
      optionalNestedMessage: TestAllTypes_NestedMessage(bb: 118),
      optionalForeignMessage: ForeignMessage(c: 119),
      optionalImportMessage: ImportMessage(d: 120),
      optionalNestedEnum: TestAllTypes_NestedEnum.BAZ,
      optionalForeignEnum: ForeignEnum.FOREIGN_BAZ,
      optionalImportEnum: ImportEnum.IMPORT_BAZ,
      optionalStringPiece: '124',
      optionalCord: '125',
      repeatedInt32: [201, 301],
      repeatedInt64: [make64(202), make64(302)],
      repeatedUint32: [203, 303],
      repeatedUint64: [make64(204), make64(304)],
      repeatedSint32: [205, 305],
      repeatedSint64: [make64(206), make64(306)],
      repeatedFixed32: [207, 307],
      repeatedFixed64: [make64(208), make64(308)],
      repeatedSfixed32: [209, 309],
      repeatedSfixed64: [make64(210), make64(310)],
      repeatedFloat: [211.0, 311.0],
      repeatedDouble: [212.0, 312.0],
      repeatedBool: [true, false],
      repeatedString: ['215', '315'],
      repeatedBytes: ['216'.codeUnits, '316'.codeUnits],
      repeatedGroup: [
        TestAllTypes_RepeatedGroup(a: 217),
        TestAllTypes_RepeatedGroup(a: 317)
      ],
      repeatedNestedMessage: [
        TestAllTypes_NestedMessage(bb: 218),
        TestAllTypes_NestedMessage(bb: 318)
      ],
      repeatedForeignMessage: [ForeignMessage(c: 219), ForeignMessage(c: 319)],
      repeatedImportMessage: [ImportMessage(d: 220), ImportMessage(d: 320)],
      repeatedNestedEnum: [
        TestAllTypes_NestedEnum.BAR,
        TestAllTypes_NestedEnum.BAZ
      ],
      repeatedForeignEnum: [ForeignEnum.FOREIGN_BAR, ForeignEnum.FOREIGN_BAZ],
      repeatedImportEnum: [ImportEnum.IMPORT_BAR, ImportEnum.IMPORT_BAZ],
      repeatedStringPiece: ['224', '324'],
      repeatedCord: ['225', '325'],
      defaultInt32: 401,
      defaultInt64: make64(402),
      defaultUint32: 403,
      defaultUint64: make64(404),
      defaultSint32: 405,
      defaultSint64: make64(406),
      defaultFixed32: 407,
      defaultFixed64: make64(408),
      defaultSfixed32: 409,
      defaultSfixed64: make64(410),
      defaultFloat: 411.0,
      defaultDouble: 412.0,
      defaultBool: false,
      defaultString: '415',
      defaultBytes: '416'.codeUnits,
      defaultNestedEnum: TestAllTypes_NestedEnum.FOO,
      defaultForeignEnum: ForeignEnum.FOREIGN_FOO,
      defaultImportEnum: ImportEnum.IMPORT_FOO,
      defaultStringPiece: '424',
      defaultCord: '425',
    );

    assertAllFieldsSet(value);
  });
}
