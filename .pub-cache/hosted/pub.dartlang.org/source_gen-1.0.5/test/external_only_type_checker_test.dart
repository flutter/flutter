// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file are only ran externally, as the behavior only works
// externally. Internally this test is skipped.

// Increase timeouts on this test which resolves source code and can be slow.
@Timeout.factor(2.0)
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  // Resolved top-level types from package:source_gen.
  late InterfaceType staticNonPublic;
  late TypeChecker staticNonPublicChecker;

  setUpAll(() async {
    late LibraryReader thisTest;
    await resolveSource(r'''
      export 'type_checker_test.dart' show NonPublic;
    ''', (resolver) async {
      thisTest = LibraryReader(await resolver.libraryFor(
          AssetId('source_gen', 'test/external_only_type_checker_test.dart')));
    }, inputId: AssetId('source_gen', 'test/example.dart'));

    staticNonPublic = thisTest.findType('NonPublic')!.instantiate(
        typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
    staticNonPublicChecker = TypeChecker.fromStatic(staticNonPublic);
  });

  // Run a common set of type comparison checks with various implementations.
  void commonTests({
    required TypeChecker Function() checkNonPublic,
  }) {
    group('NonPublic', () {
      test('should equal NonPublic', () {
        expect(checkNonPublic().isExactlyType(staticNonPublic), isTrue,
            reason: '${checkNonPublic()} != ${staticNonPublic.element.name}');
      });

      test('should be assignable from NonPublic', () {
        expect(checkNonPublic().isAssignableFromType(staticNonPublic), isTrue,
            reason: '${checkNonPublic()} is not assignable from '
                '${staticNonPublic.element.name}');
      });
    });
  }

  group('TypeChecker.forRuntime', () {
    commonTests(
      checkNonPublic: () => const TypeChecker.fromRuntime(NonPublic),
    );
  });

  group('TypeChecker.forStatic', () {
    commonTests(
      checkNonPublic: () => staticNonPublicChecker,
    );
  });

  group('TypeChecker.fromUrl', () {
    commonTests(
      checkNonPublic: () => const TypeChecker.fromUrl(
          'asset:source_gen/test/external_only_type_checker_test.dart#NonPublic'),
    );
  });
}

// Used to check identity of non-public classes
class NonPublic {}
