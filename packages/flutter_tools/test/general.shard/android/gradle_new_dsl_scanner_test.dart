// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/gradle_new_dsl_scanner.dart';

import '../../src/common.dart';

void main() {
  group('GradleNewDslScanner.blocksNewDsl', () {
    testWithoutContext('returns false for empty or migrated build files', () {
      expect(GradleNewDslScanner.blocksNewDsl('', isKotlinDsl: false), isFalse);
      expect(
        GradleNewDslScanner.blocksNewDsl('''
plugins {
    id("com.android.library")
}
android {
    namespace = "com.example.migrated"
}
androidComponents {
    onVariants(selector().all()) { }
}
''', isKotlinDsl: true),
        isFalse,
      );
    });

    testWithoutContext('blocks unconditional legacy variant and extension identifiers', () {
      const blockingSnippets = <String, String>{
        'applicationVariants': 'android { applicationVariants.all {} }',
        'libraryVariants': 'android.libraryVariants.all { v -> }',
        'testVariants': 'android.testVariants.all {}',
        'unitTestVariants': 'android.unitTestVariants.all {}',
        'variantFilter': 'android { variantFilter {} }',
        'BaseExtension': 'project.extensions.getByType(com.android.build.gradle.BaseExtension)',
        'AppExtension': 'import com.android.build.gradle.AppExtension',
        'BaseAppModuleExtension': 'extensions.configure<BaseAppModuleExtension> {}',
        'qualified BaseAppModuleExtension': 'project.extensions.getByType(com.android.build.gradle.internal.dsl.BaseAppModuleExtension)',
      };
      for (final MapEntry<String, String> entry in blockingSnippets.entries) {
        expect(
          GradleNewDslScanner.blocksNewDsl(entry.value, isKotlinDsl: false),
          isTrue,
          reason: entry.key,
        );
      }
    });

    testWithoutContext('distinguishes com.android.build.api.dsl vs legacy LibraryExtension, TestedExtension, and TestExtension', () {
      for (final extensionName in <String>[
        'LibraryExtension',
        'TestedExtension',
        'TestExtension',
      ]) {
        // Unimported bare reference blocks.
        expect(
          GradleNewDslScanner.blocksNewDsl(
            'extensions.configure<$extensionName> {}',
            isKotlinDsl: true,
          ),
          isTrue,
          reason: 'unimported $extensionName',
        );
        // Legacy package import blocks.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
import com.android.build.gradle.$extensionName
extensions.configure<$extensionName> {}
''', isKotlinDsl: true),
          isTrue,
          reason: 'legacy imported $extensionName',
        );
        // Legacy qualified reference blocks.
        expect(
          GradleNewDslScanner.blocksNewDsl(
            'extensions.configure<com.android.build.gradle.$extensionName> {}',
            isKotlinDsl: true,
          ),
          isTrue,
          reason: 'legacy qualified $extensionName',
        );
        // Public API explicit import does not block.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
import com.android.build.api.dsl.$extensionName
extensions.configure<$extensionName> {}
''', isKotlinDsl: true),
          isFalse,
          reason: 'public imported $extensionName',
        );
        // Public API wildcard import (without legacy wildcard) does not block.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
import com.android.build.api.dsl.*
extensions.configure<$extensionName> {}
''', isKotlinDsl: true),
          isFalse,
          reason: 'public wildcard $extensionName',
        );
        // Public API qualified reference does not block.
        expect(
          GradleNewDslScanner.blocksNewDsl(
            'extensions.configure<com.android.build.api.dsl.$extensionName> {}',
            isKotlinDsl: true,
          ),
          isFalse,
          reason: 'public qualified $extensionName',
        );
        // Ambiguous dual wildcard imports block bare reference.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
import com.android.build.api.dsl.*
import com.android.build.gradle.*
extensions.configure<$extensionName> {}
''', isKotlinDsl: true),
          isTrue,
          reason: 'ambiguous wildcards $extensionName',
        );
      }

      // Importing LibraryExtension from api.dsl does not excuse bare TestedExtension.
      expect(
        GradleNewDslScanner.blocksNewDsl('''
import com.android.build.api.dsl.LibraryExtension
extensions.configure<TestedExtension> {}
''', isKotlinDsl: true),
        isTrue,
      );
    });

    testWithoutContext('blocks declarative plugins {} applications without apply false', () {
      const blockingDeclarations = <String>[
        'plugins { id "kotlin-android" }',
        'plugins { id("org.jetbrains.kotlin.android") }',
        'plugins { kotlin("android") }',
        'plugins { `kotlin-android` }',
        'plugins { `org.jetbrains.kotlin.android` }',
        'plugins { alias(libs.plugins.kotlin.android) }',
        'plugins { alias(libs.plugins.jetbrains.kotlin.android) }',
        'plugins { alias(libs.plugins.android.kotlin) }',
        '''
plugins {
    id("org.jetbrains.kotlin.android")
    `maven-publish` apply false
}
''',
        '''
plugins {
    id("org.jetbrains.kotlin.android")
    id("com.android.library") apply false
}
''',
      ];
      for (final source in blockingDeclarations) {
        expect(GradleNewDslScanner.blocksNewDsl(source, isKotlinDsl: true), isTrue, reason: source);
      }
    });

    testWithoutContext(
      'allows apply false declarations, non-kotlin-android catalog aliases, and reactive queries',
      () {
        const allowedSnippets = <String>[
          'plugins { id("org.jetbrains.kotlin.android") version "2.4.20" apply false }',
          'plugins { id("kotlin-android") version libs.versions.kotlin.get() apply false }',
          'plugins { `kotlin-android` apply false }',
          '''
plugins {
    id("org.jetbrains.kotlin.android")
        version "2.4.20"
        apply false
}
''',
          'plugins { alias(libs.plugins.kotlin.multiplatform.android) }',
          'plugins { alias(libs.plugins.android.kotlin.multiplatform.library) }',
          'plugins { alias(libs.plugins.android.library) }',
          '''
plugins.withId("org.jetbrains.kotlin.android") { }
pluginManager.withPlugin("kotlin-android") { }
val hasKotlin = plugins.hasPlugin("kotlin-android") || pluginManager.hasPlugin("org.jetbrains.kotlin.android")
val found = plugins.findPlugin("kotlin-android")
''',
        ];
        for (final source in allowedSnippets) {
          expect(
            GradleNewDslScanner.blocksNewDsl(source, isKotlinDsl: true),
            isFalse,
            reason: source,
          );
        }
      },
    );

    testWithoutContext(
      'allows imperative kotlin-android when guarded by AGP or newDsl/builtInKotlin signals',
      () {
        const guardedGroovySnippets = <String>[
          '''
def agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.tokenize('.')[0].toInteger()
def builtInKotlin = project.findProperty("android.builtInKotlin")?.toString()?.toBoolean() ?: false
if (agpMajor < 9 || !builtInKotlin) {
    apply plugin: 'kotlin-android'
}
''',
          '''
def isBuiltInKotlin() {
    return project.findProperty('android.builtInKotlin')?.toString()?.toBoolean() ?: false
}
if (!isBuiltInKotlin()) {
    apply plugin: 'kotlin-android'
}
''',
          '''
def isLegacyAgp = { com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.startsWith('8.') }
if (isLegacyAgp()) {
    project.pluginManager.apply('org.jetbrains.kotlin.android')
}
''',
          '''
def builtInKotlin = project.findProperty('android.builtInKotlin') == 'true'
if (builtInKotlin) println('modern'); else apply plugin: 'kotlin-android'
''',
        ];
        for (final source in guardedGroovySnippets) {
          expect(
            GradleNewDslScanner.blocksNewDsl(source, isKotlinDsl: false),
            isFalse,
            reason: source,
          );
        }

        const guardedKotlinSnippets = <String>[
          '''
val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore(".").toInt()
val builtInKotlinEnabled =
    agpMajor >= 9 &&
        (providers.gradleProperty("android.builtInKotlin").orNull?.toBoolean() != false)
if (!builtInKotlinEnabled) {
    apply(plugin = "org.jetbrains.kotlin.android")
}
''',
          '''
val currentVersion: AndroidPluginVersion = androidComponents.pluginVersion
val beforeAgp9 = currentVersion < AndroidPluginVersion(9, 0)
if (beforeAgp9) {
    apply(plugin = "kotlin-android")
}
''',
          '''
val newDslDisabled = providers.gradleProperty("android.newDsl").orNull == "false"
if (newDslDisabled) apply(plugin = "kotlin-android")
''',
          '''
val builtInKotlin = providers.gradleProperty("android.builtInKotlin").orNull == "true"
if (builtInKotlin) println("built-in Kotlin"); else apply(plugin = "kotlin-android")
''',
          '''
fun supportsBuiltInKotlin(): Boolean {
    return providers.gradleProperty("android.builtInKotlin").orNull == "true"
}
if (!supportsBuiltInKotlin()) {
    if (!plugins.hasPlugin("kotlin-android")) {
        apply(plugin = "kotlin-android")
    }
}
''',
          '''
var applyLegacyKotlin = true
val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore(".").toInt()
if (agpMajor >= 9) {
    applyLegacyKotlin = false
}
if (applyLegacyKotlin) {
    apply(plugin = "kotlin-android")
}
''',
          '''
val builtInKotlin = providers.gradleProperty("android.builtInKotlin").orNull == "true"
when {
    !builtInKotlin -> apply(plugin = "kotlin-android")
}
''',
          '''
val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore(".").toInt()
when (agpMajor < 9) {
    true -> {
        apply(plugin = "kotlin-android")
    }
    else -> {}
}
''',
        ];
        for (final source in guardedKotlinSnippets) {
          expect(
            GradleNewDslScanner.blocksNewDsl(source, isKotlinDsl: true),
            isFalse,
            reason: source,
          );
        }
      },
    );

    testWithoutContext('blocks imperative kotlin-android in unrelated conditionals even when file checks AGP version elsewhere', () {
      expect(
        GradleNewDslScanner.blocksNewDsl('''
def agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.tokenize('.')[0].toInteger()
if (agpMajor >= 8) {
    android { namespace = 'com.example.plugin' }
}
if (!plugins.hasPlugin('kotlin-android')) {
    apply plugin: 'kotlin-android'
}
''', isKotlinDsl: false),
        isTrue,
      );

      expect(
        GradleNewDslScanner.blocksNewDsl('''
val builtInKotlin = providers.gradleProperty("android.builtInKotlin").orNull == "true"
val unrelatedFlag = true
when {
    unrelatedFlag -> apply(plugin = "kotlin-android")
}
''', isKotlinDsl: true),
        isTrue,
      );
    });

    testWithoutContext(
      'blocks multiline Groovy apply, typed Kotlin plugin variables, and map apply forms',
      () {
        expect(
          GradleNewDslScanner.blocksNewDsl('''
apply plugin:
    'kotlin-android'
''', isKotlinDsl: false),
          isTrue,
        );

        expect(
          GradleNewDslScanner.blocksNewDsl('''
apply from: 'other.gradle',
    plugin: 'kotlin-android'
''', isKotlinDsl: false),
          isTrue,
        );

        expect(
          GradleNewDslScanner.blocksNewDsl('''
val pluginId: String = "org.jetbrains.kotlin.android"
apply(plugin = pluginId)
''', isKotlinDsl: true),
          isTrue,
        );

        expect(
          GradleNewDslScanner.blocksNewDsl(
            'apply(mapOf("plugin" to "org.jetbrains.kotlin.android"))',
            isKotlinDsl: true,
          ),
          isTrue,
        );
      },
    );

    testWithoutContext(
      'respects comments, string literals, Groovy slashy strings, and division',
      () {
        // Dollar-slashy string containing `/*` does not hide subsequent legacy API.
        expect(
          GradleNewDslScanner.blocksNewDsl(r'''
def pattern = $/foo/*bar/$
android.libraryVariants.all {}
''', isKotlinDsl: false),
          isTrue,
        );

        // Slashy regex containing `"` or `/*` does not hide subsequent legacy API or apply.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
def cleaned = name.replaceAll(/"/, '')
android.libraryVariants.all {}
''', isKotlinDsl: false),
          isTrue,
        );
        expect(
          GradleNewDslScanner.blocksNewDsl('''
if (name =~ /foo/*bar/) { println("matched") }
apply plugin: 'kotlin-android'
''', isKotlinDsl: false),
          isTrue,
        );

        // Arithmetic division on the same line is not misread as a slashy string.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
def ratio = width / height + extra / 2
''', isKotlinDsl: false),
          isFalse,
        );
        expect(
          GradleNewDslScanner.blocksNewDsl('''
def ratio = width / height; def half = ratio / 2
android.libraryVariants.all {}
''', isKotlinDsl: false),
          isTrue,
        );

        // URL string before legacy API on the same line still blocks.
        expect(
          GradleNewDslScanner.blocksNewDsl(
            'def repo = "https://example.com"; android.libraryVariants.all {}\n',
            isKotlinDsl: false,
          ),
          isTrue,
        );

        // Legacy API names and closing braces inside strings or comments do not block.
        expect(
          GradleNewDslScanner.blocksNewDsl(r'''
/* Outer Kotlin block comment
   /* Nested block comment: id("kotlin-android") */
   android.applicationVariants.all {}
*/
val builtInKotlin = providers.gradleProperty("android.builtInKotlin").orNull == "true"
println("Migrated off libraryVariants and BaseExtension")
if (!builtInKotlin) {
    println("}")
    println("""raw \\ string } BaseAppModuleExtension""")
    println("${if (true) "}" else "{"}")
    apply(plugin = "kotlin-android")
}
''', isKotlinDsl: true),
          isFalse,
        );

        // Unclosed guarded brace fails closed and blocks.
        expect(
          GradleNewDslScanner.blocksNewDsl('''
val builtInKotlin = providers.gradleProperty("android.builtInKotlin").orNull == "true"
if (!builtInKotlin) {
    apply(plugin = "kotlin-android")
''', isKotlinDsl: true),
          isTrue,
        );
      },
    );
  });
}
