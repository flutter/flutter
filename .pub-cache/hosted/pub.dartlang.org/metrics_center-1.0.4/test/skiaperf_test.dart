// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(seconds: 3600))

import 'dart:async';
import 'dart:convert';

import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' show DetailedApiRequestError;
import 'package:googleapis_auth/auth_io.dart';
import 'package:metrics_center/metrics_center.dart';
import 'package:metrics_center/src/gcs_lock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'common.dart';
import 'skiaperf_test.mocks.dart';
import 'utility.dart';

class MockGcsLock implements GcsLock {
  @override
  Future<void> protectedRun(
      String exclusiveObjectName, Future<void> Function() f) async {
    await f();
  }
}

class MockSkiaPerfGcsAdaptor implements SkiaPerfGcsAdaptor {
  MockSkiaPerfGcsAdaptor({
    this.writePointsOverride,
  });

  final Future<void> Function()? writePointsOverride;

  @override
  Future<List<SkiaPerfPoint>> readPoints(String objectName) async {
    return _storage[objectName] ?? <SkiaPerfPoint>[];
  }

  @override
  Future<void> writePoints(
      String objectName, List<SkiaPerfPoint> points) async {
    if (writePointsOverride != null) {
      return writePointsOverride!();
    }
    _storage[objectName] = points.toList();
  }

  // Map from the object name to the list of SkiaPoint that mocks the GCS.
  final Map<String, List<SkiaPerfPoint>> _storage =
      <String, List<SkiaPerfPoint>>{};
}

