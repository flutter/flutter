import 'zlib_decoder_base.dart';

ZLibDecoderBase get platformZLibDecoder => throw UnsupportedError(
    'Cannot create a zlib decoder without dart:html or dart:io.');
