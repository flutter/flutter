// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_cache.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  testWithoutContext('widget cache returns null when experiment is disabled', () async {
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: false),
      fileSystem: MemoryFileSystem.test(),
    );

    expect(await widgetCache.validateLibrary(Uri.parse('package:hello_world/main.dart')), null);
  });

  testWithoutContext('widget cache can diff changes to a StatelessWidget', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('a.dart').writeAsStringSync(createWidget(0));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    fileSystem.file('a.dart').writeAsStringSync(createWidget(1));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), 'FooWidget');

    fileSystem.file('a.dart').writeAsStringSync(createWidget(2));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), 'FooWidget');

    // No change since last run.
    fileSystem.file('a.dart').writeAsStringSync(createWidget(2));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);
  });

  testWithoutContext('widget cache can diff changes to a StatefulWidget', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('a.dart').writeAsStringSync(createWidget(0, stateful: true));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    fileSystem.file('a.dart').writeAsStringSync(createWidget(1, stateful: true));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), 'FooWidget');

    fileSystem.file('a.dart').writeAsStringSync(createWidget(2, stateful: true));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), 'FooWidget');

    // No change since last run.
    fileSystem.file('a.dart').writeAsStringSync(createWidget(2, stateful: true));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);
  });

  testWithoutContext('widget cache returns null on invalid files', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('a.dart').writeAsStringSync('class FooWidget {');

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);
  });

  testWithoutContext('widget cache returns null on update to invalid file', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('a.dart').writeAsStringSync(createWidget(0));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    fileSystem.file('a.dart').writeAsStringSync('class FooWidget {');

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);
  });

  testWithoutContext('widget cache does not return widget name on transition from '
    'invalid to valid file', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('a.dart').writeAsStringSync('class FooWidget {');

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    fileSystem.file('a.dart').writeAsStringSync(createWidget(0));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    // File is still good, otherwise should trigger change normally.
    fileSystem.file('a.dart').writeAsStringSync(createWidget(0));
    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    fileSystem.file('a.dart').writeAsStringSync(createWidget(1));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), 'FooWidget');
  });

  testWithoutContext('widget cache does not return widget name on name change', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('a.dart').writeAsStringSync(createWidget(0));

    expect(await widgetCache.validateLibrary(Uri.parse('a.dart')), null);

    fileSystem.file('a.dart').writeAsStringSync('''
class FooWidget2 extends StatelessWidget {
  Widget build(BuildContext context) {
    return Text('0');
  }
}
''');
  });

  testWithoutContext('widget cache can only store up to 5 libraries', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WidgetCache widgetCache = WidgetCache(
      featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true),
      fileSystem: fileSystem,
    );
    fileSystem.file('1.dart').writeAsStringSync(createWidget(0));
    fileSystem.file('2.dart').writeAsStringSync(createWidget(0));
    fileSystem.file('3.dart').writeAsStringSync(createWidget(0));
    fileSystem.file('4.dart').writeAsStringSync(createWidget(0));
    fileSystem.file('5.dart').writeAsStringSync(createWidget(0));
    fileSystem.file('6.dart').writeAsStringSync(createWidget(0));

    expect(await widgetCache.validateLibrary(Uri.parse('1.dart')), null);
    expect(await widgetCache.validateLibrary(Uri.parse('2.dart')), null);
    expect(await widgetCache.validateLibrary(Uri.parse('3.dart')), null);
    expect(await widgetCache.validateLibrary(Uri.parse('4.dart')), null);
    expect(await widgetCache.validateLibrary(Uri.parse('5.dart')), null);
    expect(await widgetCache.validateLibrary(Uri.parse('6.dart')), null);

    // The first library entered into the cache, `1.dart` will have been
    // evicted

    fileSystem.file('1.dart').writeAsStringSync(createWidget(1));
    expect(await widgetCache.validateLibrary(Uri.parse('1.dart')), null);

    // 2.dart will be the next evicted, 3.dart is not evicted.
    fileSystem.file('3.dart').writeAsStringSync(createWidget(1));
    expect(await widgetCache.validateLibrary(Uri.parse('3.dart')), 'FooWidget');
  });
}

String createWidget(int index, {bool stateful = false}) {
  if (stateful) {
    return '''
class FooState extends State<FooWidget>{
  @override
  Widget build(BuildContext context) {
    return Text('$index');
  }
}
''';
  }
  return '''
class FooWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Text('$index');
  }
}
''';
}
