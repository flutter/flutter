@TestOn('vm')
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:test/test.dart';

import '../common.dart';

Future<BufferedFileReader> openReader(List<int> bytes,
    [int chunkSize = BufferedFileReader.defaultChunkSize]) async {
  var file = await getTempFile(bytes);
  var raf = await file.open();
  return BufferedFileReader(raf, chunkSize);
}

void main() {
  group('BufferedFileReader', () {
    test('constructor creates buffer with correct size', () {
      var reader = BufferedFileReader(null);
      expect(reader.buffer.length, BufferedFileReader.defaultChunkSize);

      reader = BufferedFileReader(null, 10);
      expect(reader.buffer.length, 10);
    });

    group('.skip()', () {
      test('increases offset', () async {
        var reader = await openReader([1, 2, 3, 4, 5]);
        await reader.loadBytes(5);
        expect(reader.remainingInBuffer, 5);
        expect(reader.offset, 0);

        reader.skip(2);
        expect(reader.remainingInBuffer, 3);
        expect(reader.offset, 2);

        reader.skip(3);
        expect(reader.remainingInBuffer, 0);
        expect(reader.offset, 5);

        await reader.file!.close();
      });

      test('fails if not enough bytes available', () async {
        var reader = await openReader([1, 2, 3]);
        await reader.loadBytes(5);
        expect(reader.remainingInBuffer, 3);
        expect(reader.offset, 0);

        expect(() => reader.skip(4), throwsA(anything));

        await reader.file!.close();
      });
    });

    group('.viewBytes()', () {
      test('returns a view with the requested size', () async {
        var reader = await openReader([1, 2, 3, 4, 5]);
        await reader.loadBytes(5);
        expect(reader.offset, 0);

        expect(reader.viewBytes(2), [1, 2]);
        expect(reader.offset, 2);

        expect(reader.viewBytes(3), [3, 4, 5]);
        expect(reader.offset, 5);

        await reader.file!.close();
      });

      test('fails if not enough bytes available', () async {
        var reader = await openReader([1, 2, 3, 4, 5]);
        await reader.loadBytes(5);

        expect(() => reader.viewBytes(6), throwsA(anything));

        await reader.file!.close();
      });
    });

    group('.loadBytes()', () {
      test('returns remaining bytes if enough bytes available', () async {
        var reader = await openReader([1, 2, 3, 4, 5], 3);
        expect(await reader.loadBytes(3), 3);
        expect(await reader.loadBytes(2), 3);

        expect(reader.viewBytes(2), [1, 2]);
        expect(reader.viewBytes(1), [3]);

        await reader.file!.close();
      });

      test('increases the buffer if it is too small', () async {
        var reader = await openReader([1, 2, 3, 4, 5], 2);
        await reader.loadBytes(2);
        expect(reader.viewBytes(2), [1, 2]);

        expect(await reader.loadBytes(3), 3);
        expect(reader.viewBytes(3), [3, 4, 5]);

        await reader.file!.close();
      });

      test('copies unused bytes', () async {
        var reader = await openReader([1, 2, 3, 4, 5, 6, 7], 3);
        await reader.loadBytes(3);
        expect(reader.viewBytes(1), [1]);

        expect(await reader.loadBytes(1), 2);
        expect(await reader.loadBytes(3), 3);
        expect(reader.viewBytes(2), [2, 3]);
        expect(await reader.loadBytes(5), 4);
        expect(reader.viewBytes(3), [4, 5, 6]);

        await reader.file!.close();
      });
    });
  });
}
