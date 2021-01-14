// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(liyuqian): Remove this legacy file once the migration is fully done.
// See go/flutter-metrics-center-migration for detailed plans.
import 'dart:convert';
import 'dart:math';

import 'package:gcloud/db.dart';

import 'common.dart';
import 'legacy_datastore.dart';

const String kSourceTimeMicrosName = 'sourceTimeMicros';

// The size of 500 is currently limited by Google datastore. It cannot write
// more than 500 entities in a single call.
const int kMaxBatchSize = 500;

/// This model corresponds to the existing data model 'MetricPoint' used in the
/// flutter-cirrus GCP project.
///
/// The originId and sourceTimeMicros fields are no longer used but we are still
/// providing valid values to them so it's compatible with old code and services
/// during the migration.
@Kind(name: 'MetricPoint', idType: IdType.String)
class LegacyMetricPointModel extends Model<String> {
  LegacyMetricPointModel({MetricPoint fromMetricPoint}) {
    if (fromMetricPoint != null) {
      id = fromMetricPoint.id;
      value = fromMetricPoint.value;
      originId = 'legacy-flutter';
      sourceTimeMicros = null;
      tags = fromMetricPoint.tags.keys
          .map((String key) =>
              jsonEncode(<String, dynamic>{key: fromMetricPoint.tags[key]}))
          .toList();
    }
  }

  @DoubleProperty(required: true, indexed: false)
  double value;

  @StringListProperty()
  List<String> tags;

  @StringProperty(required: true)
  String originId;

  @IntProperty(propertyName: kSourceTimeMicrosName)
  int sourceTimeMicros;
}

class LegacyFlutterDestination extends MetricDestination {
  LegacyFlutterDestination(this._db);

  static Future<LegacyFlutterDestination> makeFromCredentialsJson(
      Map<String, dynamic> json) async {
    return LegacyFlutterDestination(await datastoreFromCredentialsJson(json));
  }

  static LegacyFlutterDestination makeFromAccessToken(
      String accessToken, String projectId) {
    return LegacyFlutterDestination(
        datastoreFromAccessToken(accessToken, projectId));
  }

  @override
  Future<void> update(List<MetricPoint> points) async {
    final List<LegacyMetricPointModel> flutterCenterPoints =
        points.map((MetricPoint p) => LegacyMetricPointModel(fromMetricPoint: p)).toList();

    for (int start = 0; start < points.length; start += kMaxBatchSize) {
      final int end = min(start + kMaxBatchSize, points.length);
      await _db.withTransaction((Transaction tx) async {
        tx.queueMutations(inserts: flutterCenterPoints.sublist(start, end));
        await tx.commit();
      });
    }
  }

  final DatastoreDB _db;
}
