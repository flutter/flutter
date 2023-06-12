// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' show DetailedApiRequestError;
import 'package:googleapis_auth/auth_io.dart';

import 'common.dart';
import 'constants.dart';
import 'gcs_lock.dart';

/// A [MetricPoint] modeled after the format that Skia Perf expects.
///
/// Skia Perf Format is a JSON file that looks like:
/// ```json
/// {
///     "gitHash": "fe4a4029a080bc955e9588d05a6cd9eb490845d4",
///     "key": {
///         "arch": "x86",
///         "gpu": "GTX660",
///         "model": "ShuttleA",
///         "os": "Ubuntu12"
///     },
///     "results": {
///         "ChunkAlloc_PushPop_640_480": {
///             "nonrendering": {
///                 "min_ms": 0.01485466666666667,
///                 "options": {
///                     "source_type": "bench"
///                 }
///             }
///         },
///         "DeferredSurfaceCopy_discardable_640_480": {
///             "565": {
///                 "min_ms": 2.215988,
///                 "options": {
///                     "source_type": "bench"
///                 }
///             }
///         }
///      }
///   }
/// }
/// ```
class SkiaPerfPoint extends MetricPoint {
  SkiaPerfPoint._(this.githubRepo, this.gitHash, this.testName, this.subResult,
      double? value, this._options, this.jsonUrl)
      : assert(_options[kGithubRepoKey] == null),
        assert(_options[kGitRevisionKey] == null),
        assert(_options[kNameKey] == null),
        super(
          value,
          <String, String?>{}
            ..addAll(_options)
            ..addAll(<String, String?>{
              kGithubRepoKey: githubRepo,
              kGitRevisionKey: gitHash,
              kNameKey: testName,
              kSubResultKey: subResult,
            }),
        ) {
    assert(tags[kGithubRepoKey] != null);
    assert(tags[kGitRevisionKey] != null);
    assert(tags[kNameKey] != null);
  }

  /// Construct [SkiaPerfPoint] from a well-formed [MetricPoint].
  ///
  /// The [MetricPoint] must have [kGithubRepoKey], [kGitRevisionKey],
  /// [kNameKey] in its tags for this to be successful.
  ///
  /// If the [MetricPoint] has a tag 'date', that tag will be removed so Skia
  /// perf can plot multiple metrics with different date as a single trace.
  /// Skia perf will use the git revision's date instead of this date tag in
  /// the time axis.
  factory SkiaPerfPoint.fromPoint(MetricPoint p) {
    final String? githubRepo = p.tags[kGithubRepoKey];
    final String? gitHash = p.tags[kGitRevisionKey];
    final String? name = p.tags[kNameKey];

    if (githubRepo == null || gitHash == null || name == null) {
      throw '$kGithubRepoKey, $kGitRevisionKey, $kNameKey must be set in'
          ' the tags of $p.';
    }

    final String subResult = p.tags[kSubResultKey] ?? kSkiaPerfValueKey;

    final Map<String, String> options = <String, String>{}..addEntries(
        p.tags.entries.where(
          (MapEntry<String, dynamic> entry) =>
              entry.key != kGithubRepoKey &&
              entry.key != kGitRevisionKey &&
              entry.key != kNameKey &&
              entry.key != kSubResultKey &&
              // https://github.com/google/benchmark automatically generates a
              // 'date' field. If it's included in options, the Skia perf won't
              // be able to connect different points in a single trace because
              // the date is always different.
              entry.key != 'date',
        ),
      );

    return SkiaPerfPoint._(
        githubRepo, gitHash, name, subResult, p.value, options, null);
  }

  /// In the format of '<owner>/<name>' such as 'flutter/flutter' or
  /// 'flutter/engine'.
  final String githubRepo;

  /// SHA such as 'ad20d368ffa09559754e4b2b5c12951341ca3b2d'
  final String? gitHash;

  /// For Flutter devicelab, this is the task name (e.g.,
  /// 'flutter_gallery__transition_perf'); for Google benchmark, this is the
  /// benchmark name (e.g., 'BM_ShellShutdown').
  ///
  /// In Skia perf web dashboard, this value can be queried and filtered by
  /// "test".
  final String testName;

