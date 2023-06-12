import 'package:archive/archive.dart';
import 'package:test/test.dart';

void main() {
  test('empty', () {
    final out = OutputStream();
    final bytes = out.getBytes();
    expect(bytes.length, equals(0));
  });

  test('writeByte', () {
    final out = OutputStream();
    for (var i = 0; i < 10000; ++i) {
      out.writeByte(i % 256);
    }
    final bytes = out.getBytes();
    expect(bytes.length, equals(10000));
    for (var i = 0; i < 10000; ++i) {
      expect(bytes[i], equals(i % 256));
    }
  });

  test('writeUint16', () {
    final out = OutputStream();

    const len = 0xffff;
    for (var i = 0; i < len; ++i) {
      out.writeUint16(i);
    }

    final bytes = out.getBytes();
    expect(bytes.length, equals(len * 2));

    final input = InputStream(bytes);
    for (var i = 0; i < len; ++i) {
      final x = input.readUint16();
      expect(x, equals(i));
    }
  });

  test('writeUint32', () {
    final out = OutputStream();

    const len = 0xffff;
    for (var i = 0; i < len; ++i) {
      out.writeUint32(0xffff + i);
    }

    var bytes = out.getBytes();
    expect(bytes.length, equals(len * 4));

    final input = InputStream(bytes);
    for (var i = 0; i < len; ++i) {
      final x = input.readUint32();
      expect(x, equals(0xffff + i));
    }
  });
}
