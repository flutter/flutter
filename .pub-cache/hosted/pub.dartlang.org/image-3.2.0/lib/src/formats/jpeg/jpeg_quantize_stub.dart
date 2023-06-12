import 'dart:typed_data';
import '../../../image.dart';

// These functions contain bit-shift operations that fail with HTML builds.
// A conditional import is used to use a modified version for HTML builds
// to work around this javascript bug, while keeping the native version fast.

void quantizeAndInverse(Int16List quantizationTable, Int32List? coefBlock,
        Uint8List dataOut, Int32List dataIn) =>
    throw UnsupportedError(
        'Cannot create a jpeg quantizer without dart:html or dart:io');

Image getImageFromJpeg(JpegData jpeg) => throw UnsupportedError(
    'Cannot create a jpeg quantizer without dart:html or dart:io');