  /// The name of "subResult" comes from the special treatment of "sub_result"
  /// in SkiaPerf. If not provided, its value will be set to kSkiaPerfValueKey.
  ///
  /// When Google benchmarks are converted to SkiaPerfPoint, this subResult
  /// could be "cpu_time" or "real_time".
  ///
  /// When devicelab benchmarks are converted to SkiaPerfPoint, this subResult
  /// is often the metric name such as "average_frame_build_time_millis" whereas
  /// the [testName] is the benchmark or task name such as
  /// "flutter_gallery__transition_perf".
  final String subResult;

  /// The url to the Skia perf json file in the Google Cloud Storage bucket.
  ///
  /// This can be null if the point has been stored in the bucket yet.
  final String? jsonUrl;

  Map<String, dynamic> _toSubResultJson() {
    return <String, dynamic>{
      subResult: value,
      kSkiaPerfOptionsKey: _options,
    };
  }

  /// Convert a list of SkiaPoints with the same git repo and git revision into
  /// a single json file in the Skia perf format.
  ///
  /// The list must be non-empty.
  static Map<String, dynamic> toSkiaPerfJson(List<SkiaPerfPoint> points) {
    assert(points.isNotEmpty);
    assert(() {
      for (final SkiaPerfPoint p in points) {
        if (p.githubRepo != points[0].githubRepo ||
            p.gitHash != points[0].gitHash) {
          return false;
        }
      }
      return true;
    }(), 'All points must have same githubRepo and gitHash');

    final Map<String, dynamic> results = <String, dynamic>{};
    for (final SkiaPerfPoint p in points) {
      final Map<String, dynamic> subResultJson = p._toSubResultJson();
      if (results[p.testName] == null) {
        results[p.testName] = <String, dynamic>{
          kSkiaPerfDefaultConfig: subResultJson,
        };
      } else {
        // Flutter currently doesn't support having the same name but different
        // options/configurations. If this actually happens in the future, we
        // probably can use different values of config (currently there's only
        // one kSkiaPerfDefaultConfig) to resolve the conflict.
        assert(results[p.testName][kSkiaPerfDefaultConfig][kSkiaPerfOptionsKey]
                .toString() ==
            subResultJson[kSkiaPerfOptionsKey].toString());
        assert(
            results[p.testName][kSkiaPerfDefaultConfig][p.subResult] == null);
        results[p.testName][kSkiaPerfDefaultConfig][p.subResult] = p.value;
      }
    }

    return <String, dynamic>{
      kSkiaPerfGitHashKey: points[0].gitHash,
      kSkiaPerfResultsKey: results,
    };
  }

  // Equivalent to tags without git repo, git hash, and name because those two
  // are already stored somewhere else.
  final Map<String, String> _options;
}

/// Handle writing and updates of Skia perf GCS buckets.
class SkiaPerfGcsAdaptor {
  /// Construct the adaptor given the associated GCS bucket where the data is
  /// read from and written to.
  SkiaPerfGcsAdaptor(this._gcsBucket) : assert(_gcsBucket != null);

  /// Used by Skia to differentiate json file format versions.
  static const int version = 1;

  /// Write a list of SkiaPerfPoint into a GCS file with name `objectName` in
  /// the proper json format that's understandable by Skia perf services.
  ///
  /// The `objectName` must be a properly formatted string returned by
  /// [computeObjectName].
  ///
  /// The read may retry multiple times if transient network errors with code
  /// 504 happens.
  Future<void> writePoints(
      String objectName, List<SkiaPerfPoint> points) async {
    final String jsonString = jsonEncode(SkiaPerfPoint.toSkiaPerfJson(points));
    final List<int> content = utf8.encode(jsonString);

    // Retry multiple times as GCS may return 504 timeout.
    for (int retry = 0; retry < 5; retry += 1) {
      try {
        await _gcsBucket.writeBytes(objectName, content);
        return;
      } catch (e) {
        if (e is DetailedApiRequestError && e.status == 504) {
          continue;
        }
        rethrow;
      }
    }
    // Retry one last time and let the exception go through.
    await _gcsBucket.writeBytes(objectName, content);
  }

