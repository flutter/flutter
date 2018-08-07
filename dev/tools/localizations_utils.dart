// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as argslib;
import 'package:meta/meta.dart';

void exitWithError(String errorMessage) {
  assert(errorMessage != null);
  stderr.writeln('fatal: $errorMessage');
  exit(1);
}

void checkCwdIsRepoRoot(String commandName) {
  final bool isRepoRoot = new Directory('.git').existsSync();

  if (!isRepoRoot) {
    exitWithError(
      '$commandName must be run from the root of the Flutter repository. The '
      'current working directory is: ${Directory.current.path}'
    );
  }
}

String camelCase(String locale) {
  return locale
    .split('_')
    .map((String part) => part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase())
    .join('');
}

GeneratorOptions parseArgs(List<String> rawArgs) {
  final argslib.ArgParser argParser = new argslib.ArgParser()
    ..addFlag(
      'overwrite',
      abbr: 'w',
      defaultsTo: false,
    );
  final argslib.ArgResults args = argParser.parse(rawArgs);
  final bool writeToFile = args['overwrite'];

  return new GeneratorOptions(writeToFile: writeToFile);
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
  final HttpClient client = new HttpClient();
  final HttpClientRequest request = await client.getUrl(Uri.parse(registry));
  final HttpClientResponse response = await request.close();
  final String body = (await response.transform(utf8.decoder).toList()).join('');
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
  if (subtags.length >= 2) {
    final String region = _regions[subtags[1]];
    final String script = _scripts[subtags[1]];
    assert(region != null || script != null);
    if (region != null)
      return '$language, as used in $region';
    if (script != null)
      return '$language, using the $script script';
  }
  return '$language';
}