// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// No longer used. Replaced by [ServerRequestFailedException].
@Deprecated('No longer used. Replaced by ServerRequestFailedException.')
typedef RefreshFailedException = ServerRequestFailedException;

/// Thrown if an attempt to make an authorized request failed.
class AccessDeniedException implements Exception {
  final String message;

  AccessDeniedException(this.message);

  @override
  String toString() => message;
}

/// Thrown if user did not give his consent.
class UserConsentException implements Exception {
  final String message;

  final String? details;

  UserConsentException(this.message, {this.details});

  @override
  String toString() => [message, if (details != null) details].join(' ');
}

/// Thrown when a request to or the response from an authentication service is
/// invalid.
///
/// This could indicate invalid credentials.
class ServerRequestFailedException implements Exception {
  /// Describes the failure.
  final String message;

  /// The HTTP status code of the response, if known.
  ///
  /// If `null`, the status code was likely `200` and there was another issue
  /// with the response.
  final int? statusCode;

  /// Data representing the content of the response, if any.
  ///
  /// This may be a [String] representing the raw content of the response or
  /// the a parsed JSON literal of the content.
  final Object? responseContent;

  ServerRequestFailedException(
    this.message, {
    this.statusCode,
    required this.responseContent,
  });

  @override
  String toString() =>
      [message, if (statusCode != null) 'Status code: $statusCode'].join(' ');
}
