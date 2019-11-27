// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This program replaces the material_kn.arb and cupertino_kn.arb
// files in flutter_localizations/packages/lib/src/l10n with versions
// where the contents of the localized strings have been replaced by JSON
// escapes. This is done because some of those strings contain characters
// that can crash Emacs on Linux. There is more information
// here: https://github.com/flutter/flutter/issues/36704 and in the README
// in flutter_localizations/packages/lib/src/l10n.
//
// This app needs to be run by hand when material_kn.arb or cupertino_kn.arb
// have been updated.
//
// ## Usage
//
// Run this program from the root of the git repository.
//
// ```
// dart dev/tools/localization/encode_kn_arb_files.dart
// ```

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'localizations_utils.dart';

Map<String, dynamic> loadBundle(File file) {
  if (!FileSystemEntity.isFileSync(file.path))
    exitWithError('Unable to find input file: ${file.path}');
  return json.decode(file.readAsStringSync());
}

void encodeBundleTranslations(Map<String, dynamic> bundle) {
  for (String key in bundle.keys) {
    // The ARB file resource "attributes" for foo are called @foo. Don't need
    // to encode them.
    if (key.startsWith('@'))
      continue;
    final String translation = bundle[key];
    // Rewrite the string as a series of unicode characters in JSON format.
    // Like "\u0012\u0123\u1234".
    bundle[key] = translation.runes.map((int code) {
      final String codeString = '00${code.toRadixString(16)}';
      return '\\u${codeString.substring(codeString.length - 4)}';
    }).join();
  }
}

void checkEncodedTranslations(Map<String, dynamic> encodedBundle, Map<String, dynamic> bundle) {
  bool errorFound = false;
  const JsonDecoder decoder = JsonDecoder();
  for (String key in bundle.keys) {
    if (decoder.convert('"${encodedBundle[key]}"') != bundle[key]) {
      stderr.writeln('  encodedTranslation for $key does not match original value "${bundle[key]}"');
      errorFound = true;
    }
  }
  if (errorFound)
    exitWithError('JSON unicode translation encoding failed');
}

void rewriteBundle(File file, Map<String, dynamic> bundle) {
  final StringBuffer contents = StringBuffer();
  contents.writeln('{');
  for (String key in bundle.keys) {
    contents.writeln('  "$key": "${bundle[key]}"${key == bundle.keys.last ? '' : ','}');
  }
  contents.writeln('}');
  file.writeAsStringSync(contents.toString());
}

Future<void> main(List<String> rawArgs) async {
  checkCwdIsRepoRoot('encode_kn_arb_files');

  final String l10nPath = path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n');
  final File materialArbFile = File(path.join(l10nPath, 'material_kn.arb'));
  final File cupertinoArbFile = File(path.join(l10nPath, 'cupertino_kn.arb'));

  final Map<String, dynamic> materialBundle = loadBundle(materialArbFile);
  final Map<String, dynamic> cupertinoBundle = loadBundle(cupertinoArbFile);

  encodeBundleTranslations(materialBundle);
  encodeBundleTranslations(cupertinoBundle);

  checkEncodedTranslations(materialBundle, loadBundle(materialArbFile));
  checkEncodedTranslations(cupertinoBundle, loadBundle(cupertinoArbFile));

  rewriteBundle(materialArbFile, materialBundle);
  rewriteBundle(cupertinoArbFile, cupertinoBundle);
}
