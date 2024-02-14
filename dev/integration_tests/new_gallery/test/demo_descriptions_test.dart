// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/data/demos.dart';

bool _isUnique(List<String> list) {
  final covered = <String>{};
  for (final element in list) {
    if (covered.contains(element)) {
      return false;
    } else {
      covered.add(element);
    }
  }
  return true;
}

const _stringListEquality = ListEquality<String>();

void main() {
  test('_isUnique works correctly', () {
    expect(_isUnique(['a', 'b', 'c']), true);
    expect(_isUnique(['a', 'c', 'a', 'b']), false);
    expect(_isUnique(['a']), true);
    expect(_isUnique([]), true);
  });

  test('Demo descriptions are unique and correct', () {
    final allDemos = Demos.all(GalleryLocalizationsEn());
    final allDemoDescriptions = allDemos.map((d) => d.describe).toList();

    expect(_isUnique(allDemoDescriptions), true);
    expect(
      _stringListEquality.equals(
        allDemoDescriptions,
        Demos.allDescriptions(),
      ),
      true,
    );
  });

  test('Special demo descriptions are correct', () {
    final allDemos = Demos.allDescriptions();

    final specialDemos = <String>[
      'shrine@study',
      'rally@study',
      'crane@study',
      'fortnightly@study',
      'bottom-navigation@material',
      'button@material',
      'card@material',
      'chip@material',
      'dialog@material',
      'pickers@material',
      'cupertino-alerts@cupertino',
      'colors@other',
      'progress-indicator@material',
      'cupertino-activity-indicator@cupertino',
      'colors@other',
    ];

    for (final specialDemo in specialDemos) {
      expect(allDemos.contains(specialDemo), true);
    }
  });
}
