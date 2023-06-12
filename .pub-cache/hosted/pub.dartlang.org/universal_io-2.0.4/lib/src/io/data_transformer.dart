// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';

/// An instance of the default implementation of the [GZipCodec].
const GZipCodec gzip = GZipCodec._default();

@Deprecated('Use gzip instead')
const GZipCodec GZIP = gzip;

/// An instance of the default implementation of the [ZLibCodec].
const ZLibCodec zlib = ZLibCodec._default();

@Deprecated('Use zlib instead')
const ZLibCodec ZLIB = zlib;

void _validateZLibeLevel(int level) {
  if (ZLibOption.minLevel > level || ZLibOption.maxLevel < level) {
    throw RangeError.range(level, ZLibOption.minLevel, ZLibOption.maxLevel);
  }
}

void _validateZLibMemLevel(int memLevel) {
  if (ZLibOption.minMemLevel > memLevel || ZLibOption.maxMemLevel < memLevel) {
    throw RangeError.range(
        memLevel, ZLibOption.minMemLevel, ZLibOption.maxMemLevel);
  }
}

void _validateZLibStrategy(int strategy) {
  const strategies = <int>[
    ZLibOption.strategyFiltered,
    ZLibOption.strategyHuffmanOnly,
    ZLibOption.strategyRle,
    ZLibOption.strategyFixed,
    ZLibOption.strategyDefault
  ];
  if (!strategies.contains(strategy)) {
    throw ArgumentError("Unsupported 'strategy'");
  }
}

void _validateZLibWindowBits(int windowBits) {
  if (ZLibOption.minWindowBits > windowBits ||
      ZLibOption.maxWindowBits < windowBits) {
    throw RangeError.range(
        windowBits, ZLibOption.minWindowBits, ZLibOption.maxWindowBits);
  }
}

/// The [GZipCodec] encodes raw bytes to GZip compressed bytes and decodes GZip
/// compressed bytes to raw bytes.
///
/// The difference between [ZLibCodec] and [GZipCodec] is that the [GZipCodec]
/// wraps the `ZLib` compressed bytes in `GZip` frames.
class GZipCodec extends Codec<List<int>, List<int>> {
  /// When true, `GZip` frames will be added to the compressed data.
  final bool gzip;

  /// The compression-[level] can be set in the range of `-1..9`, with `6` being
  /// the default compression level. Levels above `6` will have higher
  /// compression rates at the cost of more CPU and memory usage. Levels below
  /// `6` will use less CPU and memory at the cost of lower compression rates.
  final int level;

  /// Specifies how much memory should be allocated for the internal compression
  /// state. `1` uses minimum memory but is slow and reduces compression ratio;
  /// `9` uses maximum memory for optimal speed. The default value is `8`.
  ///
  /// The memory requirements for deflate are (in bytes):
  ///
  ///     (1 << (windowBits + 2)) +  (1 << (memLevel + 9))
  /// that is: 128K for windowBits = 15 + 128K for memLevel = 8 (default values)
  final int memLevel;

  /// Tunes the compression algorithm. Use the value
  /// [ZLibOption.strategyDefault] for normal data,
  /// [ZLibOption.strategyFiltered] for data produced by a filter
  /// (or predictor), [ZLibOption.strategyHuffmanOnly] to force Huffman
  /// encoding only (no string match), or [ZLibOption.strategyRle] to limit
  /// match distances to one (run-length encoding).
  final int strategy;

  /// Base two logarithm of the window size (the size of the history buffer). It
  /// should be in the range `8..15`. Larger values result in better compression
  /// at the expense of memory usage. The default value is `15`
  final int windowBits;

  /// Initial compression dictionary.
  ///
  /// It should consist of strings (byte sequences) that are likely to be
  /// encountered later in the data to be compressed, with the most commonly used
  /// strings preferably put towards the end of the dictionary. Using a
  /// dictionary is most useful when the data to be compressed is short and can
  /// be predicted with good accuracy; the data can then be compressed better
  /// than with the default empty dictionary.
  final List<int>? dictionary;

  /// When true, deflate generates raw data with no zlib header or trailer, and
  /// will not compute an adler32 check value
  final bool raw;

  GZipCodec(
      {this.level = ZLibOption.defaultLevel,
      this.windowBits = ZLibOption.defaultWindowBits,
      this.memLevel = ZLibOption.defaultMemLevel,
      this.strategy = ZLibOption.strategyDefault,
      this.dictionary,
      this.raw = false,
      this.gzip = true}) {
    _validateZLibeLevel(level);
    _validateZLibMemLevel(memLevel);
    _validateZLibStrategy(strategy);
    _validateZLibWindowBits(windowBits);
  }

