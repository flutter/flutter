import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_memory.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('StorageBackendMemory', () {
    test('.path is null', () {
      var backend = StorageBackendMemory(null, null);
      expect(backend.path, null);
    });

    test('.supportsCompaction is false', () {
      var backend = StorageBackendMemory(null, null);
      expect(backend.supportsCompaction, false);
    });

    group('.initialize()', () {
      test('throws if frames cannot be decoded', () {
        var bytes = Uint8List.fromList([1, 2, 3, 4]);
        var backend = StorageBackendMemory(bytes, null);
        expect(
          () => backend.initialize(TypeRegistryImpl.nullImpl, null, false),
          throwsHiveError('Wrong checksum'),
        );
      });
    });

    test('.readValue() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(
          () => backend.readValue(Frame('key', 'val')), throwsUnsupportedError);
    });

    test('.writeFrames() does nothing', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.writeFrames([Frame('key', 'val')]);
    });

    test('.compact() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(() => backend.compact([]), throwsUnsupportedError);
    });

    test('.clear() does nothing', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.clear();
    });

    test('.close() does nothing', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.close();
    });

    test('.deleteFromDisk() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(() => backend.deleteFromDisk(), throwsUnsupportedError);
    });
  });
}
