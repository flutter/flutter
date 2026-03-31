// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

/// List of allowed external packages that Flutter framework packages can depend on.
/// Subject to review and approval when adding new packages.
///
/// External dependencies from Flutter framework packages cause a number of
/// issues including:
///  - Increased risk of dependency conflicts for Flutter application developers.
///  - Increased maintenance burden to keep dependencies up to date and secure.
///  - Increased risk of breaking changes from upstream packages.
///  - Increased attack surface for supply chain attacks.
///
///  Instead of adding new external dependencies, consider if the functionality
///  can be implemented directly in the Flutter framework.
///
///  For any new external dependency, ensure that it is published by a trusted
///  source, has a strong maintenance history, and has a stable API.
final List<String> allowedExternalPackages = <String>[
  'async',
  'boolean_selector',
  'characters',
  'clock',
  'collection',
  'fake_async',
  'intl',
  'leak_tracker',
  'leak_tracker_flutter_testing',
  'leak_tracker_testing',
  'matcher',
  'material_color_utilities',
  'meta',
  'path',
  'sky_engine',
  'source_span',
  'stack_trace',
  'stream_channel',
  'string_scanner',
  'term_glyph',
  'test_api',
  'vector_math',
  'vm_service',
];

Future<void> main() async {
  test('only allowed dependencies are used in flutter framework packages', () {
    // This test will explore the dependency graph of the current resolution.
    // Newer versions of packages may add new dependencies, this test cannot.
    // protect against that.
    final String flutterRoot = Platform.environment['FLUTTER_ROOT']!;

    // We assume that `pub get` has already been run and the
    // .dart_tool/package_graph.json file is available.
    final packageGraphFile = File.fromUri(
      Directory(flutterRoot).uri.resolve('.dart_tool/package_graph.json'),
    );
    final packageGraph = jsonDecode(packageGraphFile.readAsStringSync()) as Map<String, Object?>;

    // These are the sdk packages that Flutter apps can depend on.
    final roots = <String>['flutter', 'flutter_test', 'flutter_localizations'];
    final allowedPackages = <String>{
      // Allow depending on other Flutter framework sdk packages.
      ...roots,
      // Allow depending on allowed external packages.
      ...allowedExternalPackages,
    };
    final packages = packageGraph['packages']! as List<Object?>;
    final packagesByName = <String, Map<String, Object?>>{
      for (final package in packages)
        (package! as Map<String, Object?>)['name']! as String: package as Map<String, Object?>,
    };

    // Do a transitive parse of the package graph rooted in `roots` to find any
    // disallowed dependencies.
    final toVisit = <String?>[...roots];
    final visited = <String>{};
    final stack = <String>[];
    while (toVisit.isNotEmpty) {
      final String? currentName = toVisit.removeLast();
      if (currentName == null) {
        stack.removeLast();
        continue;
      }
      if (!visited.add(currentName)) {
        continue;
      }
      if (!allowedPackages.contains(currentName)) {
        stdout.writeln('Package "$currentName" is not in the allowed dependencies list.');
        stdout.writeln('Dependency chain: ${[...stack, currentName].join(' -> ')}');
        fail('''
Package "$currentName" is not in the allowed dependencies list.

Either remove the dependency or add it to the allowed dependencies list:
  packages/flutter_tools/test/integration.shard/only_allowed_dependencies_test.dart
''');
      }
      final Map<String, Object?> currentPackage = packagesByName[currentName]!;
      final dependencies = currentPackage['dependencies']! as List<Object?>;
      toVisit.add(null); // Marker for when we are done with this package.
      toVisit.addAll(dependencies.cast<String>());
      stack.add(currentName);
    }
    final List<String> unusedAllowedPackages = allowedExternalPackages.where((String package) {
      return !visited.contains(package);
    }).toList();
    if (unusedAllowedPackages.isNotEmpty) {
      fail('''
Some allowed packages are not used from any sdk framework packages.
Either use them or remove them from the allowlist:
${unusedAllowedPackages.map((String package) => ' - $package').join('\n')}

See: packages/flutter_tools/test/integration.shard/only_allowed_dependencies_test.dart
''');
    }
  });
}
