// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// Open-ended set of encodings.
///
/// An encoding is a [Codec] encoding strings to lists of byte.
///
/// This class provides a default implementation of [decodeStream],
/// which is not incremental. It collects the entire input before
/// decoding. Subclasses can choose to use that implementation,
/// or implement a more efficient stream decoding.
abstract class Encoding extends Codec<String, List<int>> {
  const Encoding();

  /// Returns the encoder from `String` to `List<int>`.
  ///
  /// It may be stateful and should not be reused.
  Converter<String, List<int>> get encoder;

  /// Returns the decoder of `this`, converting from `List<int>` to `String`.
  ///
  /// It may be stateful and should not be reused.
  Converter<List<int>, String> get decoder;

  Future<String> decodeStream(Stream<List<int>> byteStream) {
    return decoder
        .bind(byteStream)
        .fold(StringBuffer(),
            (StringBuffer buffer, String string) => buffer..write(string))
        .then((StringBuffer buffer) => buffer.toString());
  }

  /// Name of the encoding.
  ///
  /// If the encoding is standardized, this is the lower-case version of one of
  /// the IANA official names for the character set (see
  /// http://www.iana.org/assignments/character-sets/character-sets.xml)
  String get name;

  // All aliases (in lowercase) of supported encoding from
  // http://www.iana.org/assignments/character-sets/character-sets.xml.
  static final Map<String, Encoding> _nameToEncoding = <String, Encoding>{
    // ISO_8859-1:1987.
    "iso_8859-1:1987": latin1,
    "iso-ir-100": latin1,
    "iso_8859-1": latin1,
    "iso-8859-1": latin1,
    "latin1": latin1,
    "l1": latin1,
    "ibm819": latin1,
    "cp819": latin1,
    "csisolatin1": latin1,

    // US-ASCII.
    "iso-ir-6": ascii,
    "ansi_x3.4-1968": ascii,
    "ansi_x3.4-1986": ascii,
    "iso_646.irv:1991": ascii,
    "iso646-us": ascii,
    "us-ascii": ascii,
    "us": ascii,
    "ibm367": ascii,
    "cp367": ascii,
    "csascii": ascii,
    "ascii": ascii, // This is not in the IANA official names.

    // UTF-8.
    "csutf8": utf8,
    "utf-8": utf8
  };

  /// Returns an [Encoding] for a named character set.
  ///
  /// The names used are the IANA official names for the character set (see
  /// [IANA character sets][]). The names are case insensitive.
  ///
  /// [IANA character sets]: http://www.iana.org/assignments/character-sets/character-sets.xml
  ///
  /// If character set is not supported `null` is returned.
  static Encoding? getByName(String? name) {
    if (name == null) return null;
    return _nameToEncoding[name.toLowerCase()];
  }
}
