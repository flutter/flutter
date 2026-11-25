// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../localization/bin/gen_missing_localizations.dart';

void main() {
  late Directory directory;

  File writeArb(String locale, Map<String, String> resources) {
    return File(path.join(directory.path, 'material_$locale.arb'))
      ..writeAsStringSync(jsonEncode(resources));
  }

  setUp(() {
    directory = Directory.systemTemp.createTempSync('gen_missing_localizations_test.');
    addTearDown(() => directory.deleteSync(recursive: true));
    writeArb('en', <String, String>{
      'cancelButtonLabel': 'Cancel',
      'closeButtonLabel': 'Close',
      'selectedRowCountTitleOther': r'$selectedRowCount items selected',
    });
  });

  test('removes obsolete resources from a regional bundle without adding fallback strings', () {
    final File regional = writeArb('en_GB', <String, String>{
      'cancelButtonLabel': 'Cancel selection',
      'obsoleteLabel': 'Obsolete',
    });

    updateMissingResources(directory.path, 'material', removeUndefined: true);

    expect(jsonDecode(regional.readAsStringSync()), <String, String>{
      'cancelButtonLabel': 'Cancel selection',
    });
  });

  test('keeps a script locale plural when its default form is inherited', () {
    writeArb('sr', <String, String>{
      'selectedRowCountTitleOther': r'Изабрано је $selectedRowCount ставки',
    });
    final File script = writeArb('sr_Latn', <String, String>{
      'selectedRowCountTitleFew': r'Izabrane su $selectedRowCount stavke',
      'obsoleteLabel': 'Obsolete',
    });

    updateMissingResources(directory.path, 'material', removeUndefined: true);

    expect(jsonDecode(script.readAsStringSync()), <String, String>{
      'selectedRowCountTitleFew': r'Izabrane su $selectedRowCount stavke',
    });
  });

  test('adds missing resources to base bundles and leaves regional bundles alone by default', () {
    final File base = writeArb('de', <String, String>{'cancelButtonLabel': 'Abbrechen'});
    final File regional = writeArb('de_CH', <String, String>{'obsoleteLabel': 'Obsolete'});
    final String original = regional.readAsStringSync();

    updateMissingResources(directory.path, 'material');

    expect(jsonDecode(base.readAsStringSync()), containsPair('closeButtonLabel', 'Close'));
    expect(regional.readAsStringSync(), original);
  });
}
