#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import '../out/protos/google/protobuf/unittest.pb.dart';
import 'test_util.dart';

void main() {
  var testAllTypes = getAllSet();
  List<int> allFieldsData = testAllTypes.writeToBuffer();
  var emptyMessage = TestEmptyMessage.fromBuffer(allFieldsData);
  var unknownFields = emptyMessage.unknownFields;

  UnknownFieldSetField getField(String name) {
    var tagNumber = testAllTypes.getTagNumber(name)!;
    assert(unknownFields.hasField(tagNumber));
    return unknownFields.getField(tagNumber)!;
  }

  // Asserts that the given field sets are not equal and have different
  // hash codes.
  //
  // N.B.: It is valid for non-equal objects to have the same hash code, so
  // this test is more strict than necessary. However, in the test cases
  // identifies, the hash codes should differ, and as a matter of principle
  // hash collisions should be relatively rare.
  void _checkNotEqual(UnknownFieldSet s1, UnknownFieldSet s2) {
    expect(s1 == s2, isFalse);
    expect(s2 == s1, isFalse);

    expect(s1.hashCode == s2.hashCode, isFalse,
        reason: '${s1.toString()} should have a different hash code '
            'from ${s2.toString()}');
  }

  // Asserts that the given field sets are equal and have identical hash codes.
  void _checkEqualsIsConsistent(UnknownFieldSet set) {
    // Object should be equal to itself.
    expect(set, set);

    // Object should be equal to a copy of itself.
    var copy = set.clone();
    expect(copy, set);
    expect(set, copy);
  }

  test('testVarint', () {
    var optionalInt32 = getField('optionalInt32');
    expect(optionalInt32.varints[0], expect64(testAllTypes.optionalInt32));
  });

  test('testFixed32', () {
    var optionalFixed32 = getField('optionalFixed32');
    expect(optionalFixed32.fixed32s[0], testAllTypes.optionalFixed32);
  });

  test('testFixed64', () {
    var optionalFixed64 = getField('optionalFixed64');
    expect(optionalFixed64.fixed64s[0], testAllTypes.optionalFixed64);
  });

  test('testLengthDelimited', () {
    var optionalBytes = getField('optionalBytes');
    expect(optionalBytes.lengthDelimited[0], testAllTypes.optionalBytes);
  });

  test('testGroup', () {
    var tagNumberA = TestAllTypes_OptionalGroup().getTagNumber('a')!;

    var optionalGroupField = getField('optionalgroup');
    expect(optionalGroupField.groups.length, 1);
    var group = optionalGroupField.groups[0];
    expect(group.hasField(tagNumberA), isTrue);
    expect(group.getField(tagNumberA)!.varints[0],
        expect64(testAllTypes.optionalGroup.a));
  });

  test('testSerialize', () {
    expect(emptyMessage.writeToBuffer(), allFieldsData);
  });

  test('testCopyFrom', () {
    var message = emptyMessage.deepCopy();
    expect(message.toString(), emptyMessage.toString());
    expect(emptyMessage.toString().isEmpty, isFalse);
  });

  test('testMergeFrom', () {
    // Source.
    var sourceFieldSet = UnknownFieldSet()
      ..addField(2, UnknownFieldSetField()..addVarint(make64(2)))
      ..addField(3, UnknownFieldSetField()..addVarint(make64(3)));

    var source = TestEmptyMessage()..mergeUnknownFields(sourceFieldSet);

    // Destination.
    var destinationFieldSet = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addVarint(make64(1)))
      ..addField(3, UnknownFieldSetField()..addVarint(make64(4)));

    var destination = TestEmptyMessage()
      ..mergeUnknownFields(destinationFieldSet)
      ..mergeFromMessage(source);

    expect(
        destination.toString(),
        '1: 1\n'
        '2: 2\n'
        '3: 4\n'
        '3: 3\n');
  });

  test('testClear', () {
    var fsb = unknownFields.clone()..clear();
    expect(fsb.asMap(), isEmpty);
  });

  test('testEmpty', () {
    expect(UnknownFieldSet().asMap(), isEmpty);
  });

  test('testClearMessage', () {
    var message = emptyMessage.deepCopy();
    message.clear();
    expect(message.writeToBuffer(), isEmpty);
  });

  test('testParseKnownAndUnknown', () {
    // Test mixing known and unknown fields when parsing.
    var fields = unknownFields.clone()
      ..addField(123456, UnknownFieldSetField()..addVarint(make64(654321)));

    var writer = CodedBufferWriter();
    fields.writeToCodedBufferWriter(writer);

    var destination = TestAllTypes.fromBuffer(writer.toBuffer());

    assertAllFieldsSet(destination);
    expect(destination.unknownFields.asMap().length, 1);

    var field = destination.unknownFields.getField(123456)!;
    expect(field.varints.length, 1);
    expect(field.varints[0], expect64(654321));
  });

  // Constructs a protocol buffer which contains fields with all the same
  // numbers as allFieldsData except that each field is some other wire
  // type.
  List<int> getBizarroData() {
    var bizarroFields = UnknownFieldSet();

    var varintField = UnknownFieldSetField()..addVarint(make64(1));

    var fixed32Field = UnknownFieldSetField()..addFixed32(1);

    unknownFields.asMap().forEach((int tag, UnknownFieldSetField value) {
      if (value.varints.isEmpty) {
        // Original field is not a varint, so use a varint.
        bizarroFields.addField(tag, varintField);
      } else {
        // Original field *is* a varint, so use something else.
        bizarroFields.addField(tag, fixed32Field);
      }
    });
    var writer = CodedBufferWriter();
    bizarroFields.writeToCodedBufferWriter(writer);
    return writer.toBuffer();
  }

  test('testWrongTypeTreatedAsUnknown', () {
    // Test that fields of the wrong wire type are treated like unknown fields
    // when parsing.
    var bizarroData = getBizarroData();
    var allTypesMessage = TestAllTypes.fromBuffer(bizarroData);
    var emptyMessage_ = TestEmptyMessage.fromBuffer(bizarroData);
    // All fields should have been interpreted as unknown, so the debug strings
    // should be the same.
    expect(allTypesMessage.toString(), emptyMessage_.toString());
  });

  test('testUnknownExtensions', () {
    // Make sure fields are properly parsed to the UnknownFieldSet even when
    // they are declared as extension numbers.
    var message = TestEmptyMessageWithExtensions.fromBuffer(allFieldsData);

    expect(message.unknownFields.asMap().length, unknownFields.asMap().length);
    expect(message.writeToBuffer(), allFieldsData);
  });

  test('testWrongExtensionTypeTreatedAsUnknown', () {
    // Test that fields of the wrong wire type are treated like unknown fields
    // when parsing extensions.

    var bizarroData = getBizarroData();
    var allExtensionsMessage = TestAllExtensions.fromBuffer(bizarroData);
    var emptyMessage_ = TestEmptyMessage.fromBuffer(bizarroData);

    // All fields should have been interpreted as unknown, so the debug strings
    // should be the same.
    expect(allExtensionsMessage.toString(), emptyMessage_.toString());
  });

  test('testParseUnknownEnumValue', () {
    var singularFieldNum = testAllTypes.getTagNumber('optionalNestedEnum')!;
    var repeatedFieldNum = testAllTypes.getTagNumber('repeatedNestedEnum')!;

    var fieldSet = UnknownFieldSet()
      ..addField(
          singularFieldNum,
          UnknownFieldSetField()
            ..addVarint(make64(TestAllTypes_NestedEnum.BAR.value))
            ..addVarint(make64(5)))
      ..addField(
          repeatedFieldNum,
          UnknownFieldSetField()
            ..addVarint(make64(TestAllTypes_NestedEnum.FOO.value))
            ..addVarint(make64(4))
            ..addVarint(make64(TestAllTypes_NestedEnum.BAZ.value))
            ..addVarint(make64(6)));

    var writer = CodedBufferWriter();
    fieldSet.writeToCodedBufferWriter(writer);
    {
      var message = TestAllTypes.fromBuffer(writer.toBuffer());
      expect(message.optionalNestedEnum, TestAllTypes_NestedEnum.BAR);
      expect(message.repeatedNestedEnum,
          [TestAllTypes_NestedEnum.FOO, TestAllTypes_NestedEnum.BAZ]);
      final singularVarints =
          message.unknownFields.getField(singularFieldNum)!.varints;
      expect(singularVarints.length, 1);
      expect(singularVarints[0], expect64(5));
      final repeatedVarints =
          message.unknownFields.getField(repeatedFieldNum)!.varints;
      expect(repeatedVarints.length, 2);
      expect(repeatedVarints[0], expect64(4));
      expect(repeatedVarints[1], expect64(6));
    }
    {
      var message = TestAllExtensions.fromBuffer(
          writer.toBuffer(), getExtensionRegistry());
      expect(message.getExtension(Unittest.optionalNestedEnumExtension),
          TestAllTypes_NestedEnum.BAR);

      expect(message.getExtension(Unittest.repeatedNestedEnumExtension),
          [TestAllTypes_NestedEnum.FOO, TestAllTypes_NestedEnum.BAZ]);
      final singularVarints =
          message.unknownFields.getField(singularFieldNum)!.varints;
      expect(singularVarints.length, 1);
      expect(singularVarints[0], expect64(5));
      final repeatedVarints =
          message.unknownFields.getField(repeatedFieldNum)!.varints;
      expect(repeatedVarints.length, 2);
      expect(repeatedVarints[0], expect64(4));
      expect(repeatedVarints[1], expect64(6));
    }
  });

  test('testLargeVarint', () {
    var unknownFieldSet = UnknownFieldSet()
      ..addField(
          1, UnknownFieldSetField()..addVarint(make64(0x7FFFFFFF, 0xFFFFFFFF)));
    var writer = CodedBufferWriter();
    unknownFieldSet.writeToCodedBufferWriter(writer);

    var parsed = UnknownFieldSet()
      ..mergeFromCodedBufferReader(CodedBufferReader(writer.toBuffer()));
    var field = parsed.getField(1)!;
    expect(field.varints.length, 1);
    expect(field.varints[0], expect64(0x7FFFFFFF, 0xFFFFFFFFF));
  });

  test('testEquals', () {
    var a = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addFixed32(1));

    var b = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addFixed64(make64(1)));

    var c = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addVarint(make64(1)));

    var d = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addLengthDelimited([]));

    var e = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addGroup(unknownFields));

    _checkEqualsIsConsistent(a);
    _checkEqualsIsConsistent(b);
    _checkEqualsIsConsistent(c);
    _checkEqualsIsConsistent(d);
    _checkEqualsIsConsistent(e);

    _checkNotEqual(a, b);
    _checkNotEqual(a, c);
    _checkNotEqual(a, d);
    _checkNotEqual(a, e);
    _checkNotEqual(b, c);
    _checkNotEqual(b, d);
    _checkNotEqual(b, e);
    _checkNotEqual(c, d);
    _checkNotEqual(c, e);
    _checkNotEqual(d, e);

    var f1 = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addLengthDelimited([1, 2]));
    var f2 = UnknownFieldSet()
      ..addField(1, UnknownFieldSetField()..addLengthDelimited([2, 1]));

    _checkEqualsIsConsistent(f1);
    _checkEqualsIsConsistent(f2);

    _checkNotEqual(f1, f2);
  });

  test(
      'consistent hashcode for messages with no unknown fields set and an empty unknown field set',
      () {
    final m = TestAllExtensions();
    // Force an unknown field set.
    final m2 = TestAllExtensions()..unknownFields;
    expect(m.hashCode, m2.hashCode);
  });
}
