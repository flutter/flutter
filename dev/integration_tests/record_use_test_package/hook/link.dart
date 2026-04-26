// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:record_use/record_use.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    final EncodedAsset? translationAsset = _findTranslationAsset(input);

    if (translationAsset == null) {
      return;
    }

    output.dependencies.add(translationAsset.asDataAsset.file);

    final Recordings? recordings = await input.recordings;
    if (recordings == null) {
      // Record use not enabled, return full translations file.
      output.assets.data.add(translationAsset.asDataAsset);
      return;
    }

    final Set<String> usedPhrases = _extractUsedPhrases(recordings);
    final Map<String, dynamic> allTranslations = await _loadTranslations(translationAsset);
    final Map<String, dynamic> filteredTranslations = _filterTranslations(
      allTranslations,
      usedPhrases,
    );

    await _writeOutputAsset(input, output, filteredTranslations);
  });
}

extension on LinkInput {
  Future<Recordings?> get recordings async {
    // ignore: experimental_member_use
    final Uri? recordedUsagesFile = this.recordedUsagesFile;
    if (recordedUsagesFile == null) {
      return null;
    }

    final String content = await File.fromUri(recordedUsagesFile).readAsString();
    return Recordings.fromJson(jsonDecode(content) as Map<String, Object?>);
  }
}

EncodedAsset? _findTranslationAsset(LinkInput input) => input.assets.encodedAssets
    .where(
      (a) =>
          a.isDataAsset &&
          a.asDataAsset.id == 'package:${input.packageName}/data/translations.json',
    )
    .firstOrNull;

Set<String> _extractUsedPhrases(Recordings recordings) {
  final usedPhrases = <String>{};
  const translateDef = Method(
    'translate',
    Library('package:record_use_test_package/record_use_test_package.dart'),
  );

  for (final CallReference call in recordings.calls[translateDef] ?? const <CallReference>[]) {
    switch (call) {
      case CallWithArguments(
          positionalArguments: [StringConstant(:final value), ...],
        ):
        usedPhrases.add(value);
      case _:
        throw UnsupportedError('Cannot determine which translations are used.');
    }
  }
  return usedPhrases;
}

Future<Map<String, dynamic>> _loadTranslations(EncodedAsset asset) async {
  final Uri file = asset.asDataAsset.file;
  return jsonDecode(await File.fromUri(file).readAsString()) as Map<String, dynamic>;
}

Map<String, dynamic> _filterTranslations(
  Map<String, dynamic> allTranslations,
  Set<String> usedPhrases,
) =>
    {
      for (final entry in allTranslations.entries)
        if (usedPhrases.contains(entry.key)) entry.key: entry.value,
    };

Future<void> _writeOutputAsset(
  LinkInput input,
  LinkOutputBuilder output,
  Map<String, dynamic> content,
) async {
  final Uri filteredFile = input.outputDirectory.resolve(
    'filtered_translations.json',
  );
  await File.fromUri(filteredFile).writeAsString(jsonEncode(content));

  output.assets.data.add(
    DataAsset(
      package: input.packageName,
      name: 'data/translations.json',
      file: filteredFile,
    ),
  );
}
