// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:mustache_template/mustache.dart';

import 'fonts.pb.dart';

const _generatedFilePath = 'lib/google_fonts.dart';
const _familiesSupportedPath = 'generator/families_supported';
const _familiesDiffPath = 'generator/families_diff';

Future<void> main() async {
  print('Getting latest font directory...');
  final protoUrl = await _getProtoUrl();
  print('Success! Using $protoUrl');

  final fontDirectory = await _readFontsProtoData(protoUrl);
  print('\nValidating font URLs and file contents...');
  await _verifyUrls(fontDirectory);
  print(_success);

  print('\nDetermining font families delta...');
  final familiesDelta = _FamiliesDelta(fontDirectory);
  print(_success);

  print('\nGenerating $_familiesSupportedPath & $_familiesDiffPath ...');
  File(_familiesSupportedPath)
      .writeAsStringSync(familiesDelta.printableSupported());
  File(_familiesDiffPath).writeAsStringSync(familiesDelta.markdownDiff());
  print(_success);

  print('\nUpdating CHANGELOG.md and pubspec.yaml...');
  await familiesDelta.updateChangelogAndPubspec();
  print(_success);

  print('\nGenerating $_generatedFilePath...');
  await _writeDartFile(_generateDartCode(fontDirectory));
  print(_success);

  print('\nFormatting $_generatedFilePath...');
  await Process.run('flutter', ['format', _generatedFilePath]);
  print(_success);
}

const _success = 'Success!';

/// Gets the latest font directory.
///
/// Versioned directories are hosted on the Google Fonts server. We try to fetch
/// each directory one by one until we hit the last one. We know we reached the
/// end if requesting the next version results in a 404 response.
/// Other types of failure should not occur. For example, if the internet
/// connection gets lost while downloading the directories, we just crash. But
/// that's okay for now, because the generator is only executed in trusted
/// environments by individual developers.
Future<Uri> _getProtoUrl({int initialVersion = 1}) async {
  var directoryVersion = initialVersion;

  Uri url(int directoryVersion) {
    final paddedVersion = directoryVersion.toString().padLeft(3, '0');
    return Uri.parse('http://fonts.gstatic.com/s/f/directory$paddedVersion.pb');
  }

  var didReachLatestUrl = false;
  final httpClient = http.Client();
  while (!didReachLatestUrl) {
    final response = await httpClient.get(url(directoryVersion));
    if (response.statusCode == 200) {
      directoryVersion += 1;
    } else if (response.statusCode == 404) {
      didReachLatestUrl = true;
      directoryVersion -= 1;
    } else {
      throw Exception('Request failed: $response');
    }
  }
  httpClient.close();

  return url(directoryVersion);
}

Future<void> _verifyUrls(Directory fontDirectory) async {
  final totalFonts =
      fontDirectory.family.map((f) => f.fonts.length).reduce((a, b) => a + b);

  final client = http.Client();
  int i = 1;
  for (final family in fontDirectory.family) {
    for (final font in family.fonts) {
      final urlString =
          'https://fonts.gstatic.com/s/a/${_hashToString(font.file.hash)}.ttf';
      final url = Uri.parse(urlString);
      await _tryUrl(client, url, font);
      print('Verified URL ($i/$totalFonts): $urlString');
      i += 1;
    }
  }
  client.close();
}

Future<void> _tryUrl(http.Client client, Uri url, Font font) async {
  try {
    final fileContents = await client.get(url);
    final actualFileLength = fileContents.bodyBytes.length;
    final actualFileHash = sha256.convert(fileContents.bodyBytes).toString();
    if (font.file.fileSize != actualFileLength ||
        _hashToString(font.file.hash) != actualFileHash) {
      throw Exception('Font from $url did not match length of or checksum.');
    }
  } catch (e) {
    print('Failed to load font from url: $url');
    rethrow;
  }
}

String _hashToString(List<int> bytes) {
  var fileName = '';
  for (final byte in bytes) {
    final convertedByte = byte.toRadixString(16).padLeft(2, '0');
    fileName += convertedByte;
  }
  return fileName;
}

