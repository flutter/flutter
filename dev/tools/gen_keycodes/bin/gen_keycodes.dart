// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:gen_keycodes/android_code_gen.dart';
import 'package:gen_keycodes/base_code_gen.dart';
import 'package:gen_keycodes/gtk_code_gen.dart';
import 'package:gen_keycodes/ios_code_gen.dart';
import 'package:gen_keycodes/keyboard_keys_code_gen.dart';
import 'package:gen_keycodes/keyboard_maps_code_gen.dart';
import 'package:gen_keycodes/logical_key_data.dart';
import 'package:gen_keycodes/macos_code_gen.dart';
import 'package:gen_keycodes/physical_key_data.dart';
import 'package:gen_keycodes/testing_key_codes_gen.dart';
import 'package:gen_keycodes/utils.dart';
import 'package:gen_keycodes/web_code_gen.dart';
import 'package:gen_keycodes/windows_code_gen.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Get contents of the file that contains the physical key mapping in Chromium
/// source.
Future<String> getChromiumCodes() async {
  final Uri keyCodesUri = Uri.parse('https://chromium.googlesource.com/codesearch/chromium/src/+/refs/heads/master/ui/events/keycodes/dom/dom_code_data.inc?format=TEXT');
  return utf8.decode(base64.decode(await http.read(keyCodesUri)));
}

/// Get contents of the file that contains the logical key mapping in Chromium
/// source.
Future<String> getChromiumKeys() async {
  final Uri keyCodesUri = Uri.parse('https://chromium.googlesource.com/codesearch/chromium/src/+/refs/heads/master/ui/events/keycodes/dom/dom_key_data.inc?format=TEXT');
  return utf8.decode(base64.decode(await http.read(keyCodesUri)));
}

/// Get contents of the file that contains the key codes in Android source.
Future<String> getAndroidKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://android.googlesource.com/platform/frameworks/native/+/master/include/android/keycodes.h?format=TEXT');
  return utf8.decode(base64.decode(await http.read(keyCodesUri)));
}

Future<String> getWindowsKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://raw.githubusercontent.com/tpn/winsdk-10/master/Include/10.0.10240.0/um/WinUser.h');
  return http.read(keyCodesUri);
}

/// Get contents of the file that contains the scan codes in Android source.
/// Yes, this is just the generic keyboard layout file for base Android distro
/// This is because there isn't any facility in Android to get the keyboard
/// layout, so we're using this to match scan codes with symbol names for most
/// common keyboards. Other than some special keyboards and game pads, this
/// should be OK.
Future<String> getAndroidScanCodes() async {
  final Uri scanCodesUri = Uri.parse('https://android.googlesource.com/platform/frameworks/base/+/master/data/keyboards/Generic.kl?format=TEXT');
  return utf8.decode(base64.decode(await http.read(scanCodesUri)));
}

Future<String> getGlfwKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://raw.githubusercontent.com/glfw/glfw/master/include/GLFW/glfw3.h');
  return http.read(keyCodesUri);
}

Future<String> getGtkKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://gitlab.gnome.org/GNOME/gtk/-/raw/master/gdk/gdkkeysyms.h');
  return http.read(keyCodesUri);
}

String readDataFile(String fileName) {
  return File(path.join(dataRoot, fileName)).readAsStringSync();
}

bool _assertsEnabled() {
  bool enabledAsserts = false;
  assert(() {
    enabledAsserts = true;
    return true;
  }());
  return enabledAsserts;
}

