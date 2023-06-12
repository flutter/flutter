@TestOn('vm')
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/vm/read_write_sync.dart';
import 'package:hive/src/backend/vm/storage_backend_vm.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../common.dart';
import '../../frames.dart';
import '../../mocks.dart';

const testMap = {
  'SomeKey': 123,
  'AnotherKey': ['Just', 456, 'a', 333, 'List'],
  'Random Double list': [1.0, 2.0, 10.0, double.infinity],
  'Unicode:': '👋',
  'Null': null,
  'LastKey': true,
};

Uint8List getFrameBytes(Iterable<Frame> frames) {
  var writer = BinaryWriterImpl(testRegistry);
  for (var frame in frames) {
    writer.writeFrame(frame);
  }
  return writer.toBytes();
}

StorageBackendVm _getBackend({
  File? file,
  File? lockFile,
  bool crashRecovery = false,
  HiveCipher? cipher,
  FrameIoHelper? ioHelper,
  ReadWriteSync? sync,
  RandomAccessFile? readRaf,
  RandomAccessFile? writeRaf,
}) {
  final backend = StorageBackendVm.debug(
    file ?? MockFile(),
    lockFile ?? MockFile(),
    crashRecovery,
    cipher,
    ioHelper ?? MockFrameIoHelper(),
    sync ?? ReadWriteSync(),
  );
  if (readRaf != null) {
    backend.readRaf = readRaf;
  }
  if (writeRaf != null) {
    backend.writeRaf = writeRaf;
  }
  return backend;
}

