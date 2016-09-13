// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'base_request.dart';
import 'byte_stream.dart';
import 'multipart_file.dart';
import 'utils.dart';

final _newlineRegExp = new RegExp(r"\r\n|\r|\n");

/// A `multipart/form-data` request. Such a request has both string [fields],
/// which function as normal form fields, and (potentially streamed) binary
/// [files].
///
/// This request automatically sets the Content-Type header to
/// `multipart/form-data`. This value will override any value set by the user.
///
///     var uri = Uri.parse("http://pub.dartlang.org/packages/create");
///     var request = new http.MultipartRequest("POST", url);
///     request.fields['user'] = 'nweiz@google.com';
///     request.files.add(new http.MultipartFile.fromFile(
///         'package',
///         new File('build/package.tar.gz'),
///         contentType: new MediaType('application', 'x-tar'));
///     request.send().then((response) {
///       if (response.statusCode == 200) print("Uploaded!");
///     });
class MultipartRequest extends BaseRequest {
  /// The total length of the multipart boundaries used when building the
  /// request body. According to http://tools.ietf.org/html/rfc1341.html, this
  /// can't be longer than 70.
  static const int _BOUNDARY_LENGTH = 70;

  static final Random _random = new Random();

  /// The form fields to send for this request.
  final Map<String, String> fields;

  /// The private version of [files].
  final List<MultipartFile> _files;

  /// Creates a new [MultipartRequest].
  MultipartRequest(String method, Uri url)
    : fields = {},
      _files = <MultipartFile>[],
      super(method, url);

  /// The list of files to upload for this request.
  List<MultipartFile> get files => _files;

  /// The total length of the request body, in bytes. This is calculated from
  /// [fields] and [files] and cannot be set manually.
  int get contentLength {
    var length = 0;

    fields.forEach((name, value) {
      length += "--".length + _BOUNDARY_LENGTH + "\r\n".length +
          UTF8.encode(_headerForField(name, value)).length +
          UTF8.encode(value).length + "\r\n".length;
    });

    for (var file in _files) {
      length += "--".length + _BOUNDARY_LENGTH + "\r\n".length +
          UTF8.encode(_headerForFile(file)).length +
          file.length + "\r\n".length;
    }

    return length + "--".length + _BOUNDARY_LENGTH + "--\r\n".length;
  }

  void set contentLength(int value) {
    throw new UnsupportedError("Cannot set the contentLength property of "
        "multipart requests.");
  }

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  ByteStream finalize() {
    // TODO(nweiz): freeze fields and files
    var boundary = _boundaryString();
    headers['content-type'] = 'multipart/form-data; boundary="$boundary"';
    super.finalize();

    var controller = new StreamController<List<int>>(sync: true);

    void writeAscii(String string) {
      controller.add(UTF8.encode(string));
    }

    writeUtf8(String string) => controller.add(UTF8.encode(string));
    writeLine() => controller.add([13, 10]); // \r\n

    fields.forEach((name, value) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForField(name, value));
      writeUtf8(value);
      writeLine();
    });

    Future.forEach(_files, (file) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForFile(file));
      return writeStreamToSink(file.finalize(), controller)
        .then((_) => writeLine());
    }).then((_) {
      // TODO(nweiz): pass any errors propagated through this future on to
      // the stream. See issue 3657.
      writeAscii('--$boundary--\r\n');
      controller.close();
    });

    return new ByteStream(controller.stream);
  }

  /// All character codes that are valid in multipart boundaries. From
  /// http://tools.ietf.org/html/rfc2046#section-5.1.1.
  static const List<int> _BOUNDARY_CHARACTERS = const <int>[
    39, 40, 41, 43, 95, 44, 45, 46, 47, 58, 61, 63, 48, 49, 50, 51, 52, 53, 54,
    55, 56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
    81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103,
    104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118,
    119, 120, 121, 122
  ];

  /// Returns the header string for a field. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForField(String name, String value) {
    var header =
        'content-disposition: form-data; name="${_browserEncode(name)}"';
    if (!isPlainAscii(value)) {
      header = '$header\r\n'
          'content-type: text/plain; charset=utf-8\r\n'
          'content-transfer-encoding: binary';
    }
    return '$header\r\n\r\n';
  }

  /// Returns the header string for a file. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForFile(MultipartFile file) {
    var header = 'content-type: ${file.contentType}\r\n'
      'content-disposition: form-data; name="${_browserEncode(file.field)}"';

    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename)}"';
    }
    return '$header\r\n\r\n';
  }

  /// Encode [value] in the same way browsers do.
  String _browserEncode(String value) {
    // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
    // field names and file names, but in practice user agents seem not to
    // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
    // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
    // characters). We follow their behavior.
    return value.replaceAll(_newlineRegExp, "%0D%0A").replaceAll('"', "%22");
  }

  /// Returns a randomly-generated multipart boundary string
  String _boundaryString() {
    var prefix = "dart-http-boundary-";
    var list = new List<int>.generate(_BOUNDARY_LENGTH - prefix.length,
        (index) =>
            _BOUNDARY_CHARACTERS[_random.nextInt(_BOUNDARY_CHARACTERS.length)],
        growable: false);
    return "$prefix${new String.fromCharCodes(list)}";
  }
}
