// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:gen_keycodes/android_code_gen.dart';
import 'package:gen_keycodes/base_code_gen.dart';
import 'package:gen_keycodes/macos_code_gen.dart';
import 'package:gen_keycodes/fuchsia_code_gen.dart';
import 'package:gen_keycodes/glfw_code_gen.dart';
import 'package:gen_keycodes/gtk_code_gen.dart';
import 'package:gen_keycodes/windows_code_gen.dart';
import 'package:gen_keycodes/web_code_gen.dart';
import 'package:gen_keycodes/keyboard_keys_code_gen.dart';
import 'package:gen_keycodes/keyboard_maps_code_gen.dart';
import 'package:gen_keycodes/physical_key_data.dart';
import 'package:gen_keycodes/logical_key_data.dart';
import 'package:gen_keycodes/utils.dart';
import 'package:gen_keycodes/mask_constants.dart';

/// Get contents of the file that contains the physical key mapping in Chromium
/// source.
Future<String> getChromiumPhysicalKeys() async {
  final Uri keyCodesUri = Uri.parse('https://chromium.googlesource.com/codesearch/chromium/src/+/refs/heads/master/ui/events/keycodes/dom/dom_code_data.inc?format=TEXT');
  return utf8.decode(base64.decode(await http.read(keyCodesUri)));
}

/// Get contents of the file that contains the logical key mapping in Chromium
/// source.
Future<String> getChromiumLogicalKeys() async {
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
  return await http.read(keyCodesUri);
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
  return await http.read(keyCodesUri);
}

Future<String> getGtkKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://gitlab.gnome.org/GNOME/gtk/-/raw/master/gdk/gdkkeysyms.h');
  return await http.read(keyCodesUri);
}

