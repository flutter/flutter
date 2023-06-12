import 'package:build/build.dart';
import 'package:test/test.dart';

void main() {
  test('InvalidInputException.toString() reports available assets', () {
    final onlyLib = InvalidInputException(AssetId('a', 'test/foo.bar'));
    final libReadmeAndTest = InvalidInputException(AssetId('a', 'test/foo.bar'),
        allowedGlobs: ['lib/**', 'README*', 'test/**']);

    expect(onlyLib.toString(), contains('only assets matching lib/**'));
    expect(libReadmeAndTest.toString(),
        contains('only assets matching lib/**, README* or test/**'));
  });
}
