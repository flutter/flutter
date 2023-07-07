import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../util/input_buffer.dart';
import '../../util/output_buffer.dart';
import 'jpeg_marker.dart';

class JpegUtil {
  static const exifSignature = 0x45786966; // Exif\0\0

  ExifData? decodeExif(Uint8List jpeg) {
    final input = InputBuffer(jpeg, bigEndian: true);

    // Some other formats have embedded jpeg, or jpeg-like data.
    // Only validate if the image starts with the StartOfImage tag.
    final soiCheck = input.peekBytes(2);
    if (soiCheck[0] != 0xff || soiCheck[1] != 0xd8) {
      return null;
    }

    var marker = _nextMarker(input);
    if (marker != JpegMarker.soi) {
      return null;
    }

    ExifData? exif;
    marker = _nextMarker(input);
    while (marker != JpegMarker.eoi && !input.isEOS) {
      switch (marker) {
        case JpegMarker.app1:
          exif = _readExifData(_readBlock(input));
          if (exif != null) {
            return exif;
          }
          break;
        default:
          _skipBlock(input);
          break;
      }
      marker = _nextMarker(input);
    }

    return null;
  }

  Uint8List? injectExif(ExifData exif, Uint8List jpeg) {
    final input = InputBuffer(jpeg, bigEndian: true);

    // Some other formats have embedded jpeg, or jpeg-like data.
    // Only validate if the image starts with the StartOfImage tag.
    final soiCheck = input.peekBytes(2);
    if (soiCheck[0] != 0xff || soiCheck[1] != 0xd8) {
      return null;
    }

    final output = OutputBuffer(size: jpeg.length, bigEndian: true);

    var marker = _nextMarker(input, output);
    if (marker != JpegMarker.soi) {
      return null;
    }

    // Check to see if the JPEG file has an EXIF block
    var hasExifBlock = false;
    final startOffset = input.offset;
    marker = _nextMarker(input);
    while (!hasExifBlock && marker != JpegMarker.eoi && !input.isEOS) {
      if (marker == JpegMarker.app1) {
        final block = _readBlock(input);
        final signature = block?.readUint32();
        if (signature == exifSignature) {
          hasExifBlock = true;
          break;
        }
      } else {
        _skipBlock(input);
      }
      marker = _nextMarker(input);
    }

    input.offset = startOffset;

    // If the JPEG file does not have an EXIF block, add a new one.
    if (!hasExifBlock) {
      _writeAPP1(output, exif);
      // No need to parse the remaining individual blocks, just write out
      // the remainder of the file.
      output.writeBuffer(input.readBytes(input.length));
      return output.getBytes();
    }

    marker = _nextMarker(input, output);
    while (marker != JpegMarker.eoi && !input.isEOS) {
      if (marker == JpegMarker.app1) {
        final saveOffset = input.offset;
        input.skip(2); // block length
        final signature = input.readUint32();
        input.offset = saveOffset;
        if (signature == exifSignature) {
          _skipBlock(input);
          _writeAPP1(output, exif);
          // No need to parse the remaining individual blocks, just write out
          // the remainder of the file.
          output.writeBuffer(input.readBytes(input.length));
          return output.getBytes();
        }
      }
      _skipBlock(input, output);
      marker = _nextMarker(input, output);
    }

    return output.getBytes();
  }

  ExifData? _readExifData(InputBuffer? block) {
    if (block == null) {
      return null;
    }
    // Exif Header
    final signature = block.readUint32();
    if (signature != exifSignature) {
      return null;
    }
    if (block.readUint16() != 0) {
      return null;
    }

    return ExifData.fromInputBuffer(block);
  }

  void _writeAPP1(OutputBuffer out, ExifData exif) {
    if (exif.isEmpty) {
      return;
    }

    final exifData = OutputBuffer();
    exif.write(exifData);
    final exifBytes = exifData.getBytes();

    out
      ..writeUint16(exifBytes.length + 8)
      ..writeUint32(exifSignature)
      ..writeUint16(0)
      ..writeBytes(exifBytes);
  }

  InputBuffer? _readBlock(InputBuffer input) {
    final length = input.readUint16();
    if (length < 2) {
      return null;
    }
    return input.readBytes(length - 2);
  }

  bool _skipBlock(InputBuffer input, [OutputBuffer? output]) {
    final length = input.readUint16();
    output?.writeUint16(length);
    if (length < 2) {
      return false;
    }
    if (output != null) {
      output.writeBuffer(input.readBytes(length - 2));
    } else {
      input.skip(length - 2);
    }
    return true;
  }

  int _nextMarker(InputBuffer input, [OutputBuffer? output]) {
    var c = 0;
    if (input.isEOS) {
      return c;
    }

    do {
      do {
        c = input.readByte();
        output?.writeByte(c);
      } while (c != 0xff && !input.isEOS);

      if (input.isEOS) {
        return c;
      }

      do {
        c = input.readByte();
        output?.writeByte(c);
      } while (c == 0xff && !input.isEOS);
    } while (c == 0 && !input.isEOS);

    return c;
  }
}