@GenerateMocks(<Type>[Bucket, ObjectInfo])
Future<void> main() async {
  const double kValue1 = 1.0;
  const double kValue2 = 2.0;
  const double kValue3 = 3.0;

  const String kFrameworkRevision1 = '9011cece2595447eea5dd91adaa241c1c9ef9a33';
  const String kFrameworkRevision2 = '372fe290e4d4f3f97cbf02a57d235771a9412f10';
  const String kEngineRevision1 = '617938024315e205f26ed72ff0f0647775fa6a71';
  const String kEngineRevision2 = '5858519139c22484aaff1cf5b26bdf7951259344';
  const String kTaskName = 'analyzer_benchmark';
  const String kMetric1 = 'flutter_repo_batch_maximum';
  const String kMetric2 = 'flutter_repo_watch_maximum';

  final MetricPoint cocoonPointRev1Metric1 = MetricPoint(
    kValue1,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: kTaskName,
      kSubResultKey: kMetric1,
      kUnitKey: 's',
    },
  );

  final MetricPoint cocoonPointRev1Metric2 = MetricPoint(
    kValue2,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: kTaskName,
      kSubResultKey: kMetric2,
      kUnitKey: 's',
    },
  );

  final MetricPoint cocoonPointRev2Metric1 = MetricPoint(
    kValue3,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision2,
      kNameKey: kTaskName,
      kSubResultKey: kMetric1,
      kUnitKey: 's',
    },
  );

  final MetricPoint cocoonPointBetaRev1Metric1 = MetricPoint(
    kValue1,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: 'beta/$kTaskName',
      kSubResultKey: kMetric1,
      kUnitKey: 's',
      'branch': 'beta',
    },
  );

  final MetricPoint cocoonPointBetaRev1Metric1BadBranch = MetricPoint(
    kValue1,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: kTaskName,
      kSubResultKey: kMetric1,
      kUnitKey: 's',

      // If we only add this 'branch' tag without changing the test or sub-result name, an exception
      // would be thrown as Skia Perf currently only supports the same set of tags for a pair of
      // kNameKey and kSubResultKey values. So to support branches, one also has to add the branch
      // name to the test name.
      'branch': 'beta',
    },
  );

  const String engineMetricName = 'BM_PaintRecordInit';
  const String engineRevision = 'ca799fa8b2254d09664b78ee80c43b434788d112';
  const double engineValue1 = 101;
  const double engineValue2 = 102;

  final FlutterEngineMetricPoint enginePoint1 = FlutterEngineMetricPoint(
    engineMetricName,
    engineValue1,
    engineRevision,
    moreTags: const <String, String>{
      kSubResultKey: 'cpu_time',
      kUnitKey: 'ns',
      'date': '2019-12-17 15:14:14',
      'num_cpus': '56',
      'mhz_per_cpu': '2594',
      'cpu_scaling_enabled': 'true',
      'library_build_type': 'release',
    },
  );

  final FlutterEngineMetricPoint enginePoint2 = FlutterEngineMetricPoint(
    engineMetricName,
    engineValue2,
    engineRevision,
    moreTags: const <String, String>{
      kSubResultKey: 'real_time',
      kUnitKey: 'ns',
      'date': '2019-12-17 15:14:14',
      'num_cpus': '56',
      'mhz_per_cpu': '2594',
      'cpu_scaling_enabled': 'true',
      'library_build_type': 'release',
    },
  );

  test('Throw if invalid points are converted to SkiaPoint', () {
    final MetricPoint noGithubRepoPoint = MetricPoint(
      kValue1,
      const <String, String>{
        kGitRevisionKey: kFrameworkRevision1,
        kNameKey: kTaskName,
      },
    );

    final MetricPoint noGitRevisionPoint = MetricPoint(
      kValue1,
      const <String, String>{
        kGithubRepoKey: kFlutterFrameworkRepo,
        kNameKey: kTaskName,
      },
    );

    final MetricPoint noTestNamePoint = MetricPoint(
      kValue1,
      const <String, String>{
        kGithubRepoKey: kFlutterFrameworkRepo,
        kGitRevisionKey: kFrameworkRevision1,
      },
    );

    expect(() => SkiaPerfPoint.fromPoint(noGithubRepoPoint), throwsA(anything));
    expect(
        () => SkiaPerfPoint.fromPoint(noGitRevisionPoint), throwsA(anything));
    expect(() => SkiaPerfPoint.fromPoint(noTestNamePoint), throwsA(anything));
  });

  test('Correctly convert a metric point from cocoon to SkiaPoint', () {
    final SkiaPerfPoint skiaPoint1 =
        SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1);
    expect(skiaPoint1, isNotNull);
    expect(skiaPoint1.testName, equals(kTaskName));
    expect(skiaPoint1.subResult, equals(kMetric1));
    expect(skiaPoint1.value, equals(cocoonPointRev1Metric1.value));
    expect(skiaPoint1.jsonUrl, isNull); // Not inserted yet
  });

  test('Cocoon points correctly encode into Skia perf json format', () {
    final SkiaPerfPoint p1 = SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1);
    final SkiaPerfPoint p2 = SkiaPerfPoint.fromPoint(cocoonPointRev1Metric2);
    final SkiaPerfPoint p3 =
        SkiaPerfPoint.fromPoint(cocoonPointBetaRev1Metric1);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    expect(
        encoder
            .convert(SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[p1, p2, p3])),
        equals('''
{
  "gitHash": "9011cece2595447eea5dd91adaa241c1c9ef9a33",
  "results": {
    "analyzer_benchmark": {
      "default": {
        "flutter_repo_batch_maximum": 1.0,
        "options": {
          "unit": "s"
        },
        "flutter_repo_watch_maximum": 2.0
      }
    },
    "beta/analyzer_benchmark": {
      "default": {
        "flutter_repo_batch_maximum": 1.0,
        "options": {
          "branch": "beta",
          "unit": "s"
        }
      }
    }
  }
}'''));
  });

  test('Engine metric points correctly encode into Skia perf json format', () {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    expect(
      encoder.convert(SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[
        SkiaPerfPoint.fromPoint(enginePoint1),
        SkiaPerfPoint.fromPoint(enginePoint2),
      ])),
      equals(
        '''
{
  "gitHash": "ca799fa8b2254d09664b78ee80c43b434788d112",
  "results": {
    "BM_PaintRecordInit": {
      "default": {
        "cpu_time": 101.0,
        "options": {
          "cpu_scaling_enabled": "true",
          "library_build_type": "release",
          "mhz_per_cpu": "2594",
          "num_cpus": "56",
          "unit": "ns"
        },
        "real_time": 102.0
      }
    }
  }
}''',
      ),
    );
  });

  test(
      'Throw if engine points with the same test name but different options are converted to '
      'Skia perf points', () {
    final FlutterEngineMetricPoint enginePoint1 = FlutterEngineMetricPoint(
      'BM_PaintRecordInit',
      101,
      'ca799fa8b2254d09664b78ee80c43b434788d112',
      moreTags: const <String, String>{
        kSubResultKey: 'cpu_time',
        kUnitKey: 'ns',
        'cpu_scaling_enabled': 'true',
      },
    );
    final FlutterEngineMetricPoint enginePoint2 = FlutterEngineMetricPoint(
      'BM_PaintRecordInit',
      102,
      'ca799fa8b2254d09664b78ee80c43b434788d112',
      moreTags: const <String, String>{
        kSubResultKey: 'real_time',
        kUnitKey: 'ns',
        'cpu_scaling_enabled': 'false',
      },
    );

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    expect(
      () => encoder.convert(SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[
        SkiaPerfPoint.fromPoint(enginePoint1),
        SkiaPerfPoint.fromPoint(enginePoint2),
      ])),
      throwsA(anything),
    );
  });

  test(
      'Throw if two Cocoon metric points with the same name and subResult keys '
      'but different options are converted to Skia perf points', () {
    final SkiaPerfPoint p1 = SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1);
    final SkiaPerfPoint p2 =
        SkiaPerfPoint.fromPoint(cocoonPointBetaRev1Metric1BadBranch);

    expect(
      () => SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[p1, p2]),
      throwsA(anything),
    );
  });

  test('SkiaPerfGcsAdaptor computes name correctly', () async {
    expect(
      await SkiaPerfGcsAdaptor.computeObjectName(
        kFlutterFrameworkRepo,
        kFrameworkRevision1,
        DateTime.utc(2019, 12, 04, 23),
        'test',
      ),
      equals(
          'flutter-flutter/2019/12/04/23/$kFrameworkRevision1/test_values.json'),
    );
    expect(
      await SkiaPerfGcsAdaptor.computeObjectName(
        kFlutterEngineRepo,
        kEngineRevision1,
        DateTime.utc(2019, 12, 03, 20),
        'test',
      ),
      equals('flutter-engine/2019/12/03/20/$kEngineRevision1/test_values.json'),
    );
    expect(
      await SkiaPerfGcsAdaptor.computeObjectName(
        kFlutterEngineRepo,
        kEngineRevision2,
        DateTime.utc(2020, 01, 03, 15),
        'test',
      ),
      equals('flutter-engine/2020/01/03/15/$kEngineRevision2/test_values.json'),
    );
  });

  test('Successfully read mock GCS that fails 1st time with 504', () async {
    final MockBucket testBucket = MockBucket();
    final SkiaPerfGcsAdaptor skiaPerfGcs = SkiaPerfGcsAdaptor(testBucket);

    final String testObjectName = await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterFrameworkRepo,
      kFrameworkRevision1,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );

    final List<SkiaPerfPoint> writePoints = <SkiaPerfPoint>[
      SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1),
    ];
    final String skiaPerfJson =
        jsonEncode(SkiaPerfPoint.toSkiaPerfJson(writePoints));
    when(testBucket.writeBytes(testObjectName, utf8.encode(skiaPerfJson)))
        .thenAnswer((_) async => FakeObjectInfo());
    await skiaPerfGcs.writePoints(testObjectName, writePoints);
    verify(testBucket.writeBytes(testObjectName, utf8.encode(skiaPerfJson)));

    // Emulate the first network request to fail with 504.
    when(testBucket.info(testObjectName))
        .thenThrow(DetailedApiRequestError(504, 'Test Failure'));

    final MockObjectInfo mockObjectInfo = MockObjectInfo();
    when(mockObjectInfo.downloadLink)
        .thenReturn(Uri.https('test.com', 'mock.json'));
    when(testBucket.info(testObjectName))
        .thenAnswer((_) => Future<ObjectInfo>.value(mockObjectInfo));
    when(testBucket.read(testObjectName))
        .thenAnswer((_) => Stream<List<int>>.value(utf8.encode(skiaPerfJson)));

    final List<SkiaPerfPoint> readPoints =
        await skiaPerfGcs.readPoints(testObjectName);
    expect(readPoints.length, equals(1));
    expect(readPoints[0].testName, kTaskName);
    expect(readPoints[0].subResult, kMetric1);
    expect(readPoints[0].value, kValue1);
    expect(readPoints[0].githubRepo, kFlutterFrameworkRepo);
    expect(readPoints[0].gitHash, kFrameworkRevision1);
    expect(readPoints[0].jsonUrl, 'https://test.com/mock.json');
  });

  test('Return empty list if the GCS file does not exist', () async {
    final MockBucket testBucket = MockBucket();
    final SkiaPerfGcsAdaptor skiaPerfGcs = SkiaPerfGcsAdaptor(testBucket);
    final String testObjectName = await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterFrameworkRepo,
      kFrameworkRevision1,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );
    when(testBucket.info(testObjectName))
        .thenThrow(Exception('No such object'));
    expect((await skiaPerfGcs.readPoints(testObjectName)).length, 0);
  });

  // The following is for integration tests.
  Bucket? testBucket;
  GcsLock? testLock;
  final Map<String, dynamic>? credentialsJson = getTestGcpCredentialsJson();
  if (credentialsJson != null) {
    final ServiceAccountCredentials credentials =
        ServiceAccountCredentials.fromJson(credentialsJson);

    final AutoRefreshingAuthClient client =
        await clientViaServiceAccount(credentials, Storage.SCOPES);
    final Storage storage =
        Storage(client, credentialsJson['project_id'] as String);

    const String kTestBucketName = 'flutter-skia-perf-test';

    assert(await storage.bucketExists(kTestBucketName));
    testBucket = storage.bucket(kTestBucketName);
    testLock = GcsLock(client, kTestBucketName);
  }

  Future<void> skiaPerfGcsAdapterIntegrationTest() async {
    final SkiaPerfGcsAdaptor skiaPerfGcs = SkiaPerfGcsAdaptor(testBucket!);

    final String testObjectName = await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterFrameworkRepo,
      kFrameworkRevision1,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );

    await skiaPerfGcs.writePoints(testObjectName, <SkiaPerfPoint>[
      SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1),
      SkiaPerfPoint.fromPoint(cocoonPointRev1Metric2),
    ]);

    final List<SkiaPerfPoint> points =
        await skiaPerfGcs.readPoints(testObjectName);
    expect(points.length, equals(2));
    expectSetMatch(
        points.map((SkiaPerfPoint p) => p.testName), <String>[kTaskName]);
    expectSetMatch(points.map((SkiaPerfPoint p) => p.subResult),
        <String>[kMetric1, kMetric2]);
    expectSetMatch(
        points.map((SkiaPerfPoint p) => p.value), <double>[kValue1, kValue2]);
    expectSetMatch(points.map((SkiaPerfPoint p) => p.githubRepo),
        <String>[kFlutterFrameworkRepo]);
    expectSetMatch(points.map((SkiaPerfPoint p) => p.gitHash),
        <String>[kFrameworkRevision1]);
    for (int i = 0; i < 2; i += 1) {
      expect(points[0].jsonUrl, startsWith('https://'));
    }
  }

  Future<void> skiaPerfGcsIntegrationTestWithEnginePoints() async {
    final SkiaPerfGcsAdaptor skiaPerfGcs = SkiaPerfGcsAdaptor(testBucket!);

    final String testObjectName = await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterEngineRepo,
      engineRevision,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );

    await skiaPerfGcs.writePoints(testObjectName, <SkiaPerfPoint>[
      SkiaPerfPoint.fromPoint(enginePoint1),
      SkiaPerfPoint.fromPoint(enginePoint2),
    ]);

    final List<SkiaPerfPoint> points =
        await skiaPerfGcs.readPoints(testObjectName);
    expect(points.length, equals(2));
    expectSetMatch(
      points.map((SkiaPerfPoint p) => p.testName),
      <String>[engineMetricName, engineMetricName],
    );
    expectSetMatch(
      points.map((SkiaPerfPoint p) => p.value),
      <double>[engineValue1, engineValue2],
    );
    expectSetMatch(
      points.map((SkiaPerfPoint p) => p.githubRepo),
      <String>[kFlutterEngineRepo],
    );
    expectSetMatch(
        points.map((SkiaPerfPoint p) => p.gitHash), <String>[engineRevision]);
    for (int i = 0; i < 2; i += 1) {
      expect(points[0].jsonUrl, startsWith('https://'));
    }
  }

  // To run the following integration tests, there must be a valid Google Cloud
  // Project service account credentials in secret/test_gcp_credentials.json so
  // `testBucket` won't be null. Currently, these integration tests are skipped
  // in the CI, and only verified locally.
  test(
    'SkiaPerfGcsAdaptor passes integration test with Google Cloud Storage',
    skiaPerfGcsAdapterIntegrationTest,
    skip: testBucket == null,
  );

  test(
    'SkiaPerfGcsAdaptor integration test with engine points',
    skiaPerfGcsIntegrationTestWithEnginePoints,
    skip: testBucket == null,
  );

  // `SkiaPerfGcsAdaptor.computeObjectName` uses `GithubHelper` which requires
  // network connections. Hence we put them as integration tests instead of unit
  // tests.
  test(
    'SkiaPerfGcsAdaptor integration test for name computations',
    () async {
      expect(
        await SkiaPerfGcsAdaptor.computeObjectName(
          kFlutterFrameworkRepo,
          kFrameworkRevision1,
          DateTime.utc(2019, 12, 04, 23),
          'test',
        ),
        equals(
            'flutter-flutter/2019/12/04/23/$kFrameworkRevision1/test_values.json'),
      );
      expect(
        await SkiaPerfGcsAdaptor.computeObjectName(
          kFlutterEngineRepo,
          kEngineRevision1,
          DateTime.utc(2019, 12, 03, 20),
          'test',
        ),
        equals(
            'flutter-engine/2019/12/03/20/$kEngineRevision1/test_values.json'),
      );
      expect(
        await SkiaPerfGcsAdaptor.computeObjectName(
          kFlutterEngineRepo,
          kEngineRevision2,
          DateTime.utc(2020, 01, 03, 15),
          'test',
        ),
        equals(
            'flutter-engine/2020/01/03/15/$kEngineRevision2/test_values.json'),
      );
    },
    skip: testBucket == null,
  );

  test('SkiaPerfDestination.update awaits locks', () async {
    bool updateCompleted = false;
    final Completer<void> callbackCompleter = Completer<void>();
    final SkiaPerfGcsAdaptor mockGcs = MockSkiaPerfGcsAdaptor(
      writePointsOverride: () => callbackCompleter.future,
    );
    final GcsLock mockLock = MockGcsLock();
    final SkiaPerfDestination dst = SkiaPerfDestination(mockGcs, mockLock);
    final Future<void> updateFuture = dst.update(
      <MetricPoint>[cocoonPointRev1Metric1],
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );
    final Future<void> markedUpdateCompleted = updateFuture.then<void>((_) {
      updateCompleted = true;
    });

    // spin event loop to make sure function hasn't done anything yet
    await (Completer<void>()..complete()).future;

    // Ensure that the .update() method is waiting for callbackCompleter
    expect(updateCompleted, false);
    callbackCompleter.complete();
    await markedUpdateCompleted;
    expect(updateCompleted, true);
  });

  test('SkiaPerfDestination correctly updates points', () async {
    final SkiaPerfGcsAdaptor mockGcs = MockSkiaPerfGcsAdaptor();
    final GcsLock mockLock = MockGcsLock();
    final SkiaPerfDestination dst = SkiaPerfDestination(mockGcs, mockLock);
    await dst.update(
      <MetricPoint>[cocoonPointRev1Metric1],
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );
    await dst.update(
      <MetricPoint>[cocoonPointRev1Metric2],
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );
    List<SkiaPerfPoint> points =
        await mockGcs.readPoints(await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterFrameworkRepo,
      kFrameworkRevision1,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    ));
    expect(points.length, equals(2));
    expectSetMatch(
        points.map((SkiaPerfPoint p) => p.testName), <String>[kTaskName]);
    expectSetMatch(points.map((SkiaPerfPoint p) => p.subResult),
        <String>[kMetric1, kMetric2]);
    expectSetMatch(
        points.map((SkiaPerfPoint p) => p.value), <double>[kValue1, kValue2]);

    final MetricPoint updated =
        MetricPoint(kValue3, cocoonPointRev1Metric1.tags);

    await dst.update(
      <MetricPoint>[updated, cocoonPointRev2Metric1],
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );

    points =
        await mockGcs.readPoints(await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterFrameworkRepo,
      kFrameworkRevision2,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    ));
    expect(points.length, equals(1));
    expect(points[0].gitHash, equals(kFrameworkRevision2));
    expect(points[0].value, equals(kValue3));

    points =
        await mockGcs.readPoints(await SkiaPerfGcsAdaptor.computeObjectName(
      kFlutterFrameworkRepo,
      kFrameworkRevision1,
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    ));
    expectSetMatch(
        points.map((SkiaPerfPoint p) => p.value), <double>[kValue2, kValue3]);
  });

  Future<void> skiaPerfDestinationIntegrationTest() async {
    final SkiaPerfDestination destination =
        SkiaPerfDestination(SkiaPerfGcsAdaptor(testBucket!), testLock);
    await destination.update(
      <MetricPoint>[cocoonPointRev1Metric1],
      DateTime.fromMillisecondsSinceEpoch(123),
      'test',
    );
  }

  test(
    'SkiaPerfDestination integration test',
    skiaPerfDestinationIntegrationTest,
    skip: testBucket == null,
  );
}

class FakeObjectInfo extends ObjectInfo {
  @override
  int get crc32CChecksum => throw UnimplementedError();

  @override
  Uri get downloadLink => throw UnimplementedError();

  @override
  String get etag => throw UnimplementedError();

  @override
  ObjectGeneration get generation => throw UnimplementedError();

  @override
  int get length => throw UnimplementedError();

  @override
  List<int> get md5Hash => throw UnimplementedError();

  @override
  ObjectMetadata get metadata => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  DateTime get updated => throw UnimplementedError();
}
