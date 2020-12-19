// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

/// Common format of a metric data point.
class MetricPoint extends Equatable {
  MetricPoint(
    this.value,
    Map<String, String> tags,
  ) : _tags = SplayTreeMap<String, String>.from(tags);

  /// Can store integer values.
  final double value;

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
  List<Object> get props => <Object>[value, tags];
}

/// Interface to write [MetricPoint].
abstract class MetricDestination {
  /// Insert new data points or modify old ones with matching id.
  Future<void> update(List<MetricPoint> points);
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

/// Some common tag keys
const String kGithubRepoKey = 'gitRepo';
const String kGitRevisionKey = 'gitRevision';
const String kUnitKey = 'unit';
const String kNameKey = 'name';
const String kSubResultKey = 'subResult';

/// Known github repo
const String kFlutterFrameworkRepo = 'flutter/flutter';
const String kFlutterEngineRepo = 'flutter/engine';

/// The key for the GCP project id in the credentials json.
const String kProjectId = 'project_id';
