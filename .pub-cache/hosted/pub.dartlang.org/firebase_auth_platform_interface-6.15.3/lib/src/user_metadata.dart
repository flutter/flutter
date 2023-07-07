// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Interface representing a user's metadata.
class UserMetadata {
  // ignore: public_member_api_docs
  @protected
  UserMetadata(this._creationTimestamp, this._lastSignInTime);

  final int? _creationTimestamp;
  final int? _lastSignInTime;

  /// When this account was created as dictated by the server clock.
  DateTime? get creationTime => _creationTimestamp == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_creationTimestamp!, isUtc: true);

  /// When the user last signed in as dictated by the server clock.
  ///
  /// This is only accurate up to a granularity of 2 minutes for consecutive
  /// sign-in attempts.
  DateTime? get lastSignInTime => _lastSignInTime == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_lastSignInTime!, isUtc: true);

  @override
  String toString() {
    return 'UserMetadata(creationTime: $creationTime, lastSignInTime: $lastSignInTime)';
  }
}
