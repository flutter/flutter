import 'package:archive/archive.dart';
import 'package:test/test.dart';

void main() {
  test('empty', () {
    final input = InputStream(<int>[]);
    expect(input.length, equals(0));
    expect(input.isEOS, equals(true));
  });

  test('readByte', () {
    const data = <int>[0xaa, 0xbb, 0xcc];
    final input = InputStream(data);
    expect(input.length, equals(3));
    expect(input.readByte(), equals(0xaa));
    expect(input.readByte(), equals(0xbb));
    expect(input.readByte(), equals(0xcc));
    expect(input.isEOS, equals(true));
  });

  test('peakBytes', () {
    const data = <int>[0xaa, 0xbb, 0xcc];

    final input = InputStream(data);
    expect(input.readByte(), equals(0xaa));

    final bytes = input.peekBytes(2).toUint8List();
    expect(bytes[0], equals(0xbb));
    expect(bytes[1], equals(0xcc));
    expect(input.readByte(), equals(0xbb));
    expect(input.readByte(), equals(0xcc));
    expect(input.isEOS, equals(true));
  });

  test('skip', () {
    const data = <int>[0xaa, 0xbb, 0xcc];
    final input = InputStream(data);
    expect(input.length, equals(3));
    expect(input.readByte(), equals(0xaa));
    input.skip(1);
    expect(input.readByte(), equals(0xcc));
    expect(input.isEOS, equals(true));
  });

  test('subset', () {
    const data = <int>[0xaa, 0xbb, 0xcc, 0xdd, 0xee];
    final input = InputStream(data);
    expect(input.length, equals(5));
    expect(input.readByte(), equals(0xaa));

    final i2 = input.subset(null, 3);

    final i3 = i2.subset(1, 2);

    expect(i2.readByte(), equals(0xbb));
    expect(i2.readByte(), equals(0xcc));
    expect(i2.readByte(), equals(0xdd));
    expect(i2.isEOS, equals(true));

    expect(i3.readByte(), equals(0xcc));
    expect(i3.readByte(), equals(0xdd));
  });

  test('readString', () {
    const data = [84, 101, 115, 116, 0];
    final input = InputStream(data);
    var s = input.readString();
    expect(s, equals('Test'));
    expect(input.isEOS, equals(true));

    input.reset();

    s = input.readString(size: 4);
    expect(s, equals('Test'));
    expect(input.readByte(), equals(0));
    expect(input.isEOS, equals(true));
  });

  test('readBytes', () {
    const data = [84, 101, 115, 116, 0];
    final input = InputStream(data);
    final b = input.readBytes(3).toUint8List();
    expect(b.length, equals(3));
    expect(b[0], equals(84));
    expect(b[1], equals(101));
    expect(b[2], equals(115));
    expect(input.readByte(), equals(116));
    expect(input.readByte(), equals(0));
    expect(input.isEOS, equals(true));
  });

  test('readUint16', () {
    const data = [0xaa, 0xbb, 0xcc, 0xdd, 0xee];
    // Little endian (by default)
    final input = InputStream(data);
    expect(input.readUint16(), equals(0xbbaa));

    // Big endian
    final i2 = InputStream(data, byteOrder: BIG_ENDIAN);
    expect(i2.readUint16(), equals(0xaabb));
  });

  test('readUint24', () {
    const data = [0xaa, 0xbb, 0xcc, 0xdd, 0xee];
    // Little endian (by default)
    final input = InputStream(data);
    expect(input.readUint24(), equals(0xccbbaa));

    // Big endian
    final i2 = InputStream(data, byteOrder: BIG_ENDIAN);
    expect(i2.readUint24(), equals(0xaabbcc));
  });

  test('readUint32', () {
    const data = [0xaa, 0xbb, 0xcc, 0xdd, 0xee];
    // Little endian (by default)
    final input = InputStream(data);
    expect(input.readUint32(), equals(0xddccbbaa));

    // Big endian
    final i2 = InputStream(data, byteOrder: BIG_ENDIAN);
    expect(i2.readUint32(), equals(0xaabbccdd));
  });

  test('readUint64', () {
    const data = [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0xee, 0xdd];
    // Little endian (by default)
    final input = InputStream(data);
    expect(input.readUint64(), equals(0xddeeffeeddccbbaa));

    // Big endian
    final i2 = InputStream(data, byteOrder: BIG_ENDIAN);
    expect(i2.readUint64(), equals(0xaabbccddeeffeedd));
  });
}
