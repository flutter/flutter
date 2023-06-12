import 'package:archive/archive.dart';
import 'package:test/test.dart';

void main() {
  final buffer = List<int>.filled(10000, 0);
  for (var i = 0; i < buffer.length; ++i) {
    buffer[i] = i % 256;
  }

  test('encode/decode', () {
    final compressed = ZLibEncoder().encode(buffer);
    final decompressed = ZLibDecoder().decodeBytes(compressed, verify: true);
    expect(decompressed.length, equals(buffer.length));
    for (var i = 0; i < buffer.length; ++i) {
      expect(decompressed[i], equals(buffer[i]));
    }
  });
}
