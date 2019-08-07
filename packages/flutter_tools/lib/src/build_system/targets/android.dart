// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/process_manager.dart';
import '../build_system.dart';

/// Refactor into artifacts.
const String aapt = '/Users/jonahwilliams/Library/Android/sdk/build-tools/28.0.3/aapt';
const String androidJar = '/Users/jonahwilliams/Library/Android/sdk/platforms/android-28/android.jar';
const String dexer = '/Users/jonahwilliams/Library/Android/sdk/build-tools/28.0.3/dx';

/// Known during planning.
const String package = 'foo/bar/baz';

/// All resource files.
List<File> resourceFiles(Environment environment) {
  return environment.buildDir.childDirectory('res')
    .listSync(recursive: true)
    .whereType<File>();
}

/// Generates an R.java file from resources.
class ResourceFileTarget extends Target {
  const ResourceFileTarget();

  @override
  String get name => 'java_resource';

  @override
  List<Target> get dependencies => null;

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/AndroidManifest.xml'),
    Source.function(resourceFiles),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/gen/$package/R.java'),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final File androidManifest = environment.buildDir.childFile('AndroidManifest.xml');

    await processManager.run(<String>[
      aapt,
      'package',
      '-f',
      '-M', androidManifest.path,
      '-I', androidJar,
      '-S', environment.buildDir.childDirectory('res').path,
      '-J', environment.buildDir.childDirectory('gen').path,
    ]);
  }
}

class CompileJavaTarget extends Target {
  const CompileJavaTarget();

  @override
  String get name => 'compile_java';

  @override
  List<Target> get dependencies => const <Target>[
    ResourceFileTarget(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/src/$package/MainActivity.java'),
    Source.pattern('{BUILD_DIR}/gen/$package/R.java'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/obj/$package/MainActivity.class'),
    Source.pattern('{BUILD_DIR}/obj/$package/R.class'),
    Source.pattern('{BUILD_DIR}/obj/$package/R\$attr.class'),
    Source.pattern('{BUILD_DIR}/obj/$package/R\$layout.class'),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    await processManager.run(<String>[
      'javac',
      '-d', environment.buildDir.childDirectory('obj').path,
      '-classpath', environment.buildDir.childDirectory('src').path,
      '-bootclasspath', androidJar,
      fs.path.join(environment.buildDir.path, 'src', package, 'MainActivity.java'),
      fs.path.join(environment.buildDir.path, 'gen', package, 'R.java'),
    ]);
  }
}

class DexJavaTarget extends Target {
  const DexJavaTarget();

  @override
  String get name => 'dex_java';

  @override
  List<Target> get dependencies => null;

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/src/$package/MainActivity.java'),
    Source.pattern('{BUILD_DIR}/gen/$package/R.java'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/obj/$package/MainActivity.class'),
    Source.pattern('{BUILD_DIR}/obj/$package/R.class'),
    Source.pattern('{BUILD_DIR}/obj/$package/R\$attr.class'),
    Source.pattern('{BUILD_DIR}/obj/$package/R\$layout.class'),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    await processManager.run(<String>[
      'javac',
      '-d', environment.buildDir.childDirectory('obj').path,
      '-classpath', environment.buildDir.childDirectory('src').path,
      '-bootclasspath', androidJar,
      fs.path.join(environment.buildDir.path, 'src', package, 'MainActivity.java'),
      fs.path.join(environment.buildDir.path, 'gen', package, 'R.java'),
    ]);
  }
}