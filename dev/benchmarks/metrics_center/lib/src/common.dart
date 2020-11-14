// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

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

/// Some common tag keys
const String kGithubRepoKey = 'gitRepo';
const String kGitRevisionKey = 'gitRevision';
const String kUnitKey = 'unit';
const String kNameKey = 'name';
const String kSubResultKey = 'subResult';

/// Known github repo
const String kFlutterFrameworkRepo = 'flutter/flutter';
const String kFlutterEngineRepo = 'flutter/engine';
