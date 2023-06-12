import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame_helper.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class FrameIoHelper extends FrameHelper {
  /// Not part of public API
  @visibleForTesting
  Future<RandomAccessFile> openFile(String path) {
    return File(path).open();
  }

  /// Not part of public API
  @visibleForTesting
  Future<List<int>> readFile(String path) {
    return File(path).readAsBytes();
  }

  /// Not part of public API
  Future<int> keysFromFile(
      String path, Keystore keystore, HiveCipher? cipher) async {
    var raf = await openFile(path);
    var fileReader = BufferedFileReader(raf);
    try {
      return await _KeyReader(fileReader).readKeys(keystore, cipher);
    } finally {
      await raf.close();
    }
  }

  /// Not part of public API
  Future<int> framesFromFile(String path, Keystore keystore,
      TypeRegistry registry, HiveCipher? cipher) async {
    var bytes = await readFile(path);
    return framesFromBytes(bytes as Uint8List, keystore, registry, cipher);
  }
}

class _KeyReader {
  final BufferedFileReader fileReader;

  late BinaryReaderImpl _reader;

  _KeyReader(this.fileReader);

  Future<int> readKeys(Keystore keystore, HiveCipher? cipher) async {
    await _load(4);
    while (true) {
      var frameOffset = fileReader.offset;

      if (_reader.availableBytes < 4) {
        var available = await _load(4);
        if (available == 0) {
          break;
        } else if (available < 4) {
          return frameOffset;
        }
      }

      var frameLength = _reader.peekUint32();
      if (_reader.availableBytes < frameLength) {
        var available = await _load(frameLength);
        if (available < frameLength) return frameOffset;
      }

      var frame = _reader.readFrame(
        cipher: cipher,
        lazy: true,
        frameOffset: frameOffset,
      );
      if (frame == null) return frameOffset;

      keystore.insert(frame, notify: false);

      fileReader.skip(frameLength);
    }

    return -1;
  }

  Future<int> _load(int bytes) async {
    var loadedBytes = await fileReader.loadBytes(bytes);
    var buffer = fileReader.peekBytes(loadedBytes);
    _reader = BinaryReaderImpl(buffer, TypeRegistryImpl.nullImpl);

    return loadedBytes;
  }
}
