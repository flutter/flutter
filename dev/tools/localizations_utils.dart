// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as argslib;
import 'package:meta/meta.dart';

/// Simple data class to hold parsed locale. Does not promise validity of any data.
class LocaleInfo implements Comparable<LocaleInfo> {
  LocaleInfo({
    this.languageCode,
    this.scriptCode,
    this.countryCode,
    this.length,
    this.originalString,
  });

  /// Simple parser. Expects the locale string to be in the form of 'language_script_COUNTRY'
  /// where the langauge is 2 characters, script is 4 characters with the first uppercase,
  /// and country is 2-3 characters and all uppercase.
  ///
  /// 'language_COUNTRY' or 'language_script' are also valid. Missing fields will be null.
  factory LocaleInfo.fromString(String locale, {bool assume = false}) {
    final List<String> codes = locale.split('_'); // [language, script, country]
    assert(codes.isNotEmpty && codes.length < 4);
    final String languageCode = codes[0];
    String scriptCode;
    String countryCode;
    int length = codes.length;
    String originalString = locale;
    if (codes.length == 2) {
      scriptCode = codes[1].length >= 4 ? codes[1] : null;
      countryCode = codes[1].length < 4 ? codes[1] : null;
    } else if (codes.length == 3) {
      scriptCode = codes[1].length > codes[2].length ? codes[1] : codes[2];
      countryCode = codes[1].length < codes[2].length ? codes[1] : codes[2];
    }
    assert(codes[0] != null && codes[0].isNotEmpty);
    assert(countryCode == null || countryCode.isNotEmpty);
    assert(scriptCode == null || scriptCode.isNotEmpty);

    /// Adds scriptCodes to locales where we are able to assume it to provide
    /// finer granularity when resolving locales.
    ///
    /// The basis of the assumptions here are based off of known usage of scripts
    /// across various countries. For example, we know Taiwan uses traditional (Hant)
    /// script, so it is safe to apply (Hant) to Taiwanese languages.
    if (assume && scriptCode == null) {
      switch (languageCode) {
        case 'zh': {
          if (countryCode == null) {
            scriptCode = 'Hans';
          }
          switch (countryCode) {
            case 'CN':
            case 'SG':
              scriptCode = 'Hans';
              break;
            case 'TW':
            case 'HK':
            case 'MO':
              scriptCode = 'Hant';
              break;
          }
          break;
        }
        case 'sr': {
          if (countryCode == null) {
            scriptCode = 'Cyrl';
          }
          break;
        }
      }
      // Increment length if we were able to assume a scriptCode.
      if (scriptCode != null) {
        length += 1;
      }
      // Update the base string to reflect assumed scriptCodes.
      originalString = languageCode;
      if (scriptCode != null)
        originalString += '_' + scriptCode;
      if (countryCode != null)
        originalString += '_' + countryCode;
    }

    return LocaleInfo(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
      length: length,
      originalString: originalString,
    );
  }

  final String languageCode;
  final String scriptCode;
  final String countryCode;
  final int length;             // The number of fields. Ranges from 1-3.
  final String originalString;  // Original un-parsed locale string.

  @override
  bool operator ==(Object other) {
    if (!(other is LocaleInfo))
      return false;
    final LocaleInfo otherLocale = other;
    return originalString == otherLocale.originalString;
  }

  @override
  int get hashCode {
    return originalString.hashCode;
  }

  @override
  String toString() {
    return originalString;
  }

  @override
  int compareTo(LocaleInfo other) {
    return originalString.compareTo(other.originalString);
  }
}

void exitWithError(String errorMessage) {
  assert(errorMessage != null);
  stderr.writeln('fatal: $errorMessage');
  exit(1);
}

void checkCwdIsRepoRoot(String commandName) {
  final bool isRepoRoot = Directory('.git').existsSync();

  if (!isRepoRoot) {
    exitWithError(
      '$commandName must be run from the root of the Flutter repository. The '
      'current working directory is: ${Directory.current.path}'
    );
  }
}

