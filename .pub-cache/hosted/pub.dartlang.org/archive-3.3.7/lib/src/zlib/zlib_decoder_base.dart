import '../util/input_stream.dart';

/// Decompress data with the zlib format decoder.
abstract class ZLibDecoderBase {
  const ZLibDecoderBase();

  List<int> decodeBytes(List<int> data, {bool verify = false});

  List<int> decodeBuffer(InputStream input, {bool verify = false});
}