  /// Read a list of `SkiaPerfPoint` that have been previously written to the
  /// GCS file with name `objectName`.
  ///
  /// The Github repo and revision of those points will be inferred from the
  /// `objectName`.
  ///
  /// Return an empty list if the object does not exist in the GCS bucket.
  ///
  /// The read may retry multiple times if transient network errors with code
  /// 504 happens.
  Future<List<SkiaPerfPoint>> readPoints(String objectName) async {
    // Retry multiple times as GCS may return 504 timeout.
    for (int retry = 0; retry < 5; retry += 1) {
      try {
        return await _readPointsWithoutRetry(objectName);
      } catch (e) {
        if (e is DetailedApiRequestError && e.status == 504) {
          continue;
        }
        rethrow;
      }
    }
    // Retry one last time and let the exception go through.
    return _readPointsWithoutRetry(objectName);
  }

  Future<List<SkiaPerfPoint>> _readPointsWithoutRetry(String objectName) async {
    ObjectInfo? info;

    try {
      info = await _gcsBucket.info(objectName);
    } catch (e) {
      if (e.toString().contains('No such object')) {
        return <SkiaPerfPoint>[];
      } else {
        rethrow;
      }
    }

    final Stream<List<int>> stream = _gcsBucket.read(objectName);
    final Stream<int> byteStream = stream.expand((List<int> x) => x);
    final Map<String, dynamic> decodedJson =
        jsonDecode(utf8.decode(await byteStream.toList()))
            as Map<String, dynamic>;

    final List<SkiaPerfPoint> points = <SkiaPerfPoint>[];

    final String firstGcsNameComponent = objectName.split('/')[0];
    _populateGcsNameToGithubRepoMapIfNeeded();
    final String githubRepo = _gcsNameToGithubRepo[firstGcsNameComponent]!;
    assert(githubRepo != null);

    final String? gitHash = decodedJson[kSkiaPerfGitHashKey] as String?;
    final Map<String, dynamic> results =
        decodedJson[kSkiaPerfResultsKey] as Map<String, dynamic>;
    for (final String name in results.keys) {
      final Map<String, dynamic> subResultMap =
          results[name][kSkiaPerfDefaultConfig] as Map<String, dynamic>;
      for (final String subResult
          in subResultMap.keys.where((String s) => s != kSkiaPerfOptionsKey)) {
        points.add(SkiaPerfPoint._(
          githubRepo,
          gitHash,
          name,
          subResult,
          subResultMap[subResult] as double?,
          (subResultMap[kSkiaPerfOptionsKey] as Map<String, dynamic>)
              .cast<String, String>(),
          info.downloadLink.toString(),
        ));
      }
    }
    return points;
  }

  /// Compute the GCS file name that's used to store metrics for a given commit
  /// (git revision).
  ///
  /// Skia perf needs all directory names to be well formatted. The final name
  /// of the json file can be arbitrary, and multiple json files can be put
  /// in that leaf directory. We are using multiple json files divided by test
  /// names to scale up the system to avoid too many writes competing for
  /// the same json file.
  static Future<String> computeObjectName(String githubRepo, String? revision,
      DateTime commitTime, String taskName) async {
    assert(_githubRepoToGcsName[githubRepo] != null);
    final String? topComponent = _githubRepoToGcsName[githubRepo];
    // [commitTime] is not guranteed to be UTC. Ensure it is so all results
    // pushed to GCS are the same timezone.
    final DateTime commitUtcTime = commitTime.toUtc();
    final String month = commitUtcTime.month.toString().padLeft(2, '0');
    final String day = commitUtcTime.day.toString().padLeft(2, '0');
    final String hour = commitUtcTime.hour.toString().padLeft(2, '0');
    final String dateComponents = '${commitUtcTime.year}/$month/$day/$hour';
    return '$topComponent/$dateComponents/$revision/${taskName}_values.json';
  }

  static final Map<String, String> _githubRepoToGcsName = <String, String>{
    kFlutterFrameworkRepo: 'flutter-flutter',
    kFlutterEngineRepo: 'flutter-engine',
  };
  static final Map<String?, String> _gcsNameToGithubRepo = <String?, String>{};

