// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

/// Represents a media consisting of a stream of bytes, a content type and a
/// length.
class Media {
  final Stream<List<int>> stream;
  final String contentType;
  final int? length;

  /// Creates a new [Media] with a byte [stream] of length [length] with a
  /// [contentType].
  ///
  /// When uploading media, [length] can only be null if
  /// [ResumableUploadOptions] is used.
  Media(this.stream, this.length,
      {this.contentType = 'application/octet-stream'}) {
    if (length != null && length! < 0) {
      throw ArgumentError('A negative content length is not allowed');
    }
  }
}

/// Represents options for uploading a [Media].
class UploadOptions {
  /// Use either simple uploads (only media) or multipart for media+metadata
  static const UploadOptions defaultOptions = UploadOptions();

  /// Make resumable uploads
  static final ResumableUploadOptions resumable = ResumableUploadOptions();

  const UploadOptions();
}

/// Specifies options for resumable uploads.
class ResumableUploadOptions extends UploadOptions {
  static Duration? exponentialBackoff(int failedAttempts) {
    // Do not retry more than 5 times.
    if (failedAttempts > 5) return null;

    // Wait for 2^(failedAttempts-1) seconds, before retrying.
    // i.e. 1 second, 2 seconds, 4 seconds, ...
    return Duration(seconds: 1 << (failedAttempts - 1));
  }

  /// Maximum number of upload attempts per chunk.
  final int numberOfAttempts;

  /// Preferred size (in bytes) of a uploaded chunk.
  /// Must be a multiple of 256 KB.
  ///
  /// The default is 1 MB.
  final int chunkSize;

  /// Function for determining the [Duration] to wait before making the
  /// next attempt. See [exponentialBackoff] for an example.
  final Duration? Function(int) backoffFunction;

  ResumableUploadOptions({
    this.numberOfAttempts = 3,
    this.chunkSize = 1024 * 1024,
    this.backoffFunction = exponentialBackoff,
  }) {
    // See e.g. here:
    // https://developers.google.com/maps-engine/documentation/resumable-upload
    //
    // Chunk size restriction:
    // There are some chunk size restrictions based on the size of the file you
    // are uploading. Files larger than 256 KB (256 x 1024 bytes) must have
    // chunk sizes that are multiples of 256 KB. For files smaller than 256 KB,
    // there are no restrictions. In either case, the final chunk has no
    // limitations; you can simply transfer the remaining bytes. If you use
    // chunking, it is important to keep the chunk size as large as possible
    // to keep the upload efficient.
    //
    if (numberOfAttempts < 1) {
      throw ArgumentError.value(
        numberOfAttempts,
        'numberOfAttempts',
        'Must be >= 1.',
      );
    }

    const minChinkSize = 256 * 1024;

    if (chunkSize < 1 || (chunkSize % minChinkSize) != 0) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'Must be > 0 and a multiple of $minChinkSize.',
      );
    }
  }
}

/// Represents options for downloading media.
///
/// For partial downloads, see [PartialDownloadOptions].
class DownloadOptions {
  /// Download only metadata.
  // ignoring the non-standard name since we'd have to update the generator!
  static const DownloadOptions metadata = DownloadOptions();

  /// Download full media.
  // ignoring the non-standard name since we'd have to update the generator!
  static final PartialDownloadOptions fullMedia =
      PartialDownloadOptions(ByteRange(0, -1));

  const DownloadOptions();

  /// Indicates whether metadata should be downloaded.
  bool get isMetadataDownload => true;
}

/// Options for downloading a [Media].
class PartialDownloadOptions extends DownloadOptions {
  /// The range of bytes to be downloaded
  final ByteRange range;

  PartialDownloadOptions(this.range);

  @override
  bool get isMetadataDownload => false;

  /// `true` if this is a full download and `false` if this is a partial
  /// download.
  bool get isFullDownload => range.start == 0 && range.end == -1;
}

/// Specifies a range of media.
class ByteRange {
  /// First byte of media.
  final int start;

  /// Last byte of media (inclusive)
  final int end;

  /// Length of this range (i.e. number of bytes)
  int get length => end - start + 1;

  ByteRange(this.start, this.end) {
    if (!(start == 0 && end == -1 || start >= 0 && end >= start)) {
      throw ArgumentError('Invalid media range [$start, $end]');
    }
  }
}

/// Represents a general error reported by the API endpoint.
class ApiRequestError implements Exception {
  final String? message;

  ApiRequestError(this.message);

  @override
  String toString() => 'ApiRequestError(message: $message)';
}

/// Represents a specific error reported by the API endpoint.
class DetailedApiRequestError extends ApiRequestError {
  /// The error code. For some non-google services this can be `null`.
  final int? status;

  final List<ApiRequestErrorDetail> errors;

  /// The full error response as decoded json if available. `null` otherwise.
  final Map<String, dynamic>? jsonResponse;

  DetailedApiRequestError(this.status, String? message,
      {this.errors = const [], this.jsonResponse})
      : super(message);

  @override
  String toString() =>
      'DetailedApiRequestError(status: $status, message: $message)';
}

/// Instances of this class can be added to a [DetailedApiRequestError] to
/// provide detailed information.
///
/// This follows the Google JSON style guide:
/// https://google.github.io/styleguide/jsoncstyleguide.xml
class ApiRequestErrorDetail {
  /// Unique identifier for the service raising this error. This helps
  /// distinguish service-specific errors (i.e. error inserting an event in a
  /// calendar) from general protocol errors (i.e. file not found).
  final String? domain;

  /// Unique identifier for this error. Different from the
  /// [DetailedApiRequestError.status] property in that this is not an http
  /// response code.
  final String? reason;

  /// A human readable message providing more details about the error. If there
  /// is only one error, this field will match error.message.
  final String? message;

  /// The location of the error (the interpretation of its value depends on
  /// [locationType]).
  final String? location;

  /// Indicates how the [location] property should be interpreted.
  final String? locationType;

  /// A URI for a help text that might shed some more light on the error.
  final String? extendedHelp;

  /// A URI for a report form used by the service to collect data about the
  /// error condition. This URI should be preloaded with parameters describing
  /// the request.
  final String? sendReport;

  /// If this error detail gets created with the `.fromJson` constructor, the
  /// json will be accessible here.
  final Map? originalJson;

  ApiRequestErrorDetail({
    this.domain,
    this.reason,
    this.message,
    this.location,
    this.locationType,
    this.extendedHelp,
    this.sendReport,
  }) : originalJson = null;

  ApiRequestErrorDetail.fromJson(Map<dynamic, dynamic> this.originalJson)
      : domain = originalJson['domain'] as String?,
        reason = originalJson['reason'] as String?,
        message = originalJson['message'] as String?,
        location = originalJson['location'] as String?,
        locationType = originalJson['locationType'] as String?,
        extendedHelp = originalJson['extendedHelp'] as String?,
        sendReport = originalJson['sendReport'] as String?;
}
