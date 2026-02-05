// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

// This script verifies that the release binaries only export the expected
// symbols.
//
// Android binaries (libflutter.so) should only export one symbol "JNI_OnLoad"
// of type "T".
//
// Ideally, iOS binaries (Flutter.framework/Flutter) should only export
// Objective-C Symbols from the Flutter namespace, of type "(__DATA,__common)" or
// "(__DATA,__objc_data)". However, to allow Swift symbols to be exported in
// an Objective-C bridging header, they must be public or open. The framework
// uses these types internally and never publishes these types in a public header.
// Like `_InternalFlutter` Obj-C symbols, we allow `InternalFlutterSwift` and
// `InternalFlutterSwiftCommon` symbols, as they are clearly marked as internal
// in the name.

/// Takes the path to the out directory as the first argument, and the path to
/// the buildtools directory as the second argument.
///
/// If the second argument is not specified, for backwards compatibility, it is
/// assumed that it is ../buildtools relative to the first parameter (the out
/// directory).
void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    print('usage: dart verify_exported.dart OUT_DIR [BUILDTOOLS]');
    exit(1);
  }
  String outPath = arguments.first;
  if (p.isRelative(outPath)) {
    /// If path is relative then create a full path starting from the engine checkout
    /// repository.
    if (!Platform.environment.containsKey('ENGINE_CHECKOUT_PATH')) {
      print('ENGINE_CHECKOUT_PATH env variable is mandatory when using relative destination path');
      exit(1);
    }
    final String engineCheckoutPath = Platform.environment['ENGINE_CHECKOUT_PATH']!;
    outPath = p.join(engineCheckoutPath, outPath);
  }
  final String buildToolsPath = arguments.length == 1
      ? p.join(p.dirname(outPath), 'flutter', 'buildtools')
      : arguments[1];

  String platform;
  if (Platform.isLinux) {
    platform = 'linux-x64';
  } else if (Platform.isMacOS) {
    platform = 'mac-x64';
  } else {
    throw UnimplementedError('Script only support running on Linux or MacOS.');
  }
  final String nmPath = p.join(buildToolsPath, platform, 'clang', 'bin', 'llvm-nm');
  if (!Directory(outPath).existsSync()) {
    print('error: build out directory not found: $outPath');
    exit(1);
  }

  final Iterable<String> releaseBuilds = Directory(outPath)
      .listSync()
      .whereType<Directory>()
      .map<String>((FileSystemEntity dir) => p.basename(dir.path))
      .where((String s) => s.contains('_release'));

  final Iterable<String> iosReleaseBuilds = releaseBuilds.where((String s) => s.startsWith('ios_'));
  final Iterable<String> androidReleaseBuilds = releaseBuilds.where(
    (String s) => s.startsWith('android_'),
  );
  final Iterable<String> hostReleaseBuilds = releaseBuilds.where(
    (String s) => s.startsWith('host_'),
  );

  var failures = 0;
  failures += _checkIos(outPath, nmPath, iosReleaseBuilds);
  failures += _checkAndroid(outPath, nmPath, androidReleaseBuilds);
  if (Platform.isLinux) {
    failures += _checkLinux(outPath, nmPath, hostReleaseBuilds);
  }
  print('Failing checks: $failures');
  exit(failures);
}

