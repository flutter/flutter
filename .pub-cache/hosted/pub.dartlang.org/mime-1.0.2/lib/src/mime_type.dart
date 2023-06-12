// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'default_extension_map.dart';
import 'magic_number.dart';

final MimeTypeResolver _globalResolver = MimeTypeResolver();

/// The maximum number of bytes needed, to match all default magic-numbers.
int get defaultMagicNumbersMaxLength => _globalResolver.magicNumbersMaxLength;

/// Extract the extension from [path] and use that for MIME-type lookup, using
/// the default extension map.
///
/// If no matching MIME-type was found, `null` is returned.
///
/// If [headerBytes] is present, a match for known magic-numbers will be
/// performed first. This allows the correct mime-type to be found, even though
/// a file have been saved using the wrong file-name extension. If less than
/// [defaultMagicNumbersMaxLength] bytes was provided, some magic-numbers won't
/// be matched against.
String? lookupMimeType(String path, {List<int>? headerBytes}) =>
    _globalResolver.lookup(path, headerBytes: headerBytes);

/// Returns the extension for the given MIME type.
///
/// If there are multiple extensions for [mime], return the first occurrence in
/// the map. If there are no extensions for [mime], return [mime].
String extensionFromMime(String mime) {
  mime = mime.toLowerCase();
  for (final entry in defaultExtensionMap.entries) {
    if (defaultExtensionMap[entry.key] == mime) {
      return entry.key;
    }
  }
  return mime;
}

/// MIME-type resolver class, used to customize the lookup of mime-types.
class MimeTypeResolver {
  final Map<String, String> _extensionMap = {};
  final List<MagicNumber> _magicNumbers = [];
  final bool _useDefault;
  int _magicNumbersMaxLength;

  /// Create a new empty [MimeTypeResolver].
  MimeTypeResolver.empty()
      : _useDefault = false,
        _magicNumbersMaxLength = 0;

  /// Create a new [MimeTypeResolver] containing the default scope.
  MimeTypeResolver()
      : _useDefault = true,
        _magicNumbersMaxLength = initialMagicNumbersMaxLength;

  /// Get the maximum number of bytes required to match all magic numbers, when
  /// performing [lookup] with headerBytes present.
  int get magicNumbersMaxLength => _magicNumbersMaxLength;

  /// Extract the extension from [path] and use that for MIME-type lookup.
  ///
  /// If no matching MIME-type was found, `null` is returned.
  ///
  /// If [headerBytes] is present, a match for known magic-numbers will be
  /// performed first. This allows the correct mime-type to be found, even
  /// though a file have been saved using the wrong file-name extension. If less
  /// than [magicNumbersMaxLength] bytes was provided, some magic-numbers won't
  /// be matched against.
  String? lookup(String path, {List<int>? headerBytes}) {
    String? result;
    if (headerBytes != null) {
      result = _matchMagic(headerBytes, _magicNumbers);
      if (result != null) return result;
      if (_useDefault) {
        result = _matchMagic(headerBytes, initialMagicNumbers);
        if (result != null) return result;
      }
    }
    var ext = _ext(path);
    result = _extensionMap[ext];
    if (result != null) return result;
    if (_useDefault) {
      result = defaultExtensionMap[ext];
      if (result != null) return result;
    }
    return null;
  }

  /// Add a new MIME-type mapping to the [MimeTypeResolver]. If the [extension]
  /// is already present in the [MimeTypeResolver], it'll be overwritten.
  void addExtension(String extension, String mimeType) {
    _extensionMap[extension] = mimeType;
  }

  /// Add a new magic-number mapping to the [MimeTypeResolver].
  ///
  /// If [mask] is present,the [mask] is used to only perform matching on
  /// selective bits. The [mask] must have the same length as [bytes].
  void addMagicNumber(List<int> bytes, String mimeType, {List<int>? mask}) {
    if (mask != null && bytes.length != mask.length) {
      throw ArgumentError('Bytes and mask are of different lengths');
    }
    if (bytes.length > _magicNumbersMaxLength) {
      _magicNumbersMaxLength = bytes.length;
    }
    _magicNumbers.add(MagicNumber(mimeType, bytes, mask: mask));
  }

  static String? _matchMagic(
      List<int> headerBytes, List<MagicNumber> magicNumbers) {
    for (var mn in magicNumbers) {
      if (mn.matches(headerBytes)) return mn.mimeType;
    }
    return null;
  }

  static String _ext(String path) {
    var index = path.lastIndexOf('.');
    if (index < 0 || index + 1 >= path.length) return path;
    return path.substring(index + 1).toLowerCase();
  }
}
