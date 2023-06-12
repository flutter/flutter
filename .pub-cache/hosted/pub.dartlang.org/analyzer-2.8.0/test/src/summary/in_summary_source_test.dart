// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InSummarySourceTest);
  });
}

@reflectiveTest
class InSummarySourceTest {
  test_InSummarySource() {
    var sourceFactory = SourceFactory([
      InSummaryUriResolver(
          PhysicalResourceProvider.INSTANCE,
          MockSummaryDataStore.fake({
            'package:foo/foo.dart': 'foo.sum',
            'package:foo/src/foo_impl.dart': 'foo.sum',
            'package:bar/baz.dart': 'bar.sum',
          }))
    ]);

    var source =
        sourceFactory.forUri('package:foo/foo.dart') as InSummarySource;
    expect(source, isNotNull);
    expect(source.summaryPath, 'foo.sum');

    source = sourceFactory.forUri('package:foo/src/foo_impl.dart')
        as InSummarySource;
    expect(source, isNotNull);
    expect(source.summaryPath, 'foo.sum');

    source = sourceFactory.forUri('package:bar/baz.dart') as InSummarySource;
    expect(source, isNotNull);
    expect(source.summaryPath, 'bar.sum');
  }
}

class MockSummaryDataStore implements SummaryDataStore {
  @override
  final Map<String, String> uriToSummaryPath;

  MockSummaryDataStore(this.uriToSummaryPath);

  factory MockSummaryDataStore.fake(Map<String, String> uriToSummary) {
    return MockSummaryDataStore(uriToSummary);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
