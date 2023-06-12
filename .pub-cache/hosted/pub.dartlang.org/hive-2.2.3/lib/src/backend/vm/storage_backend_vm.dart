import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/backend/vm/read_write_sync.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/buffered_file_writer.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:meta/meta.dart';

/// Storage backend for the Dart VM
class StorageBackendVm extends StorageBackend {
  final File _file;
  final File _lockFile;
  final bool _crashRecovery;
  final HiveCipher? _cipher;
  final FrameIoHelper _frameHelper;

  final ReadWriteSync _sync;

  /// Not part of public API
  ///
  /// Not `late final` for testing
  @visibleForTesting
  late RandomAccessFile readRaf;

  /// Not part of public API
  ///
  /// Not `late final` for testing
  @visibleForTesting
  late RandomAccessFile writeRaf;

  /// Not part of public API
  @visibleForTesting
  late RandomAccessFile lockRaf;

  /// Not part of public API
  @visibleForTesting
  int writeOffset = 0;

  /// Not part of public API
  @visibleForTesting
  late final TypeRegistry registry;

  bool _compactionScheduled = false;

  /// Not part of public API
  StorageBackendVm(
      this._file, this._lockFile, this._crashRecovery, this._cipher)
      : _frameHelper = FrameIoHelper(),
        _sync = ReadWriteSync();

  /// Not part of public API
  StorageBackendVm.debug(this._file, this._lockFile, this._crashRecovery,
      this._cipher, this._frameHelper, this._sync);

  @override
  String get path => _file.path;

  @override
  bool supportsCompaction = true;

  /// Not part of public API
  Future open() async {
    readRaf = await _file.open();
    writeRaf = await _file.open(mode: FileMode.writeOnlyAppend);
    writeOffset = await writeRaf.length();
  }

  @override
  Future<void> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    this.registry = registry;

    lockRaf = await _lockFile.open(mode: FileMode.write);
    await lockRaf.lock();

    int recoveryOffset;
    if (!lazy) {
      recoveryOffset =
          await _frameHelper.framesFromFile(path, keystore, registry, _cipher);
    } else {
      recoveryOffset = await _frameHelper.keysFromFile(path, keystore, _cipher);
    }

    if (recoveryOffset != -1) {
      if (_crashRecovery) {
        print('Recovering corrupted box.');
        await writeRaf.truncate(recoveryOffset);
        await writeRaf.setPosition(recoveryOffset);
        writeOffset = recoveryOffset;
      } else {
        throw HiveError('Wrong checksum in hive file. Box may be corrupted.');
      }
    }
  }

  @override
  Future<dynamic> readValue(Frame frame) {
    return _sync.syncRead(() async {
      await readRaf.setPosition(frame.offset);

      var bytes = await readRaf.read(frame.length!);

      var reader = BinaryReaderImpl(bytes, registry);
      var readFrame = reader.readFrame(cipher: _cipher, lazy: false);

      if (readFrame == null) {
        throw HiveError(
            'Could not read value from box. Maybe your box is corrupted.');
      }

      return readFrame.value;
    });
  }

  @override
  Future<void> writeFrames(List<Frame> frames) {
    return _sync.syncWrite(() async {
      var writer = BinaryWriterImpl(registry);

      for (var frame in frames) {
        frame.length = writer.writeFrame(frame, cipher: _cipher);
      }

      try {
        await writeRaf.writeFrom(writer.toBytes());
      } catch (e) {
        await writeRaf.setPosition(writeOffset);
        rethrow;
      }

      for (var frame in frames) {
        frame.offset = writeOffset;
        writeOffset += frame.length!;
      }
    });
  }

  @override
  Future<void> compact(Iterable<Frame> frames) {
    if (_compactionScheduled) return Future.value();
    _compactionScheduled = true;

    return _sync.syncReadWrite(() async {
      await readRaf.setPosition(0);
      var reader = BufferedFileReader(readRaf);

      var fileDirectory = path.substring(0, path.length - 5);
      var compactFile = File('$fileDirectory.hivec');
      var compactRaf = await compactFile.open(mode: FileMode.write);
      var writer = BufferedFileWriter(compactRaf);

      var sortedFrames = frames.toList();
      sortedFrames.sort((a, b) => a.offset.compareTo(b.offset));
      try {
        for (var frame in sortedFrames) {
          if (frame.offset == -1) continue; // Frame has not been written yet
          if (frame.offset != reader.offset) {
            var skip = frame.offset - reader.offset;
            if (reader.remainingInBuffer < skip) {
              if (await reader.loadBytes(skip) < skip) {
                throw HiveError('Could not compact box: Unexpected EOF.');
              }
            }
            reader.skip(skip);
          }

          if (reader.remainingInBuffer < frame.length!) {
            if (await reader.loadBytes(frame.length!) < frame.length!) {
              throw HiveError('Could not compact box: Unexpected EOF.');
            }
          }
          await writer.write(reader.viewBytes(frame.length!));
        }
        await writer.flush();
      } finally {
        await compactRaf.close();
      }

      await readRaf.close();
      await writeRaf.close();
      await compactFile.rename(path);
      await open();

      var offset = 0;
      for (var frame in sortedFrames) {
        if (frame.offset == -1) continue;
        frame.offset = offset;
        offset += frame.length!;
      }
      _compactionScheduled = false;
    });
  }

  @override
  Future<void> clear() {
    return _sync.syncReadWrite(() async {
      await writeRaf.truncate(0);
      await writeRaf.setPosition(0);
      writeOffset = 0;
    });
  }

  Future _closeInternal() async {
    await readRaf.close();
    await writeRaf.close();

    await lockRaf.close();
    await _lockFile.delete();
  }

  @override
  Future<void> close() {
    return _sync.syncReadWrite(_closeInternal);
  }

  @override
  Future<void> deleteFromDisk() {
    return _sync.syncReadWrite(() async {
      await _closeInternal();
      await _file.delete();
    });
  }

  @override
  Future<void> flush() {
    return _sync.syncWrite(() async {
      await writeRaf.flush();
    });
  }
}