int _checkIos(String outPath, String nmPath, Iterable<String> builds) {
  var failures = 0;
  for (final build in builds) {
    final String libFlutter = p.join(outPath, build, 'Flutter.framework', 'Flutter');
    if (!File(libFlutter).existsSync()) {
      print('SKIPPING: $libFlutter does not exist.');
      continue;
    }
    final ProcessResult nmResult = Process.runSync(nmPath, <String>['-gUm', libFlutter]);
    if (nmResult.exitCode != 0) {
      print('ERROR: failed to execute "nm -gUm $libFlutter":\n${nmResult.stderr}');
      failures++;
      continue;
    }
    final Iterable<NmEntry> unexpectedEntries = NmEntry.parse(nmResult.stdout as String).where((
      NmEntry entry,
    ) {
      final bool cSymbol =
          (entry.type == '(__DATA,__common)' ||
              entry.type == '(__DATA,__const)' ||
              entry.type == '(__DATA_CONST,__const)') &&
          entry.name.startsWith('_Flutter');
      final bool cInternalSymbol =
          entry.type == '(__TEXT,__text)' && entry.name.startsWith('_InternalFlutter');
      final bool objcSymbol =
          (entry.type == '(__DATA,__objc_data)' || entry.type == '(__DATA,__data)') &&
          (entry.name.startsWith(r'_OBJC_METACLASS_$_Flutter') ||
              entry.name.startsWith(r'_OBJC_CLASS_$_Flutter'));
      return !(cSymbol || cInternalSymbol || objcSymbol || entry.isInternalSwiftSymbol);
    });
    if (unexpectedEntries.isNotEmpty) {
      print('ERROR: $libFlutter exports unexpected symbols:');
      print(
        unexpectedEntries.fold<String>('', (String previous, NmEntry entry) {
          return '${previous == '' ? '' : '$previous\n'}     ${entry.type} ${entry.name}';
        }),
      );
      failures++;
    } else {
      print('OK: $libFlutter');
    }
  }
  return failures;
}

int _checkAndroid(String outPath, String nmPath, Iterable<String> builds) {
  var failures = 0;
  for (final build in builds) {
    final String libFlutter = p.join(outPath, build, 'libflutter.so');
    if (!File(libFlutter).existsSync()) {
      print('SKIPPING: $libFlutter does not exist.');
      continue;
    }
    final ProcessResult nmResult = Process.runSync(nmPath, <String>['-gU', libFlutter]);
    if (nmResult.exitCode != 0) {
      print('ERROR: failed to execute "nm -gU $libFlutter":\n${nmResult.stderr}');
      failures++;
      continue;
    }
    final Iterable<NmEntry> entries = NmEntry.parse(nmResult.stdout as String);
    final entryMap = <String, String>{for (final NmEntry entry in entries) entry.name: entry.type};
    final expectedSymbols = <String, String>{
      'JNI_OnLoad': 'T',
      '_binary_icudtl_dat_size': 'R',
      '_binary_icudtl_dat_start': 'R',
    };
    final badSymbols = <String, String>{};
    for (final String key in entryMap.keys) {
      final bool isValidFlutterGpuSymbol =
          key.startsWith('InternalFlutterGpu') && entryMap[key] == 'T';
      final bool isLibcxxSymbol = key.endsWith('_lcxx_override');
      if (!isValidFlutterGpuSymbol && !isLibcxxSymbol && entryMap[key] != expectedSymbols[key]) {
        badSymbols[key] = entryMap[key]!;
      }
    }
    if (badSymbols.isNotEmpty) {
      print('ERROR: $libFlutter exports the wrong symbols');
      print(' Expected $expectedSymbols');
      print(' Library has $entryMap.');
      failures++;
    } else {
      print('OK: $libFlutter');
    }
  }
  return failures;
}

int _checkLinux(String outPath, String nmPath, Iterable<String> builds) {
  var failures = 0;
  for (final build in builds) {
    final String libFlutter = p.join(outPath, build, 'libflutter_engine.so');
    if (!File(libFlutter).existsSync()) {
      print('SKIPPING: $libFlutter does not exist.');
      continue;
    }
    final ProcessResult nmResult = Process.runSync(nmPath, <String>['-gUD', libFlutter]);
    if (nmResult.exitCode != 0) {
      print('ERROR: failed to execute "nm -gUD $libFlutter":\n${nmResult.stderr}');
      failures++;
      continue;
    }
    final List<NmEntry> entries = NmEntry.parse(nmResult.stdout as String).toList();
    for (final entry in entries) {
      if (entry.type != 'T' && entry.type != 'R') {
        print('ERROR: $libFlutter exports an unexpected symbol type: ($entry)');
        print(' Library has $entries.');
        failures++;
        break;
      }
      if (!(entry.name.startsWith('Flutter') ||
          entry.name.startsWith('__Flutter') ||
          entry.name.startsWith('kFlutter') ||
          entry.name.startsWith('InternalFlutter') ||
          entry.name.startsWith('kInternalFlutter'))) {
        print('ERROR: $libFlutter exports an unexpected symbol name: ($entry)');
        print(' Library has $entries.');
        failures++;
        break;
      }
    }
  }
  return failures;
}

