// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/deferred_component.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('DeferredComponent basics', () {
    test('constructor sets values', () {
      final DeferredComponent component = DeferredComponent(
        name: 'bestcomponent',
        libraries: <String>['lib1', 'lib2'],
        assets: <Uri>[Uri.file('asset1'), Uri.file('asset2')],
      );
      expect(component.name, 'bestcomponent');
      expect(component.libraries, <String>['lib1', 'lib2']);
      expect(component.assets, <Uri>[Uri.file('asset1'), Uri.file('asset2')]);
    });

    test('assignLoadingUnits', () {
      final DeferredComponent component = DeferredComponent(
        name: 'bestcomponent',
        libraries: <String>['lib1', 'lib2'],
        assets: <Uri>[Uri.file('asset1'), Uri.file('asset2')],
      );
      expect(component.libraries, <String>['lib1', 'lib2']);
      expect(component.assigned, false);
      expect(component.loadingUnits, null);

      final List<LoadingUnit> loadingUnits1 = <LoadingUnit>[
        LoadingUnit(
          id: 2,
          path: 'path/to/so.so',
          libraries: <String>['lib1', 'lib4'],
        ),
        LoadingUnit(
          id: 3,
          path: 'path/to/so.so',
          libraries: <String>['lib2', 'lib5'],
        ),
        LoadingUnit(
          id: 4,
          path: 'path/to/so.so',
          libraries: <String>['lib6', 'lib7'],
        ),
      ];

      component.assignLoadingUnits(loadingUnits1);

      expect(component.assigned, true);
      expect(component.loadingUnits.length, 2);
      expect(component.loadingUnits.contains(loadingUnits1[0]), true);
      expect(component.loadingUnits.contains(loadingUnits1[1]), true);
      expect(component.loadingUnits.contains(loadingUnits1[2]), false);

      final List<LoadingUnit> loadingUnits2 = <LoadingUnit>[
        LoadingUnit(
          id: 2,
          path: 'path/to/so.so',
          libraries: <String>['lib1', 'lib2'],
        ),
        LoadingUnit(
          id: 3,
          path: 'path/to/so.so',
          libraries: <String>['lib5', 'lib6'],
        ),
        LoadingUnit(
          id: 4,
          path: 'path/to/so.so',
          libraries: <String>['lib7', 'lib8'],
        ),
      ];
      // Can reassign loading units.
      component.assignLoadingUnits(loadingUnits2);

      expect(component.assigned, true);
      expect(component.loadingUnits.length, 1);
      expect(component.loadingUnits.contains(loadingUnits2[0]), true);
      expect(component.loadingUnits.contains(loadingUnits2[1]), false);
      expect(component.loadingUnits.contains(loadingUnits2[2]), false);

      component.assignLoadingUnits(<LoadingUnit>[]);

      expect(component.assigned, true);
      expect(component.loadingUnits.length, 0);
    });
  });

  group('LoadingUnit basics', () {
    test('constructor sets values', () {
      final LoadingUnit unit = LoadingUnit(
        id: 2,
        path: 'path/to/so.so',
        libraries: <String>['lib1', 'lib4'],
      );
      expect(unit.id, 2);
      expect(unit.path, 'path/to/so.so');
      expect(unit.libraries, <String>['lib1', 'lib4']);
    });

    test('toString', () {
      final LoadingUnit unit = LoadingUnit(
        id: 2,
        path: 'path/to/so.so',
        libraries: <String>['lib1', 'lib4'],
      );
      expect(unit.toString(),'\nLoadingUnit 2\n  Libraries:\n  - lib1\n  - lib4'); 
    });

    test('equalsIgnoringPath', () {
      final LoadingUnit unit1 = LoadingUnit(
        id: 2,
        path: 'path/to/so.so',
        libraries: <String>['lib1', 'lib4'],
      );
      final LoadingUnit unit2 = LoadingUnit(
        id: 2,
        path: 'path/to/other/so.so',
        libraries: <String>['lib1', 'lib4'],
      );
      final LoadingUnit unit3 = LoadingUnit(
        id: 1,
        path: 'path/to/other/so.so',
        libraries: <String>['lib1', 'lib4'],
      );
      final LoadingUnit unit4 = LoadingUnit(
        id: 1,
        path: 'path/to/other/so.so',
        libraries: <String>['lib1'],
      );
      final LoadingUnit unit5 = LoadingUnit(
        id: 1,
        path: 'path/to/other/so.so',
        libraries: <String>['lib2'],
      );
      final LoadingUnit unit6 = LoadingUnit(
        id: 1,
        path: 'path/to/other/so.so',
        libraries: <String>['lib1', 'lib5'],
      );
      expect(unit1.equalsIgnoringPath(unit2), true); 
      expect(unit2.equalsIgnoringPath(unit3), false); 
      expect(unit3.equalsIgnoringPath(unit4), false); 
      expect(unit4.equalsIgnoringPath(unit5), false); 
      expect(unit5.equalsIgnoringPath(unit6), false);
    });

    test('parseLoadingUnitManifest', () {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File manifest = fileSystem.file('/manifest.json');
      manifest.createSync(recursive: true);
      manifest.writeAsStringSync(r'''
{ "loadingUnits": [
{ "id": 1, "path": "\/arm64-v8a\/app.so", "libraries": [
"dart:core"]}
,
{ "id": 2, "path": "\/arm64-v8a\/app.so-2.part.so", "libraries": [
"lib2"]}
,
{ "id": 3, "path": "\/arm64-v8a\/app.so-3.part.so", "libraries": [
"lib3", "lib4"]}
] }

''', flush: true);
      final List<LoadingUnit> loadingUnits = LoadingUnit.parseLoadingUnitManifest(manifest);
      expect(loadingUnits.length, 2); // base module (id 1) is not parsed.
      expect(loadingUnits[0].id, 2);
      expect(loadingUnits[0].path, '/arm64-v8a/app.so-2.part.so');
      expect(loadingUnits[0].libraries.length, 1);
      expect(loadingUnits[0].libraries[0], 'lib2');
      expect(loadingUnits[1].id, 3);
      expect(loadingUnits[1].path, '/arm64-v8a/app.so-3.part.so');
      expect(loadingUnits[1].libraries.length, 2);
      expect(loadingUnits[1].libraries[0], 'lib3');
      expect(loadingUnits[1].libraries[1], 'lib4');
    });

    testUsingContext('parseLoadingUnitManifest invalid', () {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File manifest = fileSystem.file('/manifest.json');
      manifest.createSync(recursive: true);
      // invalid due to missing closing brace `}`
      manifest.writeAsStringSync(r'''
{ "loadingUnits": [
{ "id": 1, "path": "\/arm64-v8a\/app.so", "libraries": [
"dart:core"]}
,
{ "id": 2, "path": "\/arm64-v8a\/app.so-2.part.so", "libraries": [
"lib2"]}
,
{ "id": 3, "path": "\/arm64-v8a\/app.so-3.part.so", "libraries": [
"lib3", "lib4"]}
]

''', flush: true);
      final List<LoadingUnit> loadingUnits = LoadingUnit.parseLoadingUnitManifest(manifest);
      expect(loadingUnits.length, 0);
      expect(loadingUnits.isEmpty, true);
    });
  });
}
