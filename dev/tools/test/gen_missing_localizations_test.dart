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

  Map<String, dynamic> readArb(File file) {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  setUp(() {
    directory = Directory.systemTemp.createTempSync('gen_missing_localizations_test.');
    addTearDown(() => directory.deleteSync(recursive: true));
    writeArb('en', <String, String>{
      'cancelButtonLabel': 'Cancel',
      'closeButtonLabel': 'Close',
      'selectedRowCountTitleOne': '1 item selected',
      'selectedRowCountTitleOther': r'$selectedRowCount items selected',
    });
  });

  test('removes obsolete resources from a regional bundle without adding fallback strings', () {
    final File regional = writeArb('en_GB', <String, String>{
      'cancelButtonLabel': 'Cancel selection',
      'obsoleteLabel': 'Obsolete',
    });

    updateMissingResources(directory.path, 'material', removeUndefined: true);

    expect(readArb(regional), <String, String>{'cancelButtonLabel': 'Cancel selection'});
  });

  test('keeps plural variations whose default form is in the English bundle', () {
    final File base = writeArb('sr', <String, String>{
      'cancelButtonLabel': 'Откажи',
      'closeButtonLabel': 'Затвори',
      'selectedRowCountTitleFew': r'Изабране су $selectedRowCount ставке',
      'selectedRowCountTitleOther': r'Изабрано је $selectedRowCount ставки',
    });
    final File script = writeArb('sr_Latn', <String, String>{
      'selectedRowCountTitleFew': r'Izabrane su $selectedRowCount stavke',
      'selectedRowCountTitleOther': r'Izabrano je $selectedRowCount stavki',
    });
    final String originalBase = base.readAsStringSync();
    final String originalScript = script.readAsStringSync();

    updateMissingResources(directory.path, 'material', removeUndefined: true);

    expect(base.readAsStringSync(), originalBase);
    expect(script.readAsStringSync(), originalScript);
  });

  test('removes every variation of a plural that was removed from the English bundle', () {
    final File base = writeArb('de', <String, String>{
      'cancelButtonLabel': 'Abbrechen',
      'closeButtonLabel': 'Schließen',
      'selectedRowCountTitleOne': '1 Element ausgewählt',
      'selectedRowCountTitleOther': r'$selectedRowCount Elemente ausgewählt',
      'removedCountOne': '1 Element',
      'removedCountOther': r'$removedCount Elemente',
    });
    final File regional = writeArb('de_CH', <String, String>{
      'removedCountOne': '1 Element',
      'removedCountOther': r'$removedCount Elemente',
    });

    updateMissingResources(directory.path, 'material', removeUndefined: true);

    expect(
      readArb(base).keys,
      isNot(anyOf(contains('removedCountOne'), contains('removedCountOther'))),
    );
    expect(readArb(regional), isEmpty);
  });

  test('adds missing resources to base bundles and leaves regional bundles alone by default', () {
    final File base = writeArb('de', <String, String>{'cancelButtonLabel': 'Abbrechen'});
    final File regional = writeArb('de_CH', <String, String>{'obsoleteLabel': 'Obsolete'});
    final String original = regional.readAsStringSync();

    updateMissingResources(directory.path, 'material');

    expect(readArb(base), containsPair('closeButtonLabel', 'Close'));
    expect(regional.readAsStringSync(), original);
  });
}