final class NmEntry {
  NmEntry._(this.type, this.name);

  final String type;
  final String name;

  static Iterable<NmEntry> parse(String stdout) {
    return LineSplitter.split(stdout).map((String line) {
      final List<String> parts = line.split(' ');
      return NmEntry._(parts[1], parts.last);
    });
  }

  static (int? parsedToken, String rest) _parseLeadingUnsignedInt(String string) {
    final String? digits = RegExp(r'^\d+').firstMatch(string)?.group(0);
    return digits == null ? (null, string) : (int.parse(digits), string.substring(digits.length));
  }

  /// Extracts the leading mangled Swift identifier in the given string
  /// and returns it along with the rest of the string, or `(null, originalString)`
  /// if the given string does not start with a valid identifier.
  static (String? parsedToken, String rest) _parseLeadingSwiftMangledIdentifier(String string) {
    final (int? length, String rest) = _parseLeadingUnsignedInt(string);
    return (length == null || length == 0)
        ? (null, string)
        : (rest.substring(0, length), rest.substring(length));
  }

  // A quick and dirty way to check if the [NmEntry] represents an allowed
  // swift symbol.
  //
  // Only swift symbols introduced in `InternalFlutterSwift` or
  // `InternalFlutterSwiftCommon` are allowed. See the script documentation.
  bool get isInternalSwiftSymbol {
    final bool isTypeValid = switch (type) {
      '(__TEXT,__text)' ||
      '(__TEXT,__const)' ||
      '(__TEXT,__constg_swiftt)' ||
      '(__DATA_CONST,__const)' ||
      '(__DATA,__data)' ||
      '(__DATA,__objc_data)' => true,
      _ => false,
    };
    if (!isTypeValid && name.startsWith(r'_$s')) {
      return false;
    }

    // Check if the mangled symbol is from either allowed module. The swift
    // mangling rules can be found here: https://github.com/swiftlang/swift/blob/main/docs/ABI/Mangling.rst,
    // but for identifying the module name we only have to handle 2 cases for now:
    //  - extension, example: _$sSo19NSJSONSerializationC26InternalFlutterSwiftCommonE10decodeJSONyyp10Foundation4DataVKFZ
    //  - non-extension, example: _$s26InternalFlutterSwiftCommon8LogLevelOSYAAMc
    //
    //  Each identifier only contains ascii characters, and has a numeric prefix
    //  which represents number of ascii characters in the identifier.
    const allowedModules = <String>['InternalFlutterSwift', 'InternalFlutterSwiftCommon'];

    String rest = name.substring(3); // Trim the leading '_$s'.
    if (rest.startsWith('So')) {
      // The symbol was introduced as an extension in the internal modules on
      // an out-of-module Objective-C class (an @objc extension has to be on a
      // class).
      // example: _$sSo19NSJSONSerializationC26InternalFlutterSwiftCommonE10decodeJSONyyp10Foundation4DataVKFZ
      rest = rest.substring(2); // Trim the leading 'So'.
      rest = _parseLeadingSwiftMangledIdentifier(
        rest,
      ).$2; // Trim the leading identifier '19NSJSONSerialization'.
      return rest.startsWith('C') &&
          switch (_parseLeadingSwiftMangledIdentifier(rest.substring(1))) {
            (null, _) => false,
            (final String moduleName, final String tail) =>
              allowedModules.contains(moduleName) && tail.startsWith('E'),
          };
    }
    // Simple case: the mangled name starts with the correct module name.
    // exmaple: _$s26InternalFlutterSwiftCommon8LogLevelOSYAAMc
    final (String? moduleName, _) = _parseLeadingSwiftMangledIdentifier(rest);
    return moduleName != null && allowedModules.contains(moduleName);
  }

  @override
  String toString() => '$name: $type';
}
