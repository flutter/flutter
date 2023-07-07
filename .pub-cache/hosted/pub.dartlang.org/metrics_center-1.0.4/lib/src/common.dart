// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';

/// Common format of a metric data point.
class MetricPoint extends Equatable {
  /// Creates a new data point.
  MetricPoint(
    this.value,
    Map<String, String?> tags,
  ) : _tags = SplayTreeMap<String, String>.from(tags);

  /// Can store integer values.
  final double? value;

  /// Test name, unit, timestamp, configs, git revision, ..., in sorted order.
  UnmodifiableMapView<String, String> get tags =>
      UnmodifiableMapView<String, String>(_tags);

  /// Unique identifier for updating existing data point.
  ///
  /// We shouldn't have to worry about hash collisions until we have about
  /// 2^128 points.
  ///
  /// This id should stay constant even if the [tags.keys] are reordered.
  /// (Because we are using an ordered SplayTreeMap to generate the id.)
  String get id => sha256.convert(utf8.encode('$_tags')).toString();

  @override
  String toString() {
    return 'MetricPoint(value=$value, tags=$_tags)';
  }

  final SplayTreeMap<String, String> _tags;

  @override
  List<Object?> get props => <Object?>[value, tags];
}

/// Interface to write [MetricPoint].
abstract class MetricDestination {
  /// Insert new data points or modify old ones with matching id.
  Future<void> update(
      List<MetricPoint> points, DateTime commitTime, String taskName);
}

/// Create `AuthClient` in case we only have an access token without the full
/// credentials json. It's currently the case for Chrmoium LUCI bots.
AuthClient authClientFromAccessToken(String token, List<String> scopes) {
  final DateTime anHourLater = DateTime.now().add(const Duration(hours: 1));
  final AccessToken accessToken =
      AccessToken('Bearer', token, anHourLater.toUtc());
  final AccessCredentials accessCredentials =
      AccessCredentials(accessToken, null, scopes);
  return authenticatedClient(Client(), accessCredentials);
}
