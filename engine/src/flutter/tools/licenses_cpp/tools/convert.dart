// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// A script for converting license files found in
/// `//engine/src/flutter/ci/licenses_golden/` to the licenses format.

// A simple class to hold the parsed license information.
class License {
  License({
    required this.library,
    required this.origins,
    required this.type,
    required this.files,
    required this.licenseText,
  });

  final String library;
  final List<String> origins;
  final String type;
  final List<String> files;
  final String licenseText;

  @override
  String toString() {
    return 'Library: $library\n'
        'Type: $type\n'
        'Origins: ${origins.join(', ')}\n'
        'Files: ${files.length}\n'
        '---\n'
        'License Text:\n$licenseText\n'
        '==================================================\n';
  }
}

// Parses the licenses file and returns a list of License objects.
Future<List<License>> parseLicenses(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw FileSystemException('File not found', filePath);
  }

  final List<String> lines = await file.readAsLines();
  final licenses = <License>[];
  final buffer = StringBuffer();
  String? currentLibrary;
  List<String> currentOrigins = [];
  String? currentType;
  List<String> currentFiles = [];
  var seenDivider = false;

  for (final line in lines) {
    if (line.startsWith(
      '====================================================================================================',
    )) {
      if (currentLibrary != null) {
        licenses.add(
          License(
            library: currentLibrary,
            origins: currentOrigins,
            type: currentType ?? 'Unknown',
            files: currentFiles,
            licenseText: buffer.toString().trim(),
          ),
        );
      }
      currentLibrary = null;
      currentOrigins = [];
      currentType = null;
      currentFiles = [];
      buffer.clear();
      seenDivider = false;
      continue;
    }

    if (currentLibrary == null) {
      if (line.startsWith('LIBRARY:')) {
        currentLibrary = line.substring('LIBRARY:'.length).trim();
      }
    } else {
      if (line.startsWith('ORIGIN:')) {
        currentOrigins.add(line.substring('ORIGIN:'.length).trim());
      } else if (line.startsWith('TYPE:')) {
        currentType = line.substring('TYPE:'.length).trim();
      } else if (line.startsWith('FILE:')) {
        currentFiles.add(line.substring('FILE:'.length).trim());
      } else if (line ==
          '----------------------------------------------------------------------------------------------------') {
        seenDivider = true;
      } else if (seenDivider) {
        buffer.writeln(line);
      }
    }
  }

  // Add the last license block if it exists
  if (currentLibrary != null) {
    licenses.add(
      License(
        library: currentLibrary,
        origins: currentOrigins,
        type: currentType ?? 'Unknown',
        files: currentFiles,
        licenseText: buffer.toString().trim(),
      ),
    );
  }

  return licenses;
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage: dart run parse_licenses.dart <path_to_licenses_file>');
    exit(1);
  }

  final String filePath = arguments.first;

  try {
    final List<License> licenses = await parseLicenses(filePath);
    if (licenses.isEmpty) {
      print('No licenses found in the file.');
      return;
    }

    var first = true;
    for (final license in licenses) {
      if (!first) {
        print('--------------------------------------------------------------------------------');
      }
      first = false;
      print(license.library);
      print('');
      print(license.licenseText);
    }
  } on FileSystemException catch (e) {
    print('Error: ${e.message}');
  } catch (e) {
    print('An unexpected error occurred: $e');
  }
}
