// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/deferred_component.dart';

import '../../src/common.dart';

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
  });
}