Future<void> main(List<String> rawArguments) async {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'chromium-hid-codes',
    defaultsTo: null,
    help: 'The path to where the Chromium HID code mapping file should be '
        'read. If --chromium-hid-codes is not specified, the input will be read '
        'from the correct file in the Chromium repository.',
  );
  argParser.addOption(
    'chromium-keys',
    defaultsTo: null,
    help: 'The path to where the Chromium key list file should be '
        'read. If --chromium-keys is not specified, the input will be read '
        'from the correct file in the Chromium repository.',
  );
  argParser.addOption(
    'supplemental-hid-codes',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'supplemental_hid_codes.inc'),
    help: "The path to where the supplemental HID codes that don't appear in the "
        'Chromium map should be read.',
  );
  argParser.addOption(
    'android-keycodes',
    defaultsTo: null,
    help: 'The path to where the Android keycodes header file should be read. '
        'If --android-keycodes is not specified, the input will be read from the '
        'correct file in the Android repository.',
  );
  argParser.addOption(
    'android-scancodes',
    defaultsTo: null,
    help: 'The path to where the Android scancodes header file should be read. '
      'If --android-scancodes is not specified, the input will be read from the '
      'correct file in the Android repository.',
  );
  argParser.addOption(
    'android-domkey',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_name_to_android_name.json'),
    help: 'The path to where the Android keycode to DomKey mapping is.',
  );
  argParser.addOption(
    'glfw-keycodes',
    defaultsTo: null,
    help: 'The path to where the GLFW keycodes header file should be read. '
        'If --glfw-keycodes is not specified, the input will be read from the '
        'correct file in the GLFW github repository.',
  );
  argParser.addOption(
    'gtk-keycodes',
    defaultsTo: null,
    help: 'The path to where the GTK keycodes header file should be read. '
        'If --gtk-keycodes is not specified, the input will be read from the '
        'correct file in the GTK repository.',
  );
  argParser.addOption(
    'windows-keycodes',
    defaultsTo: null,
    help: 'The path to where the Windows keycodes header file should be read. '
        'If --windows-keycodes is not specified, the input will be read from the '
        'correct file in the Windows github repository.',
  );
  argParser.addOption(
    'windows-domkey',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_name_to_windows_name.json'),
    help: 'The path to where the Windows keycode to DomKey mapping is.',
  );
  argParser.addOption(
    'glfw-domkey',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_name_to_glfw_name.json'),
    help: 'The path to where the GLFW keycode to DomKey mapping is.',
  );
  argParser.addOption(
    'gtk-domkey',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_name_to_gtk_name.json'),
    help: 'The path to where the GTK keycode to DomKey mapping is.',
  );
  argParser.addOption(
    'mask-constants',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'mask_constants.json'),
    help: 'The path to where the mask constants are.',
  );
  argParser.addOption(
    'physical-data',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'physical_key_data.json'),
    help: 'The path to where the physical key data file should be written when '
        'collected, and read from when generating output code. If --physical-data is '
        'not specified, the output will be written to/read from the current '
        "directory. If the output directory doesn't exist, it, and the path to "
        'it, will be created.',
  );
  argParser.addOption(
    'logical-data',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'logical_key_data.json'),
    help: 'The path to where the logical key data file should be written when '
        'collected, and read from when generating output code. If --logical-data is '
        'not specified, the output will be written to/read from the current '
        "directory. If the output directory doesn't exist, it, and the path to "
        'it, will be created.',
  );
  argParser.addOption(
    'code',
    defaultsTo: path.join(flutterRoot.path, 'packages', 'flutter', 'lib', 'src', 'services', 'keyboard_key.dart'),
    help: 'The path to where the output "keyboard_keys.dart" file should be '
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
    defaultsTo: false,
    negatable: false,
    help: 'If this flag is set, then collect and parse header files from '
        'Chromium and Android instead of reading pre-parsed data from '
        '"physical_key_data.json" and "logical_key_data.json", and then '
        'update these files with the fresh data.',
  );
  argParser.addFlag(
    'help',
    defaultsTo: false,
    negatable: false,
    help: 'Print help for this command.',
  );

  final ArgResults parsedArguments = argParser.parse(rawArguments);

  if (parsedArguments['help'] as bool) {
    print(argParser.usage);
    exit(0);
  }

  PhysicalKeyData physicalData;
  LogicalKeyData logicalData;
  if (parsedArguments['collect'] as bool) {
    final String baseHidCodes = parsedArguments['chromium-hid-codes'] == null ?
      await getChromiumPhysicalKeys() :
      File(parsedArguments['chromium-hid-codes'] as String).readAsStringSync();

    final String supplementalHidCodes = File(parsedArguments['supplemental-hid-codes'] as String).readAsStringSync();
    final String hidCodes = '$baseHidCodes\n$supplementalHidCodes';

    final String logicalKeys = parsedArguments['chromium-keys'] == null ?
      await getChromiumLogicalKeys() :
      File(parsedArguments['chromium-keys'] as String).readAsStringSync();

    final String androidKeyCodes = parsedArguments['android-keycodes'] == null ?
      await getAndroidKeyCodes() :
      File(parsedArguments['android-keycodes'] as String).readAsStringSync();

    final String androidScanCodes = parsedArguments['android-scancodes'] == null ?
      await getAndroidScanCodes() :
      File(parsedArguments['android-scancodes'] as String).readAsStringSync();

    final String glfwKeyCodes = parsedArguments['glfw-keycodes'] == null ?
      await getGlfwKeyCodes() :
      File(parsedArguments['glfw-keycodes'] as String).readAsStringSync();

    final String gtkKeyCodes = parsedArguments['gtk-keycodes'] == null ?
      await getGtkKeyCodes() :
      File(parsedArguments['gtk-keycodes'] as String).readAsStringSync();

    final String windowsKeyCodes = parsedArguments['windows-keycodes'] == null ?
      await getWindowsKeyCodes() :
      File(parsedArguments['windows-keycodes'] as String).readAsStringSync();

    final String windowsToDomKey = File(parsedArguments['windows-domkey'] as String).readAsStringSync();
    final String glfwToDomKey = File(parsedArguments['glfw-domkey'] as String).readAsStringSync();
    final String gtkToDomKey = File(parsedArguments['gtk-domkey'] as String).readAsStringSync();
    final String androidToDomKey = File(parsedArguments['android-domkey'] as String).readAsStringSync();

    physicalData = PhysicalKeyData(hidCodes, androidScanCodes, androidKeyCodes, androidToDomKey, glfwKeyCodes, glfwToDomKey, gtkKeyCodes, gtkToDomKey, windowsKeyCodes, windowsToDomKey);
    logicalData = LogicalKeyData(logicalKeys);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    File(parsedArguments['physical-data'] as String).writeAsStringSync(encoder.convert(physicalData.toJson()));
    File(parsedArguments['logical-data'] as String).writeAsStringSync(encoder.convert(logicalData.toJson()));
  } else {
    physicalData = PhysicalKeyData.fromJson(json.decode(await File(parsedArguments['physical-data'] as String).readAsString()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(json.decode(await File(parsedArguments['logical-data'] as String).readAsString()) as Map<String, dynamic>);
  }

  List<MaskConstant> maskConstants = parseMaskConstants(json.decode(await File(parsedArguments['mask-constants'] as String).readAsString()));

  final File codeFile = File(parsedArguments['code'] as String);
  if (!codeFile.existsSync()) {
    codeFile.createSync(recursive: true);
  }
  print('Writing ${'key codes'.padRight(15)}${codeFile.absolute}');
  await codeFile.writeAsString(KeyboardKeysCodeGenerator(physicalData).generate());

  final File mapsFile = File(parsedArguments['maps'] as String);
  if (!mapsFile.existsSync()) {
    mapsFile.createSync(recursive: true);
  }
  print('Writing ${'key maps'.padRight(15)}${mapsFile.absolute}');
  await mapsFile.writeAsString(KeyboardMapsCodeGenerator(physicalData).generate());

  for (final String platform in <String>['android', 'darwin', 'glfw', 'fuchsia', 'linux', 'windows', 'web']) {
    PlatformCodeGenerator codeGenerator;
    switch (platform) {
      case 'glfw':
        codeGenerator = GlfwCodeGenerator(physicalData);
        break;
      case 'fuchsia':
        codeGenerator = FuchsiaCodeGenerator(physicalData);
        break;
      case 'android':
        codeGenerator = AndroidCodeGenerator(physicalData);
        break;
      case 'darwin':
        codeGenerator = MacOsCodeGenerator(physicalData, maskConstants);
        break;
      case 'windows':
        codeGenerator = WindowsCodeGenerator(physicalData);
        break;
      case 'linux':
        codeGenerator = GtkCodeGenerator(physicalData);
        break;
      case 'web':
        codeGenerator = WebCodeGenerator(physicalData);
        break;
      default:
        assert(false);
    }

    final File platformFile = File(codeGenerator.outputPath(platform));
    if (!platformFile.existsSync()) {
      platformFile.createSync(recursive: true);
    }
    print('Writing ${'$platform map'.padRight(15)}${platformFile.absolute}');
    await platformFile.writeAsString(codeGenerator.generate());
  }
}