// Utility class to track font family deltas.
//
// [fontDirectory] represents a possibly updated directory.
class _FamiliesDelta {
  _FamiliesDelta(Directory fontDirectory) {
    _init(fontDirectory);
  }

  late final Set<String> added;
  late final Set<String> removed;
  late final Set<String> all;

  void _init(Directory fontDirectory) {
    // Currently supported families.
    Set<String> familiesSupported =
        Set.from(File(_familiesSupportedPath).readAsLinesSync());

    // Newly supported families.
    all = Set<String>.from(
      fontDirectory.family.map<String>((item) => item.name),
    );

    added = all.difference(familiesSupported);
    removed = familiesSupported.difference(all);
  }

  // Printable list of supported font families.
  String printableSupported() => all.join('\n');

  // Diff of font families, suitable for markdown
  // (e.g. CHANGELOG, PR description).
  String markdownDiff() {
    final addedPrintable = added.map((family) => '  - Added `$family`');
    final removedPrintable = removed.map((family) => '  - Removed `$family`');

    String diff = '';
    if (removedPrintable.isNotEmpty) {
      diff += removedPrintable.join('\n');
      diff += '\n';
    }
    if (addedPrintable.isNotEmpty) {
      diff += addedPrintable.join('\n');
      diff += '\n';
    }

    return diff;
  }

  // Use cider to update CHANGELOG.md and pubspec.yaml.
  Future<void> updateChangelogAndPubspec() async {
    for (final family in removed) {
      await Process.run('cider', ['log', 'removed', '`$family`']);
    }
    for (final family in added) {
      await Process.run('cider', ['log', 'added', '`$family`']);
    }

    await Process.run(
      'cider',
      ['bump', removed.isNotEmpty ? 'breaking' : 'minor'],
    );
  }
}

String _generateDartCode(Directory fontDirectory) {
  final methods = <Map<String, dynamic>>[];

  for (final item in fontDirectory.family) {
    final family = item.name;
    final familyNoSpaces = family.replaceAll(' ', '');
    final familyWithPlusSigns = family.replaceAll(' ', '+');
    final methodName = _familyToMethodName(family);

    const themeParams = [
      'displayLarge',
      'displayMedium',
      'displaySmall',
      'headlineLarge',
      'headlineMedium',
      'headlineSmall',
      'titleLarge',
      'titleMedium',
      'titleSmall',
      'bodyLarge',
      'bodyMedium',
      'bodySmall',
      'labelLarge',
      'labelMedium',
      'labelSmall',
    ];

    methods.add(<String, dynamic>{
      'methodName': methodName,
      'fontFamily': familyNoSpaces,
      'fontFamilyDisplay': family,
      'docsUrl': 'https://fonts.google.com/specimen/$familyWithPlusSigns',
      'fontUrls': [
        for (final variant in item.fonts)
          {
            'variantWeight': variant.weight.start,
            'variantStyle':
                variant.italic.start.round() == 1 ? 'italic' : 'normal',
            'hash': _hashToString(variant.file.hash),
            'length': variant.file.fileSize,
          },
      ],
      'themeParams': [
        for (final themeParam in themeParams) {'value': themeParam},
      ],
    });
  }

  final template = Template(
    File('generator/google_fonts.tmpl').readAsStringSync(),
    htmlEscapeValues: false,
  );
  return template.renderString({'method': methods});
}

Future<void> _writeDartFile(String content) async {
  await File(_generatedFilePath).writeAsString(content);
}

String _familyToMethodName(String family) {
  final words = family.split(' ');
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    final isFirst = i == 0;
    final isUpperCase = word == word.toUpperCase();
    words[i] = (isFirst ? word[0].toLowerCase() : word[0].toUpperCase()) +
        (isUpperCase ? word.substring(1).toLowerCase() : word.substring(1));
  }
  return words.join();
}

Future<Directory> _readFontsProtoData(Uri protoUrl) async {
  final fontsProtoFile = await http.get(protoUrl);
  return Directory.fromBuffer(fontsProtoFile.bodyBytes);
}
