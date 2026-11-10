// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/migrations/template_dependency_version_migration.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

/// `settings.gradle.kts` as written by the app template, with the AGP and KGP
/// versions filled in.
String appSettingsKts({required String agp, required String kgp}) =>
    '''
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("\$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "$agp" apply false
    id("org.jetbrains.kotlin.android") version "$kgp" apply false
}

include(":app")
''';

/// `settings.gradle` as written by the add-to-app module template, which is
/// what an editable host app (`flutter make-host-app-editable`) contains.
String moduleHostSettingsGroovy({required String agp, required String kgp}) =>
    '''
// Generated file. Do not edit.

pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("\$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.library" version "$agp" apply false
    id "org.jetbrains.kotlin.android" version "$kgp" apply false
}

include ':app'

rootProject.name = 'android_generated'
setBinding(new Binding([gradle: this]))
evaluate(new File(settingsDir, 'include_flutter.groovy'))
''';

/// `gradle-wrapper.properties` as written by the app template.
String gradleWrapper(String gradle, {String distribution = 'all'}) =>
    '''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-$gradle-$distribution.zip
''';

void main() {
  group('TemplateDependencyVersionMigration', () {
    late MemoryFileSystem fileSystem;
    late BufferLogger logger;
    late FakeAndroidProject project;
    late File settingsKts;
    late File wrapper;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
      project = FakeAndroidProject(
        hostAppGradleRoot: fileSystem.currentDirectory.childDirectory('android')..createSync(),
      );
      settingsKts = project.hostAppGradleRoot.childFile('settings.gradle.kts');
      wrapper =
          project.hostAppGradleRoot
              .childDirectory(gradleDirectoryName)
              .childDirectory(gradleWrapperDirectoryName)
              .childFile(gradleWrapperPropertiesFilename)
            ..createSync(recursive: true);
    });

    Future<void> migrate() => TemplateDependencyVersionMigration(project, logger).migrate();

    testWithoutContext('upgrades a project created with Flutter 3.47', () async {
      settingsKts.writeAsStringSync(appSettingsKts(agp: '9.1.0', kgp: '2.4.0'));
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.1', kgp: '2.4.10'));
      expect(wrapper.readAsStringSync(), gradleWrapper('9.3.1'));
      expect(
        logger.statusText,
        contains(
          'Upgrading the Android Gradle Plugin from 9.1.0 to 9.1.1, '
          'the minimum version that Flutter supports.',
        ),
      );
      expect(
        logger.statusText,
        contains(
          'Upgrading the Kotlin Gradle Plugin from 2.4.0 to 2.4.10, '
          'the minimum version that Flutter supports.',
        ),
      );
      expect(logger.statusText, contains(pluginVersionOptOutFlag));
      expect(logger.statusText, isNot(contains('Upgrading Gradle')));
    });

    testWithoutContext('upgrades a project created with Flutter 3.44', () async {
      settingsKts.writeAsStringSync(appSettingsKts(agp: '9.0.1', kgp: '2.3.20'));
      wrapper.writeAsStringSync(gradleWrapper('9.1.0'));

      await migrate();

      expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.1', kgp: '2.4.10'));
      expect(wrapper.readAsStringSync(), gradleWrapper('9.3.1'));
      expect(
        logger.statusText,
        contains(
          'Upgrading Gradle from 9.1.0 to 9.3.1, the minimum version that Flutter supports.',
        ),
      );
      expect(logger.statusText, contains(gradleWrapperOptOutFlag));
      expect(
        logger.statusText,
        contains('Upgrading the Android Gradle Plugin from 9.0.1 to 9.1.1'),
      );
      expect(
        logger.statusText,
        contains('Upgrading the Kotlin Gradle Plugin from 2.3.20 to 2.4.10'),
      );
    });

    testWithoutContext('upgrades an editable add-to-app host created with Flutter 3.47', () async {
      final File settingsGroovy = project.hostAppGradleRoot.childFile('settings.gradle')
        ..writeAsStringSync(moduleHostSettingsGroovy(agp: '9.1.0', kgp: '2.4.0'));
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(
        settingsGroovy.readAsStringSync(),
        moduleHostSettingsGroovy(agp: '9.1.1', kgp: '2.4.10'),
      );
    });

    testWithoutContext('upgrades single-quoted Groovy declarations', () async {
      final File settingsGroovy = project.hostAppGradleRoot.childFile('settings.gradle')
        ..writeAsStringSync('''
plugins {
    id 'com.android.application' version '9.1.0' apply false
    id 'org.jetbrains.kotlin.android' version '2.4.0' apply false
}
''');
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsGroovy.readAsStringSync(), '''
plugins {
    id 'com.android.application' version '9.1.1' apply false
    id 'org.jetbrains.kotlin.android' version '2.4.10' apply false
}
''');
    });

    testWithoutContext('upgrades a Gradle bin distribution', () async {
      settingsKts.writeAsStringSync(appSettingsKts(agp: '9.0.1', kgp: '2.3.20'));
      wrapper.writeAsStringSync(gradleWrapper('9.1.0', distribution: 'bin'));

      await migrate();

      expect(wrapper.readAsStringSync(), gradleWrapper('9.3.1', distribution: 'bin'));
      expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.1', kgp: '2.4.10'));
    });

    testWithoutContext('leaves a project created with the current templates unchanged', () async {
      final String settings = appSettingsKts(
        agp: templateAndroidGradlePluginVersion,
        kgp: templateKotlinGradlePluginVersion,
      );
      final String wrapperContents = gradleWrapper(templateDefaultGradleVersion);
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(wrapperContents);

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
      expect(wrapper.readAsStringSync(), wrapperContents);
      expect(logger.statusText, isEmpty);
    });

    testWithoutContext('leaves versions that no template wrote unchanged', () async {
      final String settings = appSettingsKts(agp: '9.2.0', kgp: '2.4.5');
      final String wrapperContents = gradleWrapper('9.2.1');
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(wrapperContents);

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
      expect(wrapper.readAsStringSync(), wrapperContents);
      expect(logger.statusText, isEmpty);
    });

    testWithoutContext('does not upgrade across a major AGP version', () async {
      // Flutter 3.41 templates. Moving to AGP 9 requires the migration in
      // https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin,
      // so this migration leaves AGP 8 projects alone.
      final String settings = appSettingsKts(agp: '8.11.1', kgp: '2.2.20');
      final String wrapperContents = gradleWrapper('8.14');
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(wrapperContents);

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
      expect(wrapper.readAsStringSync(), wrapperContents);
      expect(logger.statusText, isEmpty);
    });

    testWithoutContext(
      'upgrades KGP but not AGP when the Gradle version is too old for the new AGP',
      () async {
        settingsKts.writeAsStringSync(appSettingsKts(agp: '9.1.0', kgp: '2.4.0'));
        // Not a version that a template wrote, so it isn't upgraded.
        wrapper.writeAsStringSync(gradleWrapper('9.2.0'));

        await migrate();

        expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.0', kgp: '2.4.10'));
        expect(wrapper.readAsStringSync(), gradleWrapper('9.2.0'));
        expect(
          logger.traceText,
          contains(
            'Skipping Android Gradle Plugin upgrade from 9.1.0 because AGP 9.1.1 '
            'requires Gradle 9.3.1 or later, and the project uses Gradle 9.2.0.',
          ),
        );
      },
    );

    testWithoutContext('upgrades KGP but not AGP when the Gradle version is unknown', () async {
      settingsKts.writeAsStringSync(appSettingsKts(agp: '9.1.0', kgp: '2.4.0'));
      wrapper.deleteSync();

      await migrate();

      expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.0', kgp: '2.4.10'));
      expect(logger.traceText, contains('the project uses Gradle of an unknown version'));
    });

    testWithoutContext(
      'does not upgrade AGP when the Gradle distribution is not on services.gradle.org',
      () async {
        settingsKts.writeAsStringSync(appSettingsKts(agp: '9.1.0', kgp: '2.4.0'));
        const mirroredWrapper =
            'distributionUrl=https\\://example.com/mirror/gradle-9.3.1-all.zip\n';
        wrapper.writeAsStringSync(mirroredWrapper);

        await migrate();

        // The Gradle version can't be read from a mirror URL, so AGP is left
        // alone rather than risking an AGP and Gradle mismatch.
        expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.0', kgp: '2.4.10'));
        expect(wrapper.readAsStringSync(), mirroredWrapper);
      },
    );

    testWithoutContext('honors the Gradle wrapper opt-out flag', () async {
      settingsKts.writeAsStringSync(appSettingsKts(agp: '9.0.1', kgp: '2.3.20'));
      final wrapperContents = '${gradleWrapper('9.1.0')}# $gradleWrapperOptOutFlag\n';
      wrapper.writeAsStringSync(wrapperContents);

      await migrate();

      expect(wrapper.readAsStringSync(), wrapperContents);
      // AGP 9.1.1 needs a newer Gradle, so AGP is left alone too.
      expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.0.1', kgp: '2.4.10'));
      expect(logger.traceText, contains(gradleWrapperOptOutFlag));
    });

    testWithoutContext('honors the settings opt-out flag', () async {
      final settings = '// $pluginVersionOptOutFlag\n${appSettingsKts(agp: '9.1.0', kgp: '2.4.0')}';
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
      expect(logger.statusText, isEmpty);
      expect(logger.traceText, contains(pluginVersionOptOutFlag));
    });

    testWithoutContext('leaves commented-out declarations unchanged', () async {
      const settings = '''
plugins {
    // id("com.android.application") version "9.1.0" apply false
    id("com.android.application") version "9.1.0" apply false // was 9.0.1
}
''';
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsKts.readAsStringSync(), '''
plugins {
    // id("com.android.application") version "9.1.0" apply false
    id("com.android.application") version "9.1.1" apply false // was 9.0.1
}
''');
    });

    testWithoutContext('leaves version catalog declarations unchanged', () async {
      const settings = '''
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
}
''';
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
      expect(logger.statusText, isEmpty);
    });

    testWithoutContext('leaves versions from variables unchanged', () async {
      const settings = r'''
val agpVersion = "9.1.0"
plugins {
    id("com.android.application") version agpVersion apply false
    id("org.jetbrains.kotlin.android") version "${extra["kotlinVersion"]}" apply false
}
''';
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
      expect(logger.statusText, isEmpty);
    });

    testWithoutContext('does not change other plugins with matching versions', () async {
      const settings = '''
plugins {
    id("com.google.gms.google-services") version "9.1.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.0" apply false
}
''';
      settingsKts.writeAsStringSync(settings);
      wrapper.writeAsStringSync(gradleWrapper('9.3.1'));

      await migrate();

      expect(settingsKts.readAsStringSync(), settings);
    });

    testWithoutContext('is idempotent', () async {
      settingsKts.writeAsStringSync(appSettingsKts(agp: '9.0.1', kgp: '2.3.20'));
      wrapper.writeAsStringSync(gradleWrapper('9.1.0'));

      await migrate();
      final migratedLogger = BufferLogger.test();
      await TemplateDependencyVersionMigration(project, migratedLogger).migrate();

      expect(settingsKts.readAsStringSync(), appSettingsKts(agp: '9.1.1', kgp: '2.4.10'));
      expect(wrapper.readAsStringSync(), gradleWrapper('9.3.1'));
      expect(migratedLogger.statusText, isEmpty);
    });

    testWithoutContext('does nothing when files are missing', () async {
      settingsKts.parent.deleteSync(recursive: true);
      settingsKts.parent.createSync();

      await migrate();

      expect(logger.statusText, isEmpty);
      expect(logger.traceText, contains('settings.gradle(.kts) not found'));
    });

    testWithoutContext('targets the minimum versions that Flutter supports', () async {
      // Keep the targets in sync with DependencyVersionChecker.kt, so that the
      // migrated project builds without an error and the targets don't drift
      // past the versions that this migration has been verified with.
      const FileSystem localFileSystem = LocalFileSystem();
      final File checker = localFileSystem.file(
        localFileSystem.path.join(
          getFlutterRoot(),
          'packages',
          'flutter_tools',
          'gradle',
          'src',
          'main',
          'kotlin',
          'DependencyVersionChecker.kt',
        ),
      );
      final String source = checker.readAsStringSync();
      String versionOf(String name) {
        final RegExpMatch match = RegExp('$name: \\w+ = \\w+\\((\\d+), (\\d+), (\\d+)\\)')
            .firstMatch(source)!;
        return '${match.group(1)}.${match.group(2)}.${match.group(3)}';
      }

      expect(gradleTargetVersion, versionOf('errorGradleVersion'));
      expect(agpTargetVersion, versionOf('errorAGPVersion'));
      expect(kgpTargetVersion, versionOf('errorKGPVersion'));
    });
  });
}

class FakeAndroidProject extends Fake implements AndroidProject {
  FakeAndroidProject({required this.hostAppGradleRoot});

  @override
  final Directory hostAppGradleRoot;
}