void main() {
  setUpAll(() {
    registerFallbackValue(KeystoreFake());
    registerFallbackValue(TypeRegistryFake());
  });

  group('StorageBackendVm', () {
    test('.path returns path for of open box file', () {
      var file = File('some/path');
      var backend = _getBackend(file: file);
      expect(backend.path, 'some/path');
    });

    test('.supportsCompaction is true', () {
      var backend = _getBackend();
      expect(backend.supportsCompaction, true);
    });

    group('.open()', () {
      test('readFile & writeFile', () async {
        var file = MockFile();
        var readRaf = MockRandomAccessFile();
        var writeRaf = MockRandomAccessFile();
        when(() => file.open()).thenAnswer((i) => Future.value(readRaf));
        when(() => file.open(mode: FileMode.writeOnlyAppend))
            .thenAnswer((i) => Future.value(writeRaf));
        when(() => writeRaf.length()).thenAnswer((_) => Future.value(0));

        var backend = _getBackend(file: file);
        await backend.open();
        expect(backend.readRaf, readRaf);
        expect(backend.writeRaf, writeRaf);
      });

      test('writeOffset', () async {
        var file = MockFile();
        var writeFile = MockRandomAccessFile();
        var readRaf = MockRandomAccessFile();
        when(() => file.open(mode: FileMode.writeOnlyAppend))
            .thenAnswer((i) => Future.value(writeFile));
        when(() => file.open()).thenAnswer((i) => Future.value(readRaf));
        when(() => writeFile.length()).thenAnswer((i) => Future.value(123));

        var backend = _getBackend(file: file);
        await backend.open();
        expect(backend.writeOffset, 123);
      });
    });

    group('.initialize()', () {
      File getLockFile() {
        var lockMockFile = MockFile();
        when(() => lockMockFile.open(mode: FileMode.write))
            .thenAnswer((i) => Future.value(MockRandomAccessFile()));
        return lockMockFile;
      }

      FrameIoHelper getFrameIoHelper(int recoveryOffset) {
        var helper = MockFrameIoHelper();
        when(() => helper.framesFromFile(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((i) => Future.value(recoveryOffset));
        when(() => helper.keysFromFile(
              any(),
              any(),
              any(),
            )).thenAnswer((i) => Future.value(recoveryOffset));
        return helper;
      }

      void runTests(bool lazy) {
        test('opens lock file and acquires lock', () async {
          var lockFile = MockFile();
          var lockRaf = MockRandomAccessFile();
          when(() => lockFile.open(mode: FileMode.write))
              .thenAnswer((i) => Future.value(lockRaf));
          when(() => lockRaf.lock()).thenAnswer((i) => Future.value(lockRaf));

          var backend = _getBackend(
            lockFile: lockFile,
            ioHelper: getFrameIoHelper(-1),
          );
          when(() => backend.path).thenReturn('nullPath');

          await backend.initialize(
              TypeRegistryImpl.nullImpl, MockKeystore(), lazy);
          verify(() => lockRaf.lock());
        });

        test('recoveryOffset with crash recovery', () async {
          var writeRaf = MockRandomAccessFile();
          var lockFile = getLockFile();
          var lockRaf = MockRandomAccessFile();

          var backend = _getBackend(
            lockFile: lockFile,
            ioHelper: getFrameIoHelper(20),
            crashRecovery: true,
            writeRaf: writeRaf,
          );
          when(() => backend.path).thenReturn('nullPath');
          when(() => lockFile.open(mode: FileMode.write))
              .thenAnswer((i) => Future.value(lockRaf));
          when(() => lockRaf.lock()).thenAnswer((i) => Future.value(lockRaf));
          when(() => writeRaf.truncate(20))
              .thenAnswer((i) => Future.value(writeRaf));
          when(() => writeRaf.setPosition(20))
              .thenAnswer((i) => Future.value(writeRaf));

          await backend.initialize(
              TypeRegistryImpl.nullImpl, MockKeystore(), lazy);
          verify(() => writeRaf.truncate(20));
          verify(() => writeRaf.setPosition(20));
        });

        test('recoveryOffset without crash recovery', () async {
          var lockFile = getLockFile();
          var lockRaf = MockRandomAccessFile();

          var backend = _getBackend(
            lockFile: lockFile,
            ioHelper: getFrameIoHelper(20),
            crashRecovery: false,
          );
          when(() => backend.path).thenReturn('nullPath');
          when(() => lockFile.open(mode: FileMode.write))
              .thenAnswer((i) => Future.value(lockRaf));
          when(() => lockRaf.lock()).thenAnswer((i) => Future.value(lockRaf));

          await expectLater(
              () => backend.initialize(
                  TypeRegistryImpl.nullImpl, MockKeystore(), lazy),
              throwsHiveError('corrupted'));
        });
      }

      group('(not lazy)', () {
        runTests(false);
      });

      group('(lazy)', () {
        runTests(true);
      });
    });

    group('.readValue()', () {
      test('reads value with offset', () async {
        var frameBytes = getFrameBytes([Frame('test', 123)]);
        var readRaf = await getTempRaf([1, 2, 3, 4, 5, ...frameBytes]);

        var backend = _getBackend(readRaf: readRaf)
          // The registry needs to be initialized before reading values, and
          // because we do not call StorageBackendVM.initialize(), we set it
          // manually.
          ..registry = TypeRegistryImpl.nullImpl;
        var value = await backend.readValue(
          Frame('test', 123, length: frameBytes.length, offset: 5),
        );
        expect(value, 123);

        await readRaf.close();
      });

      test('throws exception when frame cannot be read', () async {
        var readRaf = await getTempRaf([1, 2, 3, 4, 5]);
        var backend = _getBackend(readRaf: readRaf)
          // The registry needs to be initialized before reading values, and
          // because we do not call StorageBackendVM.initialize(), we set it
          // manually.
          ..registry = TypeRegistryImpl.nullImpl;

        var frame = Frame('test', 123, length: frameBytes.length, offset: 0);
        await expectLater(
            () => backend.readValue(frame), throwsHiveError('corrupted'));

        await readRaf.close();
      });
    });

    group('.writeFrames()', () {
      test('writes bytes', () async {
        var frames = [Frame('key1', 'value'), Frame('key2', null)];
        var bytes = getFrameBytes(frames);

        var writeRaf = MockRandomAccessFile();
        when(() => writeRaf.setPosition(0))
            .thenAnswer((i) => Future.value(writeRaf));
        when(() => writeRaf.writeFrom(bytes))
            .thenAnswer((i) => Future.value(writeRaf));

        var backend = _getBackend(writeRaf: writeRaf)
          // The registry needs to be initialized before writing values, and
          // because we do not call StorageBackendVM.initialize(), we set it
          // manually.
          ..registry = TypeRegistryImpl.nullImpl;

        await backend.writeFrames(frames);
        verify(() => writeRaf.writeFrom(bytes));
      });

      test('updates offsets', () async {
        var frames = [Frame('key1', 'value'), Frame('key2', null)];

        var writeRaf = MockRandomAccessFile();
        when(() => writeRaf.setPosition(5))
            .thenAnswer((i) => Future.value(writeRaf));
        when(() => writeRaf.writeFrom(any()))
            .thenAnswer((i) => Future.value(writeRaf));

        var backend = _getBackend(writeRaf: writeRaf)
          // The registry needs to be initialized before writing values, and
          // because we do not call StorageBackendVM.initialize(), we set it
          // manually.
          ..registry = TypeRegistryImpl.nullImpl;
        backend.writeOffset = 5;

        await backend.writeFrames(frames);
        expect(frames, [
          Frame('key1', 'value', length: 24, offset: 5),
          Frame('key2', null, length: 15, offset: 29),
        ]);
        expect(backend.writeOffset, 44);
      });

      test('resets writeOffset on error', () async {
        var writeRaf = MockRandomAccessFile();
        when(() => writeRaf.writeFrom(any())).thenThrow('error');
        var backend = _getBackend(writeRaf: writeRaf)
          // The registry needs to be initialized before writing values, and
          // because we do not call StorageBackendVM.initialize(), we set it
          // manually.
          ..registry = TypeRegistryImpl.nullImpl;
        backend.writeOffset = 123;

        await expectLater(() => backend.writeFrames([Frame('key1', 'value')]),
            throwsA(anything));
        verify(() => writeRaf.setPosition(123));
        expect(backend.writeOffset, 123);
      });
    });

    /*group('.compact()', () {
      //TODO improve this test
      test('check compaction', () async {
        var bytes = BytesBuilder();
        var comparisonBytes = BytesBuilder();
        var entries = <String, Frame>{};

        void addFrame(String key, dynamic val, [bool keep = false]) {
          var frameBytes = Frame(key, val).toBytes(null, null);
          if (keep) {
            entries[key] = Frame(key, val,
                length: frameBytes.length, offset: bytes.length);
            comparisonBytes.add(frameBytes);
          } else {
            entries.remove(key);
          }
          bytes.add(frameBytes);
        }

        for (var i = 0; i < 1000; i++) {
          for (var key in testMap.keys) {
            addFrame(key, testMap[key]);
            addFrame(key, null);
          }
        }

        for (var key in testMap.keys) {
          addFrame(key, 12345);
          addFrame(key, null);
          addFrame(key, 'This is a test');
          addFrame(key, testMap[key], true);
        }

        var boxFile = await getTempFile();
        await boxFile.writeAsBytes(bytes.toBytes());

        var syncedFile = SyncedFile(boxFile.path);
        await syncedFile.open();
        var backend = StorageBackendVm(syncedFile, null);

        await backend.compact(entries.values);

        var compactedBytes = await File(backend.path).readAsBytes();
        expect(compactedBytes, comparisonBytes.toBytes());

        await backend.close();
      });

      test('throws error if corrupted', () async {
        var bytes = BytesBuilder();
        var boxFile = await getTempFile(); 
        var syncedFile = SyncedFile(boxFile.path);
        await syncedFile.open();

        var box = BoxImplVm(
            HiveImpl(), path.basename(boxFile.path), BoxOptions(), syncedFile);
        await box.put('test', true);
        await box.put('test2', 'hello');
        await box.put('test', 'world');

        await syncedFile.truncate(await boxFile.length() - 1);

        expect(() => box.compact(), throwsHiveError('unexpected eof'));
      });
    });*/

    test('.clear()', () async {
      var writeRaf = MockRandomAccessFile();
      when(() => writeRaf.truncate(0))
          .thenAnswer((i) => Future.value(writeRaf));
      when(() => writeRaf.setPosition(0))
          .thenAnswer((i) => Future.value(writeRaf));
      var backend = _getBackend(writeRaf: writeRaf);
      backend.writeOffset = 111;

      await backend.clear();
      verify(() => writeRaf.truncate(0));
      verify(() => writeRaf.setPosition(0));
      expect(backend.writeOffset, 0);
    });

    test('.close()', () async {
      var readRaf = MockRandomAccessFile();
      var writeRaf = MockRandomAccessFile();
      var lockRaf = MockRandomAccessFile();
      var lockFile = MockFile();

      returnFutureVoid(when(() => readRaf.close()));
      returnFutureVoid(when(() => writeRaf.close()));
      returnFutureVoid(when(() => lockRaf.close()));
      when(() => lockFile.delete()).thenAnswer((i) => Future.value(lockFile));

      var backend = _getBackend(
        lockFile: lockFile,
        readRaf: readRaf,
        writeRaf: writeRaf,
      );
      backend.lockRaf = lockRaf;

      await backend.close();
      verifyInOrder([
        () => readRaf.close(),
        () => writeRaf.close(),
        () => lockRaf.close(),
        () => lockFile.delete(),
      ]);
    });

    test('.deleteFromDisk()', () async {
      var readRaf = MockRandomAccessFile();
      var writeRaf = MockRandomAccessFile();
      var lockRaf = MockRandomAccessFile();
      var lockFile = MockFile();
      var file = MockFile();

      returnFutureVoid(when(() => readRaf.close()));
      returnFutureVoid(when(() => writeRaf.close()));
      returnFutureVoid(when(() => lockRaf.close()));
      when(() => lockFile.delete()).thenAnswer((i) => Future.value(lockFile));
      when(() => file.delete()).thenAnswer((i) => Future.value(file));

      var backend = _getBackend(
        file: file,
        lockFile: lockFile,
        readRaf: readRaf,
        writeRaf: writeRaf,
      );
      backend.lockRaf = lockRaf;

      await backend.deleteFromDisk();
      verifyInOrder([
        () => readRaf.close(),
        () => writeRaf.close(),
        () => lockRaf.close(),
        () => lockFile.delete(),
        () => file.delete()
      ]);
    });
  });
}
