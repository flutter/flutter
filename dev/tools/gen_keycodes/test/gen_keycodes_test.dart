// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:gen_keycodes/android_code_gen.dart';
import 'package:gen_keycodes/base_code_gen.dart';
import 'package:gen_keycodes/gtk_code_gen.dart';
import 'package:gen_keycodes/ios_code_gen.dart';
import 'package:gen_keycodes/logical_key_data.dart';
import 'package:gen_keycodes/macos_code_gen.dart';
import 'package:gen_keycodes/physical_key_data.dart';
import 'package:gen_keycodes/utils.dart';
import 'package:gen_keycodes/web_code_gen.dart';
import 'package:gen_keycodes/windows_code_gen.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

String readDataFile(String fileName) {
  return File(path.join(dataRoot, fileName)).readAsStringSync();
}

final String testPhysicalData = path.join(dataRoot, 'physical_key_data.json');
final String testLogicalData = path.join(dataRoot,'logical_key_data.json');

void main() {
  setUp(() {
    testDataRoot = path.canonicalize(path.join(Directory.current.absolute.path, 'data'));
  });

  tearDown((){
    testDataRoot = null;
  });

  void checkCommonOutput(String output) {
    expect(output, contains(RegExp('Copyright 201[34]')));
    expect(output, contains('DO NOT EDIT'));
    expect(output, contains(RegExp(r'\b[kK]eyA\b')));
    expect(output, contains(RegExp(r'\b[Dd]igit1\b')));
    expect(output, contains(RegExp(r'\b[Ff]1\b')));
    expect(output, contains(RegExp(r'\b[Nn]umpad1\b')));
    expect(output, contains(RegExp(r'\b[Ss]hiftLeft\b')));
  }

  test('Generate Keycodes for Android', () {
    PhysicalKeyData physicalData;
    LogicalKeyData logicalData;

    physicalData = PhysicalKeyData.fromJson(
        json.decode(File(testPhysicalData).readAsStringSync()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(
        json.decode(File(testLogicalData).readAsStringSync()) as Map<String, dynamic>);

    const String platform = 'android';
    final PlatformCodeGenerator codeGenerator = AndroidCodeGenerator(
      physicalData,
      logicalData,
    );
    final String output = codeGenerator.generate();

    expect(codeGenerator.outputPath(platform), endsWith('KeyboardMap.java'));
    expect(output, contains('class KeyboardMap'));
    expect(output, contains('scanCodeToPhysical'));
    expect(output, contains('keyCodeToLogical'));
    checkCommonOutput(output);
  });
  test('Generate Keycodes for macOS', () {
    PhysicalKeyData physicalData;
    LogicalKeyData logicalData;

    physicalData = PhysicalKeyData.fromJson(
        json.decode(File(testPhysicalData).readAsStringSync()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(
        json.decode(File(testLogicalData).readAsStringSync()) as Map<String, dynamic>);

    const String platform = 'macos';
    final PlatformCodeGenerator codeGenerator = MacOSCodeGenerator(
      physicalData,
      logicalData,
    );
    final String output = codeGenerator.generate();

    expect(codeGenerator.outputPath(platform), endsWith('KeyCodeMap.mm'));
    expect(output, contains('kValueMask'));
    expect(output, contains('keyCodeToPhysicalKey'));
    expect(output, contains('keyCodeToLogicalKey'));
    expect(output, contains('keyCodeToModifierFlag'));
    expect(output, contains('modifierFlagToKeyCode'));
    expect(output, contains('kCapsLockPhysicalKey'));
    expect(output, contains('kCapsLockLogicalKey'));
    checkCommonOutput(output);
  });
  test('Generate Keycodes for iOS', () {
    PhysicalKeyData physicalData;
    LogicalKeyData logicalData;

    physicalData = PhysicalKeyData.fromJson(
        json.decode(File(testPhysicalData).readAsStringSync()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(
        json.decode(File(testLogicalData).readAsStringSync()) as Map<String, dynamic>);

    const String platform = 'ios';
    final PlatformCodeGenerator codeGenerator = IOSCodeGenerator(
      physicalData,
      logicalData,
    );
    final String output = codeGenerator.generate();

    expect(codeGenerator.outputPath(platform), endsWith('KeyCodeMap.mm'));
    expect(output, contains('kValueMask'));
    expect(output, contains('keyCodeToPhysicalKey'));
    expect(output, contains('keyCodeToLogicalKey'));
    expect(output, contains('keyCodeToModifierFlag'));
    expect(output, contains('modifierFlagToKeyCode'));
    expect(output, contains('functionKeyCodes'));
    expect(output, contains('kCapsLockPhysicalKey'));
    expect(output, contains('kCapsLockLogicalKey'));
    checkCommonOutput(output);
  });
  test('Generate Keycodes for Windows', () {
    PhysicalKeyData physicalData;
    LogicalKeyData logicalData;

    physicalData = PhysicalKeyData.fromJson(
        json.decode(File(testPhysicalData).readAsStringSync()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(
        json.decode(File(testLogicalData).readAsStringSync()) as Map<String, dynamic>);

    const String platform = 'windows';
    final PlatformCodeGenerator codeGenerator = WindowsCodeGenerator(
      physicalData,
      logicalData,
      readDataFile(path.join(dataRoot, 'windows_scancode_logical_map.json')),
    );
    final String output = codeGenerator.generate();

    expect(codeGenerator.outputPath(platform), endsWith('flutter_key_map.cc'));
    expect(output, contains('KeyboardKeyEmbedderHandler::windowsToPhysicalMap_'));
    expect(output, contains('KeyboardKeyEmbedderHandler::windowsToLogicalMap_'));
    expect(output, contains('KeyboardKeyEmbedderHandler::scanCodeToLogicalMap_'));
    checkCommonOutput(output);
  });
  test('Generate Keycodes for Linux', () {
    PhysicalKeyData physicalData;
    LogicalKeyData logicalData;

    physicalData = PhysicalKeyData.fromJson(
        json.decode(File(testPhysicalData).readAsStringSync()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(
        json.decode(File(testLogicalData).readAsStringSync()) as Map<String, dynamic>);

    const String platform = 'gtk';
    final PlatformCodeGenerator codeGenerator = GtkCodeGenerator(
      physicalData,
      logicalData,
      readDataFile(path.join(dataRoot, 'gtk_modifier_bit_mapping.json')),
      readDataFile(path.join(dataRoot, 'gtk_lock_bit_mapping.json')),
    );
    final String output = codeGenerator.generate();

    expect(codeGenerator.outputPath(platform), endsWith('key_mapping.cc'));
    expect(output, contains('initialize_modifier_bit_to_checked_keys'));
    expect(output, contains('initialize_lock_bit_to_checked_keys'));
    checkCommonOutput(output);
  });
  test('Generate Keycodes for Web', () {
    PhysicalKeyData physicalData;
    LogicalKeyData logicalData;

    physicalData = PhysicalKeyData.fromJson(
        json.decode(File(testPhysicalData).readAsStringSync()) as Map<String, dynamic>);
    logicalData = LogicalKeyData.fromJson(
        json.decode(File(testLogicalData).readAsStringSync()) as Map<String, dynamic>);

    const String platform = 'web';
    final PlatformCodeGenerator codeGenerator = WebCodeGenerator(
      physicalData,
      logicalData,
      readDataFile(path.join(dataRoot, 'web_logical_location_mapping.json')),
    );
    final String output = codeGenerator.generate();

    expect(codeGenerator.outputPath(platform), endsWith('key_map.dart'));
    expect(output, contains('kWebToLogicalKey'));
    expect(output, contains('kWebToPhysicalKey'));
    expect(output, contains('kWebLogicalLocationMap'));
    checkCommonOutput(output);
  });
}