  static void _populateGcsNameToGithubRepoMapIfNeeded() {
    if (_gcsNameToGithubRepo.isEmpty) {
      for (final String repo in _githubRepoToGcsName.keys) {
        final String? gcsName = _githubRepoToGcsName[repo];
        assert(_gcsNameToGithubRepo[gcsName] == null);
        _gcsNameToGithubRepo[gcsName] = repo;
      }
    }
  }

  final Bucket _gcsBucket;
}

/// A [MetricDestination] that conforms to Skia Perf's protocols.
class SkiaPerfDestination extends MetricDestination {
  /// Creates a new [SkiaPerfDestination].
  SkiaPerfDestination(this._gcs, this._lock);

  /// Create from a full credentials json (of a service account).
  static Future<SkiaPerfDestination> makeFromGcpCredentials(
      Map<String, dynamic> credentialsJson,
      {bool isTesting = false}) async {
    final AutoRefreshingAuthClient client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(credentialsJson), Storage.SCOPES);
    return make(
      client,
      credentialsJson[kProjectId] as String,
      isTesting: isTesting,
    );
  }

  /// Create from an access token and its project id.
  static Future<SkiaPerfDestination> makeFromAccessToken(
      String token, String projectId,
      {bool isTesting = false}) async {
    final AuthClient client = authClientFromAccessToken(token, Storage.SCOPES);
    return make(client, projectId, isTesting: isTesting);
  }

  /// Create from an [AuthClient] and a GCP project id.
  ///
  /// [AuthClient] can be obtained from functions like `clientViaUserConsent`.
  static Future<SkiaPerfDestination> make(AuthClient client, String projectId,
      {bool isTesting = false}) async {
    final Storage storage = Storage(client, projectId);
    final String bucketName = isTesting ? kTestBucketName : kBucketName;
    if (!await storage.bucketExists(bucketName)) {
      throw 'Bucket $bucketName does not exist.';
    }
    final SkiaPerfGcsAdaptor adaptor =
        SkiaPerfGcsAdaptor(storage.bucket(bucketName));
    final GcsLock lock = GcsLock(client, bucketName);
    return SkiaPerfDestination(adaptor, lock);
  }

  @override
  Future<void> update(
      List<MetricPoint> points, DateTime commitTime, String taskName) async {
    // 1st, create a map based on git repo, git revision, and point id. Git repo
    // and git revision are the top level components of the Skia perf GCS object
    // name.
    final Map<String, Map<String?, Map<String, SkiaPerfPoint>>> pointMap =
        <String, Map<String, Map<String, SkiaPerfPoint>>>{};
    for (final SkiaPerfPoint p
        in points.map((MetricPoint x) => SkiaPerfPoint.fromPoint(x))) {
      if (p != null) {
        pointMap[p.githubRepo] ??= <String, Map<String, SkiaPerfPoint>>{};
        pointMap[p.githubRepo]![p.gitHash] ??= <String, SkiaPerfPoint>{};
        pointMap[p.githubRepo]![p.gitHash]![p.id] = p;
      }
    }

    // All created locks must be released before returning
    final List<Future<void>> lockFutures = <Future<void>>[];

    // 2nd, read existing points from the gcs object and update with new ones.
    for (final String repo in pointMap.keys) {
      for (final String? revision in pointMap[repo]!.keys) {
        final String objectName = await SkiaPerfGcsAdaptor.computeObjectName(
            repo, revision, commitTime, taskName);
        final Map<String, SkiaPerfPoint>? newPoints = pointMap[repo]![revision];
        // Too many bots writing the metrics of a git revision into a single json
        // file will cause high contention on the lock. We use multiple
        // json files according to task names. Skia perf read all json files in
        // the directory so one can use arbitrary names for those sharded json
        // file names.
        lockFutures.add(
          _lock!.protectedRun('$objectName.lock', () async {
            final List<SkiaPerfPoint> oldPoints =
                await _gcs.readPoints(objectName);
            for (final SkiaPerfPoint p in oldPoints) {
              if (newPoints![p.id] == null) {
                newPoints[p.id] = p;
              }
            }
            await _gcs.writePoints(objectName, newPoints!.values.toList());
          }),
        );
      }
    }
    await Future.wait(lockFutures);
  }

  final SkiaPerfGcsAdaptor _gcs;
  late final GcsLock? _lock;
}
