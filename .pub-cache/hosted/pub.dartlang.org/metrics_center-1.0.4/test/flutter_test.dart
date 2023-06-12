// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:metrics_center/src/constants.dart';
import 'package:metrics_center/src/flutter.dart';

import 'common.dart';
import 'utility.dart';

void main() {
  const String gitRevision = 'ca799fa8b2254d09664b78ee80c43b434788d112';
  final FlutterEngineMetricPoint simplePoint = FlutterEngineMetricPoint(
    'BM_ParagraphLongLayout',
    287235,
    gitRevision,
  );

  test('FlutterEngineMetricPoint works.', () {
    expect(simplePoint.value, equals(287235));
    expect(simplePoint.tags[kGithubRepoKey], kFlutterEngineRepo);
    expect(simplePoint.tags[kGitRevisionKey], gitRevision);
    expect(simplePoint.tags[kNameKey], 'BM_ParagraphLongLayout');

    final FlutterEngineMetricPoint detailedPoint = FlutterEngineMetricPoint(
      'BM_ParagraphLongLayout',
      287224,
      'ca799fa8b2254d09664b78ee80c43b434788d112',
      moreTags: const <String, String>{
        'executable': 'txt_benchmarks',
        'sub_result': 'CPU',
        kUnitKey: 'ns',
      },
    );
    expect(detailedPoint.value, equals(287224));
    expect(detailedPoint.tags['executable'], equals('txt_benchmarks'));
    expect(detailedPoint.tags['sub_result'], equals('CPU'));
    expect(detailedPoint.tags[kUnitKey], equals('ns'));
  });

  final Map<String, dynamic>? credentialsJson = getTestGcpCredentialsJson();

  test('FlutterDestination integration test with update.', () async {
    final FlutterDestination dst =
        await FlutterDestination.makeFromCredentialsJson(credentialsJson!,
            isTesting: true);
    await dst.update(<FlutterEngineMetricPoint>[simplePoint],
        DateTime.fromMillisecondsSinceEpoch(123), 'test');
  }, skip: credentialsJson == null);
}
