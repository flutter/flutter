import 'dart:typed_data';

import '../hdr/hdr_image.dart';
import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';
import 'tiff/tiff_entry.dart';
import 'tiff/tiff_image.dart';

/// Encode a TIFF image.
class TiffEncoder extends Encoder {
  @override
  List<int> encodeImage(Image image) {
    final out = OutputBuffer();
    _writeHeader(out);
    _writeImage(out, image);
    out.writeUint32(0); // no offset to the next image
    return out.getBytes();
  }

  List<int> encodeHdrImage(HdrImage image) {
    final out = OutputBuffer();
    _writeHeader(out);
    _writeHdrImage(out, image);
    out.writeUint32(0); // no offset to the next image
    return out.getBytes();
  }

  void _writeHeader(OutputBuffer out) {
    out.writeUint16(LITTLE_ENDIAN); // byteOrder
    out.writeUint16(SIGNATURE); // TIFF signature
    out.writeUint32(8); // Offset to the start of the IFD tags
  }

  void _writeImage(OutputBuffer out, Image image) {
    out.writeUint16(11); // number of IFD entries

    _writeEntryUint32(out, TiffImage.TAG_IMAGE_WIDTH, image.width);
    _writeEntryUint32(out, TiffImage.TAG_IMAGE_LENGTH, image.height);
    _writeEntryUint16(out, TiffImage.TAG_BITS_PER_SAMPLE, 8);
    _writeEntryUint16(
        out, TiffImage.TAG_COMPRESSION, TiffImage.COMPRESSION_NONE);
    _writeEntryUint16(out, TiffImage.TAG_PHOTOMETRIC_INTERPRETATION,
        TiffImage.PHOTOMETRIC_RGB);
    _writeEntryUint16(out, TiffImage.TAG_SAMPLES_PER_PIXEL, 4);
    _writeEntryUint16(out, TiffImage.TAG_SAMPLE_FORMAT, TiffImage.FORMAT_UINT);

    _writeEntryUint32(out, TiffImage.TAG_ROWS_PER_STRIP, image.height);
    _writeEntryUint16(out, TiffImage.TAG_PLANAR_CONFIGURATION, 1);
    _writeEntryUint32(
        out, TiffImage.TAG_STRIP_BYTE_COUNTS, image.width * image.height * 4);
    _writeEntryUint32(out, TiffImage.TAG_STRIP_OFFSETS, out.length + 4);
    out.writeBytes(image.getBytes());
  }

  void _writeHdrImage(OutputBuffer out, HdrImage image) {
    out.writeUint16(11); // number of IFD entries

    _writeEntryUint32(out, TiffImage.TAG_IMAGE_WIDTH, image.width);
    _writeEntryUint32(out, TiffImage.TAG_IMAGE_LENGTH, image.height);
    _writeEntryUint16(out, TiffImage.TAG_BITS_PER_SAMPLE, image.bitsPerSample);
    _writeEntryUint16(
        out, TiffImage.TAG_COMPRESSION, TiffImage.COMPRESSION_NONE);
    _writeEntryUint16(
        out,
        TiffImage.TAG_PHOTOMETRIC_INTERPRETATION,
        image.numberOfChannels == 1
            ? TiffImage.PHOTOMETRIC_BLACKISZERO
            : TiffImage.PHOTOMETRIC_RGB);
    _writeEntryUint16(
        out, TiffImage.TAG_SAMPLES_PER_PIXEL, image.numberOfChannels);
    _writeEntryUint16(
        out, TiffImage.TAG_SAMPLE_FORMAT, _getSampleFormat(image));

    final bytesPerSample = image.bitsPerSample ~/ 8;
    final imageSize =
        image.width * image.height * image.slices.length * bytesPerSample;

    _writeEntryUint32(out, TiffImage.TAG_ROWS_PER_STRIP, image.height);
    _writeEntryUint16(out, TiffImage.TAG_PLANAR_CONFIGURATION, 1);
    _writeEntryUint32(out, TiffImage.TAG_STRIP_BYTE_COUNTS, imageSize);
    _writeEntryUint32(out, TiffImage.TAG_STRIP_OFFSETS, out.length + 4);

    final channels = <Uint8List>[];
    if (image.blue != null) {
      // ? Why does this channel order working but not RGB?
      channels.add(image.blue!.getBytes());
    }
    if (image.red != null) {
      channels.add(image.red!.getBytes());
    }
    if (image.green != null) {
      channels.add(image.green!.getBytes());
    }
    if (image.alpha != null) {
      channels.add(image.alpha!.getBytes());
    }
    if (image.depth != null) {
      channels.add(image.depth!.getBytes());
    }

    for (var y = 0, pi = 0; y < image.height; ++y) {
      for (var x = 0; x < image.width; ++x, pi += bytesPerSample) {
        for (var c = 0; c < channels.length; ++c) {
          final ch = channels[c];
          for (var b = 0; b < bytesPerSample; ++b) {
            out.writeByte(ch[pi + b]);
          }
        }
      }
    }
  }

  int _getSampleFormat(HdrImage image) {
    switch (image.sampleFormat) {
      case HdrImage.UINT:
        return TiffImage.FORMAT_UINT;
      case HdrImage.INT:
        return TiffImage.FORMAT_INT;
    }
    return TiffImage.FORMAT_FLOAT;
  }

  void _writeEntryUint16(OutputBuffer out, int tag, int data) {
    out.writeUint16(tag);
    out.writeUint16(TiffEntry.TYPE_SHORT);
    out.writeUint32(1); // number of values
    out.writeUint16(data);
    out.writeUint16(0); // pad to 4 bytes
  }

  void _writeEntryUint32(OutputBuffer out, int tag, int data) {
    out.writeUint16(tag);
    out.writeUint16(TiffEntry.TYPE_LONG);
    out.writeUint32(1); // number of values
    out.writeUint32(data);
  }

  static const LITTLE_ENDIAN = 0x4949;
  static const SIGNATURE = 42;
}
