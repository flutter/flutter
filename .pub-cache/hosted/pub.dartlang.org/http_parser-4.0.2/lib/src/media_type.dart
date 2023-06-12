// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:string_scanner/string_scanner.dart';

import 'case_insensitive_map.dart';
import 'scan.dart';
import 'utils.dart';

/// A regular expression matching a character that needs to be backslash-escaped
/// in a quoted string.
final _escapedChar = RegExp(r'["\x00-\x1F\x7F]');

/// A class representing an HTTP media type, as used in Accept and Content-Type
/// headers.
///
/// This is immutable; new instances can be created based on an old instance by
/// calling [change].
class MediaType {
  /// The primary identifier of the MIME type.
  ///
  /// This is always lowercase.
  final String type;

  /// The secondary identifier of the MIME type.
  ///
  /// This is always lowercase.
  final String subtype;

  /// The parameters to the media type.
  ///
  /// This map is immutable and the keys are case-insensitive.
  final Map<String, String> parameters;

  /// The media type's MIME type.
  String get mimeType => '$type/$subtype';

  /// Parses a media type.
  ///
  /// This will throw a FormatError if the media type is invalid.
  factory MediaType.parse(String mediaType) =>
      // This parsing is based on sections 3.6 and 3.7 of the HTTP spec:
      // http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html.
      wrapFormatException('media type', mediaType, () {
        final scanner = StringScanner(mediaType);
        scanner.scan(whitespace);
        scanner.expect(token);
        final type = scanner.lastMatch![0]!;
        scanner.expect('/');
        scanner.expect(token);
        final subtype = scanner.lastMatch![0]!;
        scanner.scan(whitespace);

        final parameters = <String, String>{};
        while (scanner.scan(';')) {
          scanner.scan(whitespace);
          scanner.expect(token);
          final attribute = scanner.lastMatch![0]!;
          scanner.expect('=');

          String value;
          if (scanner.scan(token)) {
            value = scanner.lastMatch![0]!;
          } else {
            value = expectQuotedString(scanner);
          }

          scanner.scan(whitespace);
          parameters[attribute] = value;
        }

        scanner.expectDone();
        return MediaType(type, subtype, parameters);
      });

  MediaType(String type, String subtype, [Map<String, String>? parameters])
      : type = type.toLowerCase(),
        subtype = subtype.toLowerCase(),
        parameters = UnmodifiableMapView(
            parameters == null ? {} : CaseInsensitiveMap.from(parameters));

  /// Returns a copy of this [MediaType] with some fields altered.
  ///
  /// [type] and [subtype] alter the corresponding fields. [mimeType] is parsed
  /// and alters both the [type] and [subtype] fields; it cannot be passed along
  /// with [type] or [subtype].
  ///
  /// [parameters] overwrites and adds to the corresponding field. If
  /// [clearParameters] is passed, it replaces the corresponding field entirely
  /// instead.
  MediaType change(
      {String? type,
      String? subtype,
      String? mimeType,
      Map<String, String>? parameters,
      bool clearParameters = false}) {
    if (mimeType != null) {
      if (type != null) {
        throw ArgumentError('You may not pass both [type] and [mimeType].');
      } else if (subtype != null) {
        throw ArgumentError('You may not pass both [subtype] and '
            '[mimeType].');
      }

      final segments = mimeType.split('/');
      if (segments.length != 2) {
        throw FormatException('Invalid mime type "$mimeType".');
      }

      type = segments[0];
      subtype = segments[1];
    }

    type ??= this.type;
    subtype ??= this.subtype;
    parameters ??= {};

    if (!clearParameters) {
      final newParameters = parameters;
      parameters = Map.from(this.parameters);
      parameters.addAll(newParameters);
    }

    return MediaType(type, subtype, parameters);
  }

  /// Converts the media type to a string.
  ///
  /// This will produce a valid HTTP media type.
  @override
  String toString() {
    final buffer = StringBuffer()
      ..write(type)
      ..write('/')
      ..write(subtype);

    parameters.forEach((attribute, value) {
      buffer.write('; $attribute=');
      if (nonToken.hasMatch(value)) {
        buffer
          ..write('"')
          ..write(
              value.replaceAllMapped(_escapedChar, (match) => '\\${match[0]}'))
          ..write('"');
      } else {
        buffer.write(value);
      }
    });

    return buffer.toString();
  }
}
