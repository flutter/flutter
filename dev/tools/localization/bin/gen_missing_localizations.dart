// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This program updates the language locale arb files with any missing resource
// entries that are included in the English arb files. This is useful when
// adding new resources for localization. You can just add the appropriate
// entries to the English arb file and then run this script. It will then check
// all of the other language locale arb files and update them with the English
// source for any missing resources. These will be picked up by the localization
// team and then translated.
//
// ## Usage
//
// Run this program from the root of the git repository.
//
// ```
// dart dev/tools/localization/bin/gen_missing_localizations.dart
// ```
//
// Add the '--remove-undefined' flag to also remove resources that are no
// longer in the English arb files from all of the other locale arb files,
// including the regional and script ones (for example, `material_en_GB.arb`).
//
// ```
// dart dev/tools/localization/bin/gen_missing_localizations.dart --remove-undefined
// ```

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../localizations_utils.dart';
import '../localizations_validator.dart';

Future<void> main(List<String> rawArgs) async {
  var removeUndefined = false;
  if (rawArgs.contains('--remove-undefined')) {
    removeUndefined = true;
  }
  checkCwdIsRepoRoot('gen_missing_localizations');

  final String localizationPath = path.join(
    'packages',
    'flutter_localizations',
    'lib',
    'src',
    'l10n',
  );
  updateMissingResources(localizationPath, 'material', removeUndefined: removeUndefined);
  updateMissingResources(localizationPath, 'cupertino', removeUndefined: removeUndefined);
  updateMissingResources(localizationPath, 'widgets', removeUndefined: removeUndefined);
}

Map<String, dynamic> loadBundle(File file) {
  if (!FileSystemEntity.isFileSync(file.path)) {
    exitWithError('Unable to find input file: ${file.path}');
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

void writeBundle(File file, Map<String, dynamic> bundle) {
  final contents = StringBuffer();
  contents.writeln('{');
  for (final String key in bundle.keys) {
    contents.writeln('  "$key": ${json.encode(bundle[key])}${key == bundle.keys.last ? '' : ','}');
  }
  contents.writeln('}');
  file.writeAsStringSync(contents.toString());
}

Set<String> resourceKeys(Map<String, dynamic> bundle) {
  return Set<String>.from(
    // Skip any attribute keys
    bundle.keys.where((String key) => !key.startsWith('@')),
  );
}

bool intentionallyOmitted(String key, Map<String, dynamic> bundle) {
  final attributeKey = '@$key';
  final dynamic attribute = bundle[attributeKey];
  return attribute is Map && attribute.containsKey('notUsed');
}

/// Whether `key` corresponds to one of the plural variations of a key with
/// the same prefix and suffix "Other".
bool isPluralVariation(String key, Map<String, dynamic> bundle) {
  final Match? pluralMatch = kPluralRegexp.firstMatch(key);
  if (pluralMatch == null) {
    return false;
  }
  final String prefix = pluralMatch[1]!;
  return bundle.containsKey('${prefix}Other');
}

/// Adds the resources of the `<groupPrefix>_en.arb` file that are missing from
/// the language-level locale files in `localizationPath`, using the English
/// strings as placeholders.
///
/// Regional and script locale files, such as `<groupPrefix>_en_GB.arb` or
/// `<groupPrefix>_sr_Latn.arb`, are not filled in, because their missing
/// resources fall back to the language-level locale.
///
/// If `removeUndefined` is true, resources that are no longer defined in the
/// English file are also removed from every locale file, including the
/// regional and script ones.
void updateMissingResources(
  String localizationPath,
  String groupPrefix, {
  bool removeUndefined = false,
}) {
  final localizationDir = Directory(localizationPath);
  final filenamePattern = RegExp('${groupPrefix}_(\\w+)\\.arb');

  final Map<String, dynamic> englishBundle = loadBundle(
    File(path.join(localizationPath, '${groupPrefix}_en.arb')),
  );
  final Set<String> requiredKeys = resourceKeys(englishBundle);

  for (final FileSystemEntity entity
      in localizationDir.listSync().toList()..sort(sortFilesByPath)) {
    final String entityPath = entity.path;
    if (FileSystemEntity.isFileSync(entityPath) && filenamePattern.hasMatch(entityPath)) {
      final String localeString = filenamePattern.firstMatch(entityPath)![1]!;
      final locale = LocaleInfo.fromString(localeString);

      final isBaseLocale = locale.length == 1;
      if (isBaseLocale || removeUndefined) {
        final arbFile = File(entityPath);
        final Map<String, dynamic> localeBundle = loadBundle(arbFile);
        final Set<String> localeResources = resourceKeys(localeBundle);
        // Whether or not the resources were modified and need to be updated.
        var shouldWrite = false;

        // Remove any localizations that are not defined in the canonical
        // locale. This allows unused localizations to be removed if
        // --remove-undefined is passed.
        if (removeUndefined) {
          bool isIncluded(String key) {
            // Check plural variations against the canonical locale, so the
            // variations of a removed plural are removed too.
            return !isPluralVariation(key, englishBundle) &&
                !intentionallyOmitted(key, localeBundle);
          }

          // Find any resources in this locale that don't appear in the
          // canonical locale, and skipping any which should not be included
          // (plurals and intentionally omitted).
          final Set<String> extraResources = localeResources
              .difference(requiredKeys)
              .where(isIncluded)
              .toSet();

          // Remove them.
          localeBundle.removeWhere((String key, dynamic value) {
            final bool found = extraResources.contains(key);
            if (found) {
              shouldWrite = true;
            }
            return found;
          });
          if (shouldWrite) {
            print('Updating $entityPath by removing extra entries for $extraResources');
          }
        }

        // Regional and script bundles inherit strings from their parent locale.
        if (isBaseLocale) {
          // Add in any resources that are in the canonical locale and not present
          // in this locale.
          final Set<String> missingResources = requiredKeys
              .difference(localeResources)
              .where(
                (String key) =>
                    !isPluralVariation(key, localeBundle) &&
                    !intentionallyOmitted(key, localeBundle),
              )
              .toSet();
          if (missingResources.isNotEmpty) {
            localeBundle.addEntries(
              missingResources.map(
                (String k) => MapEntry<String, String>(k, englishBundle[k].toString()),
              ),
            );
            shouldWrite = true;
            print('Updating $entityPath with missing entries for $missingResources');
          }
        }
        if (shouldWrite) {
          writeBundle(arbFile, localeBundle);
        }
      }
    }
  }
}
