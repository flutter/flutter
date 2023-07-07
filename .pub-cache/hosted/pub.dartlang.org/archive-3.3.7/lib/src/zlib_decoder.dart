import 'util/input_stream.dart';
import 'zlib/zlib_decoder_stub.dart'
    if (dart.library.io) 'zlib/_zlib_decoder_io.dart'
    if (dart.library.js) 'zlib/_zlib_decoder_js.dart';

/// Decompress data with the zlib format decoder.
class ZLibDecoder {
  static const int DEFLATE = 8;

  const ZLibDecoder();

  List<int> decodeBytes(List<int> data, {bool verify = false}) {
    return platformZLibDecoder.decodeBytes(data, verify: verify);
  }

  List<int> decodeBuffer(InputStream input, {bool verify = false}) {
    return platformZLibDecoder.decodeBuffer(input, verify: verify);
  }
}