Future<void> main(List<String> rawArguments) async {
  if (!_assertsEnabled()) {
    print('The gen_keycodes script must be run with --enable-asserts.');
    return;
  }
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'engine-root',
    defaultsTo: path.join(flutterRoot.path, '..', 'engine', 'src', 'flutter'),
    help: 'The path to the root of the flutter/engine repository. This is used '
        'to place the generated engine mapping files. If --engine-root is not '
        r'specified, it will default to $flutterRoot/../engine/src/flutter, '
        'assuming the engine gclient folder is placed at the same folder as '
        'the flutter/flutter repository.',
  );
  argParser.addOption(
    'physical-data',
    defaultsTo: path.join(dataRoot, 'physical_key_data.json'),
    help: 'The path to where the physical key data file should be written when '
        'collected, and read from when generating output code. If --physical-data is '
        'not specified, the output will be written to/read from the current '
        "directory. If the output directory doesn't exist, it, and the path to "
        'it, will be created.',
  );
  argParser.addOption(
    'logical-data',
    defaultsTo: path.join(dataRoot, 'logical_key_data.json'),
    help: 'The path to where the logical key data file should be written when '
        'collected, and read from when generating output code. If --logical-data is '
        'not specified, the output will be written to/read from the current '
        "directory. If the output directory doesn't exist, it, and the path to "
        'it, will be created.',
  );
  argParser.addOption(
    'code',
    defaultsTo: path.join(flutterRoot.path, 'packages', 'flutter', 'lib', 'src', 'services', 'keyboard_key.dart'),
    help: 'The path to where the output "keyboard_key.dart" file should be '
        'written. If --code is not specified, the output will be written to the '
        'correct directory in the flutter tree. If the output directory does not '
        'exist, it, and the path to it, will be created.',
  );
  argParser.addOption(
    'maps',
    defaultsTo: path.join(flutterRoot.path, 'packages', 'flutter', 'lib', 'src', 'services', 'keyboard_maps.dart'),
    help: 'The path to where the output "keyboard_maps.dart" file should be '
      'written. If --maps is not specified, the output will be written to the '
      'correct directory in the flutter tree. If the output directory does not '
      'exist, it, and the path to it, will be created.',
  );
  argParser.addFlag(
    'collect',
    negatable: false,
    help: 'If this flag is set, then collect and parse header files from '
        'Chromium and Android instead of reading pre-parsed data from '
        '"physical_key_data.json" and "logical_key_data.json", and then '
        'update these files with the fresh data.',
  );
  argParser.addFlag(
    'help',
    negatable: false,
    help: 'Print help for this command.',
  );

  final ArgResults parsedArguments = argParser.parse(rawArguments);

  if (parsedArguments['help'] as bool) {
    print(argParser.usage);
    exit(0);
  }

  PlatformCodeGenerator.engineRoot = parsedArguments['engine-root'] as String;

  PhysicalKeyData physicalData;
  LogicalKeyData logicalData;
  if (parsedArguments['collect'] as bool) {
    // Physical
    final String baseHidCodes = await getChromiumCodes();
    final String supplementalHidCodes = readDataFile('supplemental_hid_codes.inc');
    final String androidScanCodes = await getAndroidScanCodes();
    final String androidToDomKey = readDataFile('android_key_name_to_name.json');
    physicalData = PhysicalKeyData(
      <String>[baseHidCodes, supplementalHidCodes].join('\n'),
      androidScanCodes,
      androidToDomKey,
    );

    // Logical
    final String gtkKeyCodes = await getGtkKeyCodes();
    final String webLogicalKeys = await getChromiumKeys();
    final String supplementalKeyData = readDataFile('supplemental_key_data.inc');
    final String gtkToDomKey = readDataFile('gtk_logical_name_mapping.json');
    final String windowsKeyCodes = await getWindowsKeyCodes();
    final String windowsToDomKey = readDataFile('windows_logical_to_window_vk.json');
    final String macosLogicalToPhysical = readDataFile('macos_logical_to_physical.json');
    final String iosLogicalToPhysical = readDataFile('ios_logical_to_physical.json');
    final String androidKeyCodes = await getAndroidKeyCodes();
    final String glfwKeyCodes = await getGlfwKeyCodes();
    final String glfwToDomKey = readDataFile('glfw_key_name_to_name.json');

    logicalData = LogicalKeyData(
      <String>[webLogicalKeys, supplementalKeyData].join('\n'),
      gtkKeyCodes,
      gtkToDomKey,
      windowsKeyCodes,
      windowsToDomKey,
      androidKeyCodes,
      androidToDomKey,
      macosLogicalToPhysical,
      iosLogicalToPhysical,
      glfwKeyCodes,
      glfwToDomKey,
      physicalData,
    );

    // Write data files
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String physicalJson = encoder.convert(physicalData.toJson());
    File(parsedArguments['physical-data'] as String).writeAsStringSync('$physicalJson\n');
    final String logicalJson = encoder.convert(logicalData.toJson());
    File(parsedArguments['logical-data'] as String).writeAsStringSync('$logicalJson\n');
  } else {
    physicalData = PhysicalKeyData.fromJson(json.decode(await File(parsedArguments['physical-data'] as String).readAsString()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(json.decode(await File(parsedArguments['logical-data'] as String).readAsString()) as Map<String, dynamic>);
  }

  final File codeFile = File(parsedArguments['code'] as String);
  if (!codeFile.existsSync()) {
    codeFile.createSync(recursive: true);
  }
  print('Writing ${'key codes'.padRight(15)}${codeFile.absolute}');
  await codeFile.writeAsString(KeyboardKeysCodeGenerator(physicalData, logicalData).generate());

  final File mapsFile = File(parsedArguments['maps'] as String);
  if (!mapsFile.existsSync()) {
    mapsFile.createSync(recursive: true);
  }
  print('Writing ${'key maps'.padRight(15)}${mapsFile.absolute}');
  await mapsFile.writeAsString(KeyboardMapsCodeGenerator(physicalData, logicalData).generate());

  final File keyCodesFile = File(path.join(PlatformCodeGenerator.engineRoot,
      'shell', 'platform', 'embedder', 'test_utils', 'key_codes.h'));
  if (!mapsFile.existsSync()) {
    mapsFile.createSync(recursive: true);
  }
  print('Writing ${'engine key codes'.padRight(15)}${mapsFile.absolute}');
  await keyCodesFile.writeAsString(KeyCodesCcGenerator(physicalData, logicalData).generate());

  final Map<String, PlatformCodeGenerator> platforms = <String, PlatformCodeGenerator>{
    'android': AndroidCodeGenerator(
      physicalData,
      logicalData,
    ),
    'macos': MacOSCodeGenerator(
      physicalData,
      logicalData,
    ),
    'ios': IOSCodeGenerator(
      physicalData,
      logicalData,
    ),
    'windows': WindowsCodeGenerator(
      physicalData,
      logicalData,
      readDataFile('windows_scancode_logical_map.json')
    ),
    'linux': GtkCodeGenerator(
      physicalData,
      logicalData,
      readDataFile('gtk_modifier_bit_mapping.json'),
      readDataFile('gtk_lock_bit_mapping.json'),
    ),
    'web': WebCodeGenerator(
      physicalData,
      logicalData,
      readDataFile('web_logical_location_mapping.json'),
    ),
  };
  await Future.wait(platforms.entries.map((MapEntry<String, PlatformCodeGenerator> entry) {
    final String platform = entry.key;
    final PlatformCodeGenerator codeGenerator = entry.value;
    final File platformFile = File(codeGenerator.outputPath(platform));
    if (!platformFile.existsSync()) {
      platformFile.createSync(recursive: true);
    }
    print('Writing ${'$platform map'.padRight(15)}${platformFile.absolute}');
    return platformFile.writeAsString(codeGenerator.generate());
  }));
}
