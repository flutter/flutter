// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/macos/native_assets_host.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:hooks_runner/hooks_runner.dart';

import '../../../src/common.dart';

void main() {
  test('framework name', () {
    expect(frameworkUri('libfoo.dylib', <String>{}), equals(Uri.file('foo.framework/foo')));
    expect(frameworkUri('foo', <String>{}), equals(Uri.file('foo.framework/foo')));
    expect(frameworkUri('foo_foo', <String>{}), equals(Uri.file('foo_foo.framework/foo_foo')));
    expect(frameworkUri('foo-foo', <String>{}), equals(Uri.file('foo-foo.framework/foo-foo')));
    expect(frameworkUri(r'foo$foo', <String>{}), equals(Uri.file('foofoo.framework/foofoo')));
    expect(frameworkUri('foo.foo', <String>{}), equals(Uri.file('foo.foo.framework/foo.foo')));
    expect(
      frameworkUri('foo.1.2.3', <String>{}),
      equals(Uri.file('foo.1.2.3.framework/foo.1.2.3')),
    );
    expect(
      frameworkUri('libatoolongfilenameforaframework.dylib', <String>{}),
      equals(Uri.file('atoolongfilenameforaframework.framework/atoolongfilenameforaframework')),
    );
  });

  test('framework name conflicts', () {
    final alreadyTakenNames = <String>{};
    expect(frameworkUri('libfoo.dylib', alreadyTakenNames), equals(Uri.file('foo.framework/foo')));
    expect(
      frameworkUri('libfoo.dylib', alreadyTakenNames),
      equals(Uri.file('foo1.framework/foo1')),
    );
    expect(
      frameworkUri('libfoo.dylib', alreadyTakenNames),
      equals(Uri.file('foo2.framework/foo2')),
    );
    expect(
      frameworkUri('libatoolongfilenameforaframework.dylib', alreadyTakenNames),
      equals(Uri.file('atoolongfilenameforaframework.framework/atoolongfilenameforaframework')),
    );
    expect(
      frameworkUri('libatoolongfilenameforaframework.dylib', alreadyTakenNames),
      equals(Uri.file('atoolongfilenameforaframework1.framework/atoolongfilenameforaframework1')),
    );
    expect(
      frameworkUri('libatoolongfilenameforaframework.dylib', alreadyTakenNames),
      equals(Uri.file('atoolongfilenameforaframework2.framework/atoolongfilenameforaframework2')),
    );
  });

  group('parseOtoolArchitectureSections', () {
    test('single architecture', () {
      expect(
        parseOtoolArchitectureSections('''
/build/native_assets/ios/buz.framework/buz (architecture x86_64):
@rpath/libfoo.dylib
'''),
        <Architecture, List<String>>{
          Architecture.x64: <String>['@rpath/libfoo.dylib'],
        },
      );
    });

    test('single architecture but not specified', () {
      expect(
        parseOtoolArchitectureSections('''
/build/native_assets/ios/buz.framework/buz:
@rpath/libfoo.dylib
'''),
        <Architecture?, List<String>>{
          null: <String>['@rpath/libfoo.dylib'],
        },
      );
    });

    test('multiple architectures', () {
      expect(
        parseOtoolArchitectureSections('''
/build/native_assets/ios/buz.framework/buz (architecture x86_64):
@rpath/libfoo.dylib
/build/native_assets/ios/buz.framework/buz (architecture arm64):
@rpath/libbar.dylib
'''),
        <Architecture, List<String>>{
          Architecture.x64: <String>['@rpath/libfoo.dylib'],
          Architecture.arm64: <String>['@rpath/libbar.dylib'],
        },
      );
    });

    test('multiple lines in section', () {
      expect(
        parseOtoolArchitectureSections('''
/build/native_assets/ios/buz.framework/buz (architecture x86_64):
@rpath/libfoo.dylib
@rpath/libbar.dylib
'''),
        <Architecture, List<String>>{
          Architecture.x64: <String>['@rpath/libfoo.dylib', '@rpath/libbar.dylib'],
        },
      );
    });

    test('trim each line in section', () {
      expect(
        parseOtoolArchitectureSections('''
/build/native_assets/ios/buz.framework/buz (architecture x86_64):
  @rpath/libfoo.dylib
'''),
        <Architecture, List<String>>{
          Architecture.x64: <String>['@rpath/libfoo.dylib'],
        },
      );
    });
  });

  test('fatAssetTargetLocations ignores cross-architecture conflicts', () {
    final asset1 = FlutterCodeAsset(
      codeAsset: CodeAsset(
        package: 'my_package',
        name: 'my_asset',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file('libmy_asset.dylib'),
      ),
      target: Target.fromString('macos_arm64'),
    );
    final asset2 = FlutterCodeAsset(
      codeAsset: CodeAsset(
        package: 'my_package',
        name: 'my_asset',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file('libmy_asset.dylib'),
      ),
      target: Target.fromString('macos_x64'),
    );

    final Map<KernelAssetPath, List<FlutterCodeAsset>> result = fatAssetTargetLocations(
      <FlutterCodeAsset>[asset1, asset2],
      (FlutterCodeAsset asset, Set<String> alreadyTakenNames) {
        final String fileName = asset.codeAsset.file!.pathSegments.last;
        final Uri uri = frameworkUri(fileName, alreadyTakenNames);
        return KernelAsset(
          id: asset.codeAsset.id,
          target: asset.target,
          path: KernelAssetAbsolutePath(uri),
        );
      },
    );

    expect(result.length, equals(1));
    final KernelAssetPath path = result.keys.single;
    expect((path as KernelAssetAbsolutePath).uri.path, equals('my_asset.framework/my_asset'));
    expect(result[path]!.length, equals(2));
  });

  test('fatAssetTargetLocations handles conflicts between different assets', () {
    final assetA1 = FlutterCodeAsset(
      codeAsset: CodeAsset(
        package: 'package_a',
        name: 'my_asset',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file('libfoo.dylib'),
      ),
      target: Target.fromString('macos_arm64'),
    );
    final assetB1 = FlutterCodeAsset(
      codeAsset: CodeAsset(
        package: 'package_b',
        name: 'my_asset',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file('libfoo.dylib'),
      ),
      target: Target.fromString('macos_arm64'),
    );
    final assetA2 = FlutterCodeAsset(
      codeAsset: CodeAsset(
        package: 'package_a',
        name: 'my_asset',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file('libfoo.dylib'),
      ),
      target: Target.fromString('macos_x64'),
    );
    final assetB2 = FlutterCodeAsset(
      codeAsset: CodeAsset(
        package: 'package_b',
        name: 'my_asset',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file('libfoo.dylib'),
      ),
      target: Target.fromString('macos_x64'),
    );

    final Map<KernelAssetPath, List<FlutterCodeAsset>> result = fatAssetTargetLocations(
      <FlutterCodeAsset>[assetA1, assetB1, assetA2, assetB2],
      (FlutterCodeAsset asset, Set<String> alreadyTakenNames) {
        final String fileName = asset.codeAsset.file!.pathSegments.last;
        final Uri uri = frameworkUri(fileName, alreadyTakenNames);
        return KernelAsset(
          id: asset.codeAsset.id,
          target: asset.target,
          path: KernelAssetAbsolutePath(uri),
        );
      },
    );

    expect(result.length, equals(2));

    final KernelAssetPath pathA = result.keys.firstWhere(
      (k) => (k as KernelAssetAbsolutePath).uri.path == 'foo.framework/foo',
    );
    final KernelAssetPath pathB = result.keys.firstWhere(
      (k) => (k as KernelAssetAbsolutePath).uri.path == 'foo1.framework/foo1',
    );

    expect(result[pathA]!.length, equals(2));
    expect(result[pathA]!.contains(assetA1), isTrue);
    expect(result[pathA]!.contains(assetA2), isTrue);

    expect(result[pathB]!.length, equals(2));
    expect(result[pathB]!.contains(assetB1), isTrue);
    expect(result[pathB]!.contains(assetB2), isTrue);
  });
}
