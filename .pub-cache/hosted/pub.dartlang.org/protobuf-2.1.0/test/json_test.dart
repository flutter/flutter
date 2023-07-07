// Basic smoke tests for the GeneratedMessage JSON API.
//
// There are more JSON tests in the dart-protoc-plugin package.
library json_test;

import 'dart:convert';

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:test/test.dart';

import 'mock_util.dart' show T, mockEnumValues;

void main() {
  var example = T()
    ..val = 123
    ..str = 'hello'
    ..int32s.addAll(<int>[1, 2, 3]);

  test('testProto3JsonEnum', () {
    // No enum value specified.
    expect(example.hasEnm, isFalse);
    // Defaults to first when it doesn't exist.
    expect(example.enm, equals(mockEnumValues.first));
    expect((example..mergeFromProto3Json({'enm': 'a'})).enm.name, equals('a'));
    // Now it's explicitly set after merging.
    expect(example.hasEnm, isTrue);

    expect((example..mergeFromProto3Json({'enm': 'b'})).enm.name, equals('b'));
    // "c" is not a legal enum value.
    expect(
        () => example..mergeFromProto3Json({'enm': 'c'}),
        throwsA(allOf(
            isFormatException,
            predicate(
                (dynamic e) => e.message.contains('Unknown enum value')))));
    // `example` hasn't changed.
    expect(example.hasEnm, isTrue);
    expect(example.enm.name, equals('b'));

    // "c" is not a legal enum value, but we are ignoring unknown fields, so
    // default behavior is to unset `enm`, returning the default value "a"
    expect(
        (example..mergeFromProto3Json({'enm': 'c'}, ignoreUnknownFields: true))
            .enm
            .name,
        equals('a'));
    expect(example.hasEnm, isFalse);

    // Same for index values...
    expect((example..mergeFromProto3Json({'enm': 2})).enm.name, 'b');
    expect(
        () => example..mergeFromProto3Json({'enm': 3}),
        throwsA(allOf(
            isFormatException,
            predicate(
                (dynamic e) => e.message.contains('Unknown enum value')))));
    // `example` hasn't changed.
    expect(example.hasEnm, isTrue);
    expect(example.enm.name, equals('b'));

    // "c" is not a legal enum value, but we are ignoring unknown fields, so
    // default behavior is to unset `enm`, returning the default value "a"
    expect(
        (example..mergeFromProto3Json({'enm': 3}, ignoreUnknownFields: true))
            .enm
            .name,
        equals('a'));
    expect(example.hasEnm, isFalse);
  });

  test('testWriteToJson', () {
    var json = example.writeToJson();
    checkJsonMap(jsonDecode(json));
  });

  test('testWriteFrozenToJson', () {
    final frozen = example.clone()..freeze();
    final json = frozen.writeToJson();
    checkJsonMap(jsonDecode(json));
  });

  test('writeToJsonMap', () {
    Map m = example.writeToJsonMap();
    checkJsonMap(m);
  });

  test('testMergeFromJson', () {
    var t = T();
    t.mergeFromJson('''{"1": 123, "2": "hello"}''');
    checkMessage(t);
  });

  test('testMergeFromJsonMap', () {
    var t = T();
    t.mergeFromJsonMap({'1': 123, '2': 'hello'});
    checkMessage(t);
  });

  test('testInt64JsonEncoding', () {
    final value = Int64.parseInt('1234567890123456789');
    final t = T()..int64 = value;
    final encoded = t.writeToJsonMap();
    expect(encoded['5'], '$value');
    final decoded = T()..mergeFromJsonMap(encoded);
    expect(decoded.int64, value);
  });

  test('testFrozentInt64JsonEncoding', () {
    final value = Int64.parseInt('1234567890123456789');
    final frozen = T()
      ..int64 = value
      ..freeze();
    final encoded = frozen.writeToJsonMap();
    expect(encoded['5'], '$value');
    final decoded = T()..mergeFromJsonMap(encoded);
    expect(decoded.int64, value);
  });
}

void checkJsonMap(Map m) {
  expect(m.length, 3);
  expect(m['1'], 123);
  expect(m['2'], 'hello');
  expect(m['4'], [1, 2, 3]);
}

void checkMessage(T t) {
  expect(t.val, 123);
  expect(t.str, 'hello');
}
