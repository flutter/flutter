// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Shared logic between iOS and macOS implementations of native assets.

import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide BuildMode;

import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../base/io.dart';
import '../../../build_info.dart';
import '../../../convert.dart';
import '../../../globals.dart' as globals;

/// Create an `Info.plist` in [target] for a framework with a single dylib.
///
/// The framework must be named [name].framework and the dylib [name].
Future<void> createInfoPlist(
  String name,
  Directory target,
) async {
  final File infoPlistFile = target.childFile('Info.plist');
  await infoPlistFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	 <string>en</string>
	<key>CFBundleExecutable</key>
	<string>$name</string>
	<key>CFBundleIdentifier</key>
	<string>io.flutter.flutter.native_assets.$name</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$name</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
</dict>
</plist>
  ''');
}

/// Combines dylibs from [sources] into a fat binary at [targetFullPath].
///
/// The dylibs must have different architectures. E.g. a dylib targeting
/// arm64 ios simulator cannot be combined with a dylib targeting arm64
/// ios device or macos arm64.
Future<void> lipoDylibs(File target, List<Uri> sources) async {
  final ProcessResult lipoResult = await globals.processManager.run(
    <String>[
      'lipo',
      '-create',
      '-output',
      target.path,
      for (final Uri source in sources) source.toFilePath(),
    ],
  );
  if (lipoResult.exitCode != 0) {
    throwToolExit('Failed to create universal binary:\n${lipoResult.stderr}');
  }
  globals.logger.printTrace(lipoResult.stdout as String);
  globals.logger.printTrace(lipoResult.stderr as String);
}

/// Sets the install name in a dylib with a Mach-O format.
///
/// On macOS and iOS, opening a dylib at runtime fails if the path inside the
/// dylib itself does not correspond to the path that the file is at. Therefore,
/// native assets copied into their final location also need their install name
/// updated with the `install_name_tool`.
Future<void> setInstallNameDylib(File dylibFile) async {
  final String fileName = dylibFile.basename;
  final ProcessResult installNameResult = await globals.processManager.run(
    <String>[
      'install_name_tool',
      '-id',
      '@rpath/$fileName.framework/$fileName',
      dylibFile.path,
    ],
  );
  if (installNameResult.exitCode != 0) {
    throwToolExit(
      'Failed to change the install name of $dylibFile:\n${installNameResult.stderr}',
    );
  }
}

Future<void> codesignDylib(
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystemEntity target,
) async {
  if (codesignIdentity == null || codesignIdentity.isEmpty) {
    codesignIdentity = '-';
  }
  final List<String> codesignCommand = <String>[
    'codesign',
    '--force',
    '--sign',
    codesignIdentity,
    if (buildMode != BuildMode.release) ...<String>[
      // Mimic Xcode's timestamp codesigning behavior on non-release binaries.
      '--timestamp=none',
    ],
    target.path,
  ];
  globals.logger.printTrace(codesignCommand.join(' '));
  final ProcessResult codesignResult = await globals.processManager.run(
    codesignCommand,
  );
  if (codesignResult.exitCode != 0) {
    throwToolExit(
      'Failed to code sign binary: exit code: ${codesignResult.exitCode} '
      '${codesignResult.stdout} ${codesignResult.stderr}',
    );
  }
  globals.logger.printTrace(codesignResult.stdout as String);
  globals.logger.printTrace(codesignResult.stderr as String);
}

/// Flutter expects `xcrun` to be on the path on macOS hosts.
///
/// Use the `clang`, `ar`, and `ld` that would be used if run with `xcrun`.
Future<CCompilerConfig> cCompilerConfigMacOS() async {
  final ProcessResult xcrunResult = await globals.processManager.run(
    <String>['xcrun', 'clang', '--version'],
  );
  if (xcrunResult.exitCode != 0) {
    throwToolExit('Failed to find clang with xcrun:\n${xcrunResult.stderr}');
  }
  final String installPath = LineSplitter.split(xcrunResult.stdout as String)
      .firstWhere((String s) => s.startsWith('InstalledDir: '))
      .split(' ')
      .last;
  return CCompilerConfig(
    cc: Uri.file('$installPath/clang'),
    ar: Uri.file('$installPath/ar'),
    ld: Uri.file('$installPath/ld'),
  );
}

/// Converts [fileName] into a suitable framework name.
///
/// On MacOS and iOS, dylibs need to be packaged in a framework.
///
/// In order for resolution to work, the file name inside the framework must be
/// equal to the framework name.
///
/// Dylib names on MacOS/iOS usually have a dylib extension. If so, remove it.
///
/// Dylib names on MacOS/iOS are usually prefixed with 'lib'. So, if the file is
/// a dylib, try to remove the prefix.
///
/// The bundle ID string must contain only alphanumeric characters
/// (A–Z, a–z, and 0–9), hyphens (-), and periods (.).
/// https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleidentifier
///
/// The [alreadyTakenNames] are used to ensure that the framework name does not
/// conflict with previously chosen names.
Uri frameworkUri(String fileName, Set<String> alreadyTakenNames) {
  final List<String> splitFileName = fileName.split('.');
  final bool isDylib;
  if (splitFileName.length >= 2) {
    isDylib = splitFileName.last == 'dylib';
    if (isDylib) {
      fileName = splitFileName.sublist(0, splitFileName.length - 1).join('.');
    }
  } else {
    isDylib = false;
  }
  if (isDylib && fileName.startsWith('lib')) {
    fileName = fileName.replaceFirst('lib', '');
  }
  fileName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  if (alreadyTakenNames.contains(fileName)) {
    final String prefixName = fileName;
    for (int i = 1; i < 1000; i++) {
      fileName = '$prefixName$i';
      if (!alreadyTakenNames.contains(fileName)) {
        break;
      }
    }
    if (alreadyTakenNames.contains(fileName)) {
      throwToolExit('Failed to rename $fileName in native assets packaging.');
    }
  }
  alreadyTakenNames.add(fileName);
  return Uri(path: '$fileName.framework/$fileName');
}
