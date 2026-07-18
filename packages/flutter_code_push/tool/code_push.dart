// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Packages Dart isolate snapshot blobs for OTA code push.
///
/// Patches are `isolate_snapshot_data` + `isolate_snapshot_instr` extracted from
/// a release `app.so` / `App.framework` build. The APK/IPA keeps the original
/// native library; only these blobs are downloaded at runtime.
Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.first == 'help' || arguments.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final String command = arguments.first;
  final Map<String, String> options = _parseOptions(arguments.skip(1));

  switch (command) {
    case 'artifact':
      await _createArtifact(options);
    case 'extract':
      await _extractFromElf(options);
    default:
      stderr.writeln('Unknown command: $command');
      _printUsage();
      exit(64);
  }
}

Future<void> _createArtifact(Map<String, String> options) async {
  final String? dataPath = options['isolate-data'];
  final String? instrPath = options['isolate-instr'];
  final String? releaseVersion = options['release-version'];
  final String? patchNumberString = options['patch-number'];
  final String? outputDirectoryPath = options['output'];

  if (dataPath == null ||
      instrPath == null ||
      releaseVersion == null ||
      patchNumberString == null ||
      outputDirectoryPath == null) {
    stderr.writeln(
      'artifact requires --isolate-data, --isolate-instr, '
      '--release-version, --patch-number, --output',
    );
    exit(64);
  }

  final File dataFile = File(dataPath);
  final File instrFile = File(instrPath);
  if (!await dataFile.exists() || !await instrFile.exists()) {
    stderr.writeln('Snapshot blob file(s) not found.');
    exit(66);
  }

  final int patchNumber = int.parse(patchNumberString);
  final Directory outputDirectory = Directory(outputDirectoryPath);
  await outputDirectory.create(recursive: true);

  final List<int> dataBytes = await dataFile.readAsBytes();
  final List<int> instrBytes = await instrFile.readAsBytes();
  final String dataSha256 = sha256.convert(dataBytes).toString();
  final String instrSha256 = sha256.convert(instrBytes).toString();

  await File('${outputDirectory.path}/isolate_snapshot_data')
      .writeAsBytes(dataBytes, flush: true);
  await File('${outputDirectory.path}/isolate_snapshot_instr')
      .writeAsBytes(instrBytes, flush: true);

  final Map<String, Object?> manifest = <String, Object?>{
    'patch_number': patchNumber,
    'release_version': releaseVersion,
    'isolate_data_sha256': dataSha256,
    'isolate_instr_sha256': instrSha256,
    'isolate_data_length_bytes': dataBytes.length,
    'isolate_instr_length_bytes': instrBytes.length,
    'enabled': true,
  };

  await File('${outputDirectory.path}/patch_manifest.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  stdout.writeln('Created isolate snapshot patch at ${outputDirectory.path}');
}

Future<void> _extractFromElf(Map<String, String> options) async {
  final String? elfPath = options['elf'];
  final String? outputDirectoryPath = options['output'];
  if (elfPath == null || outputDirectoryPath == null) {
    stderr.writeln('extract requires --elf and --output');
    exit(64);
  }

  final Directory outputDirectory = Directory(outputDirectoryPath);
  await outputDirectory.create(recursive: true);

  await _extractSymbolBlob(
    elfPath: elfPath,
    symbolName: 'kDartIsolateSnapshotData',
    outputPath: '${outputDirectory.path}/isolate_snapshot_data',
  );
  await _extractSymbolBlob(
    elfPath: elfPath,
    symbolName: 'kDartIsolateSnapshotInstructions',
    outputPath: '${outputDirectory.path}/isolate_snapshot_instr',
  );

  stdout.writeln('Extracted isolate snapshots from $elfPath');
}

Future<void> _extractSymbolBlob({
  required String elfPath,
  required String symbolName,
  required String outputPath,
}) async {
  final ProcessResult sizeResult = await Process.run('nm', <String>['-S', elfPath]);
  if (sizeResult.exitCode != 0) {
    stderr.writeln('nm failed: ${sizeResult.stderr}');
    exit(1);
  }

  final RegExp symbolPattern = RegExp(
    r'([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+\w\s+_?' + symbolName + r'\s*$',
  );

  String? addressHex;
  String? sizeHex;
  for (final String line in '${sizeResult.stdout}'.split('\n')) {
    final Match? match = symbolPattern.firstMatch(line.trim());
    if (match != null) {
      addressHex = match.group(1);
      sizeHex = match.group(2);
      break;
    }
  }

  if (addressHex == null || sizeHex == null) {
    stderr.writeln('Symbol $symbolName not found in $elfPath');
    exit(1);
  }

  final int address = int.parse(addressHex, radix: 16);
  final int size = int.parse(sizeHex, radix: 16);

  final RandomAccessFile elfFile = await File(elfPath).open();
  await elfFile.setPosition(address);
  final List<int> bytes = await elfFile.read(size);
  await elfFile.close();
  await File(outputPath).writeAsBytes(bytes, flush: true);
}

Map<String, String> _parseOptions(Iterable<String> arguments) {
  final Map<String, String> options = <String, String>{};
  final List<String> args = arguments.toList();
  for (int index = 0; index < args.length; index++) {
    final String arg = args[index];
    if (!arg.startsWith('--')) {
      continue;
    }
    final String key = arg.substring(2);
    if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
      options[key] = args[index + 1];
      index++;
    } else {
      options[key] = 'true';
    }
  }
  return options;
}

void _printUsage() {
  stdout.writeln('''
flutter_code_push CLI — Dart isolate snapshot patches only

Commands:
  extract    Extract isolate_snapshot_data/instr from app.so (requires nm)
  artifact   Package blob files for CDN upload

extract:
  --elf       Path to libapp.so / app.so from flutter build
  --output    Directory for isolate_snapshot_data + isolate_snapshot_instr

artifact:
  --isolate-data       Path to isolate_snapshot_data blob
  --isolate-instr      Path to isolate_snapshot_instr blob
  --release-version    Must match the installed store build
  --patch-number       Monotonic patch id
  --output             Output directory

Workflow:
  1. flutter build apk --release
  2. dart run .../code_push.dart extract --elf build/.../app.so --output /tmp/patch
  3. Make Dart changes, rebuild, extract again as patch 2
  4. Host blobs + serve manifest JSON from your API
''');
}