  const GZipCodec._default()
      : level = ZLibOption.defaultLevel,
        windowBits = ZLibOption.defaultWindowBits,
        memLevel = ZLibOption.defaultMemLevel,
        strategy = ZLibOption.strategyDefault,
        raw = false,
        gzip = true,
        dictionary = null;

  /// Get a [ZLibDecoder] for decoding `GZip` compressed data.
  @override
  ZLibDecoder get decoder =>
      ZLibDecoder(windowBits: windowBits, dictionary: dictionary, raw: raw);

  /// Get a [ZLibEncoder] for encoding to `GZip` compressed data.
  @override
  ZLibEncoder get encoder => ZLibEncoder(
      gzip: true,
      level: level,
      windowBits: windowBits,
      memLevel: memLevel,
      strategy: strategy,
      dictionary: dictionary,
      raw: raw);
}

/// The [RawZLibFilter] class provides a low-level interface to zlib.
abstract class RawZLibFilter {
  /// Returns a a [RawZLibFilter] whose [process] and [processed] methods
  /// compress data.
  factory RawZLibFilter.deflateFilter({
    bool gzip = false,
    int level = ZLibOption.defaultLevel,
    int? windowBits = ZLibOption.defaultWindowBits,
    int memLevel = ZLibOption.defaultMemLevel,
    int strategy = ZLibOption.strategyDefault,
    List<int>? dictionary,
    bool raw = false,
  }) {
    return _makeZLibDeflateFilter(
        gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  }

  /// Returns a a [RawZLibFilter] whose [process] and [processed] methods
  /// decompress data.
  factory RawZLibFilter.inflateFilter({
    int? windowBits = ZLibOption.defaultWindowBits,
    List<int>? dictionary,
    bool raw = false,
  }) {
    return _makeZLibInflateFilter(windowBits, dictionary, raw);
  }

  /// Call to process a chunk of data. A call to [process] should only be made
  /// when [processed] returns [:null:].
  void process(List<int> data, int start, int end);

  /// Get a chunk of processed data. When there are no more data available,
  /// [processed] will return [:null:]. Set [flush] to [:false:] for non-final
  /// calls to improve performance of some filters.
  ///
  /// The last call to [processed] should have [end] set to [:true:]. This will
  /// make sure an 'end' packet is written on the stream.
  List<int> processed({bool flush = true, bool end = false});

  static RawZLibFilter _makeZLibDeflateFilter(
      bool gzip,
      int level,
      int? windowBits,
      int memLevel,
      int strategy,
      List<int>? dictionary,
      bool raw) {
    throw UnimplementedError();
  }

  static RawZLibFilter _makeZLibInflateFilter(
      int? windowBits, List<int>? dictionary, bool raw) {
    throw UnimplementedError();
  }
}

/// The [ZLibCodec] encodes raw bytes to ZLib compressed bytes and decodes ZLib
/// compressed bytes to raw bytes.
class ZLibCodec extends Codec<List<int>, List<int>> {
  /// When true, `GZip` frames will be added to the compressed data.
  final bool gzip;

  /// The compression-[level] can be set in the range of `-1..9`, with `6` being
  /// the default compression level. Levels above `6` will have higher
  /// compression rates at the cost of more CPU and memory usage. Levels below
  /// `6` will use less CPU and memory at the cost of lower compression rates.
  final int level;

  /// Specifies how much memory should be allocated for the internal compression
  /// state. `1` uses minimum memory but is slow and reduces compression ratio;
  /// `9` uses maximum memory for optimal speed. The default value is `8`.
  ///
  /// The memory requirements for deflate are (in bytes):
  ///
  ///     (1 << (windowBits + 2)) +  (1 << (memLevel + 9))
  /// that is: 128K for windowBits = 15 + 128K for memLevel = 8 (default values)
  final int memLevel;

  /// Tunes the compression algorithm. Use the value strategyDefault for normal
  /// data, strategyFiltered for data produced by a filter (or predictor),
  /// strategyHuffmanOnly to force Huffman encoding only (no string match), or
  /// strategyRle to limit match distances to one (run-length encoding).
  final int strategy;

  /// Base two logarithm of the window size (the size of the history buffer). It
  /// should be in the range 8..15. Larger values result in better compression at
  /// the expense of memory usage. The default value is 15
  final int windowBits;

  /// When true, deflate generates raw data with no zlib header or trailer, and
  /// will not compute an adler32 check value
  final bool raw;

  /// Initial compression dictionary.
  ///
  /// It should consist of strings (byte sequences) that are likely to be
  /// encountered later in the data to be compressed, with the most commonly used
  /// strings preferably put towards the end of the dictionary. Using a
  /// dictionary is most useful when the data to be compressed is short and can
  /// be predicted with good accuracy; the data can then be compressed better
  /// than with the default empty dictionary.
  final List<int>? dictionary;

