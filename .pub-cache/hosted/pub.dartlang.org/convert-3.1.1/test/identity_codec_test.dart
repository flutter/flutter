import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityCodec', () {
    test('encode', () {
      const codec = IdentityCodec<String>();
      expect(codec.encode('hello-world'), equals('hello-world'));
    });

    test('decode', () {
      const codec = IdentityCodec<String>();
      expect(codec.decode('hello-world'), equals('hello-world'));
    });

    test('fuse', () {
      const stringCodec = IdentityCodec<String>();
      final utf8Strings = stringCodec.fuse(utf8);
      expect(utf8Strings, equals(utf8));
    });
  });
}
