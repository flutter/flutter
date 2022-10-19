// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/memory.dart';

import '../tool_subsharding.dart';
import 'common.dart';

void main() {
  group('generateMetrics', () {
    late MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    test('empty metrics', () async {
      final File file = fileSystem.file('success_file');
      const String output = '''
      {"missing": "entry"}
      {"other": true}''';
      file.writeAsStringSync(output);
      final Map<int, TestSpecs> result = generateMetrics(file);
      expect(result, isEmpty);
    });

    test('have metrics', () async {
      final File file = fileSystem.file('success_file');
      const String output = '''
      {"protocolVersion":"0.1.1","runnerVersion":"1.21.6","pid":93376,"type":"start","time":0}
      {"suite":{"id":0,"platform":"vm","path":"test/general.shard/project_validator_result_test.dart"},"type":"suite","time":0}
      {"count":1,"time":12,"type":"allSuites"}
      {"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":4798}
      {"test":{"id":4,"name":"ProjectValidatorResult success status","suiteID":0,"groupIDs":[2,3],"metadata":{"skip":false,"skipReason":null},"line":159,"column":16,"url":"file:///file","root_line":50,"root_column":5,"root_url":"file:///file"},"type":"testStart","time":4803}
      {"testID":4,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":4837}
      {"suite":{"id":1,"platform":"vm","path":"other_path"},"type":"suite","time":1000}
      {"test":{"id":5,"name":"ProjectValidatorResult success status with warning","suiteID":0,"groupIDs":[2,3],"metadata":{"skip":false,"skipReason":null},"line":159,"column":16,"url":"file:///file","root_line":60,"root_column":5,"root_url":"file:///file"},"type":"testStart","time":4837}
      {"testID":5,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":4839}
      {"test":{"id":6,"name":"ProjectValidatorResult error status","suiteID":0,"groupIDs":[2,3],"metadata":{"skip":false,"skipReason":null},"line":159,"column":16,"url":"file:///file","root_line":71,"root_column":5,"root_url":"file:///file"},"type":"testStart","time":4839}
      {"testID":6,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":4841}
      {"group":{"id":7,"suiteID":0,"parentID":2,"name":"ProjectValidatorTask","metadata":{"skip":false,"skipReason":null},"testCount":1,"line":82,"column":3,"url":"file:///file"},"type":"group","time":4841}
      {"test":{"id":8,"name":"ProjectValidatorTask error status","suiteID":0,"groupIDs":[2,7],"metadata":{"skip":false,"skipReason":null},"line":159,"column":16,"url":"file:///file","root_line":89,"root_column":5,"root_url":"file:///file"},"type":"testStart","time":4842}
      {"testID":8,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":4860}
      {"group":{"id":7,"suiteID":1,"parentID":2,"name":"ProjectValidatorTask","metadata":{"skip":false,"skipReason":null},"testCount":1,"line":82,"column":3,"url":"file:///file"},"type":"group","time":5000}
      {"success":true,"type":"done","time":4870}''';
      file.writeAsStringSync(output);
      final Map<int, TestSpecs> result = generateMetrics(file);
      expect(result, contains(0));
      expect(result, contains(1));
      expect(result[0]!.path, 'test/general.shard/project_validator_result_test.dart');
      expect(result[0]!.milliseconds, 4841);
      expect(result[1]!.path, 'other_path');
      expect(result[1]!.milliseconds, 4000);
    });

    test('missing success entry', () async {
      final File file = fileSystem.file('success_file');
      const String output = '''
      {"suite":{"id":1,"platform":"vm","path":"other_path"},"type":"suite","time":1000}
      {"group":{"id":7,"suiteID":1,"parentID":2,"name":"name","metadata":{"skip":false,"skipReason":null},"testCount":1,"line":82,"column":3,"url":"file:///file"},"type":"group","time":5000}''';
      file.writeAsStringSync(output);
      final Map<int, TestSpecs> result = generateMetrics(file);
      expect(result, isEmpty);
    });
  });
}