  ZLibCodec(
      {this.level = ZLibOption.defaultLevel,
      this.windowBits = ZLibOption.defaultWindowBits,
      this.memLevel = ZLibOption.defaultMemLevel,
      this.strategy = ZLibOption.strategyDefault,
      this.dictionary,
      this.raw = false,
      this.gzip = false}) {
    _validateZLibeLevel(level);
    _validateZLibMemLevel(memLevel);
    _validateZLibStrategy(strategy);
    _validateZLibWindowBits(windowBits);
  }

  const ZLibCodec._default()
      : level = ZLibOption.defaultLevel,
        windowBits = ZLibOption.defaultWindowBits,
        memLevel = ZLibOption.defaultMemLevel,
        strategy = ZLibOption.strategyDefault,
        raw = false,
        gzip = false,
        dictionary = null;

  /// Get a [ZLibDecoder] for decoding `ZLib` compressed data.
  @override
  ZLibDecoder get decoder =>
      ZLibDecoder(windowBits: windowBits, dictionary: dictionary, raw: raw);

  /// Get a [ZLibEncoder] for encoding to `ZLib` compressed data.
  @override
  ZLibEncoder get encoder => ZLibEncoder(
      gzip: false,
      level: level,
      windowBits: windowBits,
      memLevel: memLevel,
      strategy: strategy,
      dictionary: dictionary,
      raw: raw);
}

/// The [ZLibDecoder] is used by [ZLibCodec] and [GZipCodec] to decompress data.
class ZLibDecoder extends Converter<List<int>, List<int>> {
  /// Base two logarithm of the window size (the size of the history buffer). It
  /// should be in the range `8..15`. Larger values result in better compression
  /// at the expense of memory usage. The default value is `15`.
  final int windowBits;

  /// Initial compression dictionary.
  ///
  /// It should consist of strings (byte sequences) that are likely to be
  /// encountered later in the data to be compressed, with the most commonly used
  /// strings preferably put towards the end of the dictionary. Using a
  /// dictionary is most useful when the data to be compressed is short and can
  /// be predicted with good accuracy; the data can then be compressed better
  /// than with the default empty dictionary.
  final List<int>? dictionary;

  /// When true, deflate generates raw data with no zlib header or trailer, and
  /// will not compute an adler32 check value
  final bool raw;

  ZLibDecoder(
      {this.windowBits = ZLibOption.defaultWindowBits,
      this.dictionary,
      this.raw = false}) {
    _validateZLibWindowBits(windowBits);
  }

  /// Convert a list of bytes using the options given to the [ZLibDecoder]
  /// constructor.
  @override
  List<int> convert(List<int> bytes) {
    throw UnimplementedError();
  }

  /// Start a chunked conversion. While it accepts any [Sink]
  /// taking [List<int>]'s, the optimal sink to be passed as [sink] is a
  /// [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    throw UnimplementedError();
  }
}

/// The [ZLibEncoder] encoder is used by [ZLibCodec] and [GZipCodec] to compress
/// data.
class ZLibEncoder extends Converter<List<int>, List<int>> {
  /// When true, `GZip` frames will be added to the compressed data.
  final bool gzip;

  /// The compression-[level] can be set in the range of `-1..9`, with `6` being
  /// the default compression level. Levels above `6` will have higher
  /// compression rates at the cost of more CPU and memory usage. Levels below
  /// `6` will use less CPU and memory at the cost of lower compression rates.
  final int level;

  /// Specifies how much memory should be allocated for the internal compression
  /// state. `1` uses minimum memory but is slow and reduces compression ratio;
  /// `9` uses maximum memory for optimal speed. The default value is `8`.
  ///
  /// The memory requirements for deflate are (in bytes):
  ///
  ///     (1 << (windowBits + 2)) +  (1 << (memLevel + 9))
  /// that is: 128K for windowBits = 15 + 128K for memLevel = 8 (default values)
  final int memLevel;

  /// Tunes the compression algorithm. Use the value
  /// [ZLibOption.strategyDefault] for normal data,
  /// [ZLibOption.strategyFiltered] for data produced by a filter
  /// (or predictor), [ZLibOption.strategyHuffmanOnly] to force Huffman
  /// encoding only (no string match), or [ZLibOption.strategyRle] to limit
  /// match distances to one (run-length encoding).
  final int strategy;

  /// Base two logarithm of the window size (the size of the history buffer). It
  /// should be in the range `8..15`. Larger values result in better compression
  /// at the expense of memory usage. The default value is `15`
  final int windowBits;