String camelCase(LocaleInfo locale) {
  return locale.originalString
    .split('_')
    .map<String>((String part) => part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase())
    .join('');
}

GeneratorOptions parseArgs(List<String> rawArgs) {
  final argslib.ArgParser argParser = argslib.ArgParser()
    ..addFlag(
      'overwrite',
      abbr: 'w',
      defaultsTo: false,
    );
  final argslib.ArgResults args = argParser.parse(rawArgs);
  final bool writeToFile = args['overwrite'];

  return GeneratorOptions(writeToFile: writeToFile);
}

class GeneratorOptions {
  GeneratorOptions({
    @required this.writeToFile,
  });

  final bool writeToFile;
}

const String registry = 'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry';

// See also //master/tools/gen_locale.dart in the engine repo.
Map<String, List<String>> _parseSection(String section) {
  final Map<String, List<String>> result = <String, List<String>>{};
  List<String> lastHeading;
  for (String line in section.split('\n')) {
    if (line == '')
      continue;
    if (line.startsWith('  ')) {
      lastHeading[lastHeading.length - 1] = '${lastHeading.last}${line.substring(1)}';
      continue;
    }
    final int colon = line.indexOf(':');
    if (colon <= 0)
      throw 'not sure how to deal with "$line"';
    final String name = line.substring(0, colon);
    final String value = line.substring(colon + 2);
    lastHeading = result.putIfAbsent(name, () => <String>[]);
    result[name].add(value);
  }
  return result;
}

final Map<String, String> _languages = <String, String>{};
final Map<String, String> _regions = <String, String>{};
final Map<String, String> _scripts = <String, String>{};
const String kProvincePrefix = ', Province of ';
const String kParentheticalPrefix = ' (';

/// Prepares the data for the [describeLocale] method below.
///
/// The data is obtained from the official IANA registry.
Future<void> precacheLanguageAndRegionTags() async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(Uri.parse(registry));
  final HttpClientResponse response = await request.close();
  final String body = (await response.transform<String>(utf8.decoder).toList()).join('');
  client.close(force: true);
  final List<Map<String, List<String>>> sections = body.split('%%').skip(1).map<Map<String, List<String>>>(_parseSection).toList();
  for (Map<String, List<String>> section in sections) {
    assert(section.containsKey('Type'), section.toString());
    final String type = section['Type'].single;
    if (type == 'language' || type == 'region' || type == 'script') {
      assert(section.containsKey('Subtag') && section.containsKey('Description'), section.toString());
      final String subtag = section['Subtag'].single;
      String description = section['Description'].join(' ');
      if (description.startsWith('United '))
        description = 'the $description';
      if (description.contains(kParentheticalPrefix))
        description = description.substring(0, description.indexOf(kParentheticalPrefix));
      if (description.contains(kProvincePrefix))
        description = description.substring(0, description.indexOf(kProvincePrefix));
      if (description.endsWith(' Republic'))
        description = 'the $description';
      switch (type) {
        case 'language':
          _languages[subtag] = description;
          break;
        case 'region':
          _regions[subtag] = description;
          break;
        case 'script':
          _scripts[subtag] = description;
          break;
      }
    }
  }
}

String describeLocale(String tag) {
  final List<String> subtags = tag.split('_');
  assert(subtags.isNotEmpty);
  assert(_languages.containsKey(subtags[0]));
  final String language = _languages[subtags[0]];
  String output = '$language';
  String region;
  String script;
  if (subtags.length == 2) {
    region = _regions[subtags[1]];
    script = _scripts[subtags[1]];
    assert(region != null || script != null);
  } else if (subtags.length >= 3) {
    region = _regions[subtags[2]];
    script = _scripts[subtags[1]];
    assert(region != null && script != null);
  }
  if (region != null)
    output += ', as used in $region';
  if (script != null)
    output += ', using the $script script';
  return output;
}