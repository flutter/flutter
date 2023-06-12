import 'package:archive/archive.dart';
import 'package:test/test.dart';

void main() {
  final buffer = List<int>.filled(0xfffff, 0);
  for (var i = 0; i < buffer.length; ++i) {
    buffer[i] = i % 256;
  }

  test('NO_COMPRESSION', () {
    final deflated = Deflate(buffer, level: Deflate.NO_COMPRESSION).getBytes();

    final inflated = Inflate(deflated).getBytes();

    expect(inflated.length, equals(buffer.length));
    for (var i = 0; i < buffer.length; ++i) {
      expect(inflated[i], equals(buffer[i]));
    }
  });

  test('BEST_SPEED', () {
    final deflated = Deflate(buffer, level: Deflate.BEST_SPEED).getBytes();

    final inflated = Inflate(deflated).getBytes();

    expect(inflated.length, equals(buffer.length));
    for (var i = 0; i < buffer.length; ++i) {
      expect(inflated[i], equals(buffer[i]));
    }
  });

  test('BEST_COMPRESSION', () {
    final deflated =
        Deflate(buffer, level: Deflate.BEST_COMPRESSION).getBytes();

    final inflated = Inflate(deflated).getBytes();

    expect(inflated.length, equals(buffer.length));
    for (var i = 0; i < buffer.length; ++i) {
      expect(inflated[i], equals(buffer[i]));
    }
  });
}