  /// Initial compression dictionary.
  ///
  /// It should consist of strings (byte sequences) that are likely to be
  /// encountered later in the data to be compressed, with the most commonly used
  /// strings preferably put towards the end of the dictionary. Using a
  /// dictionary is most useful when the data to be compressed is short and can
  /// be predicted with good accuracy; the data can then be compressed better
  /// than with the default empty dictionary.
  final List<int>? dictionary;

  /// When true, deflate generates raw data with no zlib header or trailer, and
  /// will not compute an adler32 check value
  final bool raw;

  ZLibEncoder(
      {this.gzip = false,
      this.level = ZLibOption.defaultLevel,
      this.windowBits = ZLibOption.defaultWindowBits,
      this.memLevel = ZLibOption.defaultMemLevel,
      this.strategy = ZLibOption.strategyDefault,
      this.dictionary,
      this.raw = false}) {
    _validateZLibeLevel(level);
    _validateZLibMemLevel(memLevel);
    _validateZLibStrategy(strategy);
    _validateZLibWindowBits(windowBits);
  }

  /// Convert a list of bytes using the options given to the ZLibEncoder
  /// constructor.
  @override
  List<int> convert(List<int> bytes) {
    throw UnimplementedError();
  }

  /// Start a chunked conversion using the options given to the [ZLibEncoder]
  /// constructor. While it accepts any [Sink] taking [List<int>]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    throw UnimplementedError();
  }
}

/// Exposes ZLib options for input parameters.
///
/// See http://www.zlib.net/manual.html for more documentation.
abstract class ZLibOption {
  /// Minimal value for [ZLibCodec.windowBits], [ZLibEncoder.windowBits]
  /// and [ZLibDecoder.windowBits].
  static const int minWindowBits = 8;
  @Deprecated('Use minWindowBits instead')
  static const int MIN_WINDOW_BITS = 8;

  /// Maximal value for [ZLibCodec.windowBits], [ZLibEncoder.windowBits]
  /// and [ZLibDecoder.windowBits].
  static const int maxWindowBits = 15;
  @Deprecated('Use maxWindowBits instead')
  static const int MAX_WINDOW_BITS = 15;

  /// Default value for [ZLibCodec.windowBits], [ZLibEncoder.windowBits]
  /// and [ZLibDecoder.windowBits].
  static const int defaultWindowBits = 15;
  @Deprecated('Use defaultWindowBits instead')
  static const int DEFAULT_WINDOW_BITS = 15;

  /// Minimal value for [ZLibCodec.level] and [ZLibEncoder.level].
  static const int minLevel = -1;
  @Deprecated('Use minLevel instead')
  static const int MIN_LEVEL = -1;

  /// Maximal value for [ZLibCodec.level] and [ZLibEncoder.level]
  static const int maxLevel = 9;
  @Deprecated('Use maxLevel instead')
  static const int MAX_LEVEL = 9;

  /// Default value for [ZLibCodec.level] and [ZLibEncoder.level].
  static const int defaultLevel = 6;
  @Deprecated('Use defaultLevel instead')
  static const int DEFAULT_LEVEL = 6;

  /// Minimal value for [ZLibCodec.memLevel] and [ZLibEncoder.memLevel].
  static const int minMemLevel = 1;
  @Deprecated('Use minMemLevel instead')
  static const int MIN_MEM_LEVEL = 1;

  /// Maximal value for [ZLibCodec.memLevel] and [ZLibEncoder.memLevel].
  static const int maxMemLevel = 9;
  @Deprecated('Use maxMemLevel instead')
  static const int MAX_MEM_LEVEL = 9;

  /// Default value for [ZLibCodec.memLevel] and [ZLibEncoder.memLevel].
  static const int defaultMemLevel = 8;
  @Deprecated('Use defaultMemLevel instead')
  static const int DEFAULT_MEM_LEVEL = 8;

  /// Recommended strategy for data produced by a filter (or predictor)
  static const int strategyFiltered = 1;
  @Deprecated('Use strategyFiltered instead')
  static const int STRATEGY_FILTERED = 1;

  /// Use this strategy to force Huffman encoding only (no string match)
  static const int strategyHuffmanOnly = 2;
  @Deprecated('Use strategyHuffmanOnly instead')
  static const int STRATEGY_HUFFMAN_ONLY = 2;

  /// Use this strategy to limit match distances to one (run-length encoding)
  static const int strategyRle = 3;
  @Deprecated('Use strategyRle instead')
  static const int STRATEGY_RLE = 3;

  /// This strategy prevents the use of dynamic Huffman codes, allowing for a
  /// simpler decoder
  static const int strategyFixed = 4;
  @Deprecated('Use strategyFixed instead')
  static const int STRATEGY_FIXED = 4;

  /// Recommended strategy for normal data
  static const int strategyDefault = 0;
  @Deprecated('Use strategyDefault instead')
  static const int STRATEGY_DEFAULT = 0;
}
