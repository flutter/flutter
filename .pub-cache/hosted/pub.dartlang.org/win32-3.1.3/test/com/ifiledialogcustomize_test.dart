// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that Win32 API prototypes can be successfully loaded (i.e. that
// lookupFunction works for all the APIs generated)

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_local_variable

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'package:win32/win32.dart';

void main() {
  final ptr = calloc<COMObject>();

  final filedialogcustomize = IFileDialogCustomize(ptr);
  test('Can instantiate IFileDialogCustomize.enableOpenDropDown', () {
    expect(filedialogcustomize.enableOpenDropDown, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addMenu', () {
    expect(filedialogcustomize.addMenu, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addPushButton', () {
    expect(filedialogcustomize.addPushButton, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addComboBox', () {
    expect(filedialogcustomize.addComboBox, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addRadioButtonList', () {
    expect(filedialogcustomize.addRadioButtonList, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addCheckButton', () {
    expect(filedialogcustomize.addCheckButton, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addEditBox', () {
    expect(filedialogcustomize.addEditBox, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addSeparator', () {
    expect(filedialogcustomize.addSeparator, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addText', () {
    expect(filedialogcustomize.addText, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setControlLabel', () {
    expect(filedialogcustomize.setControlLabel, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.getControlState', () {
    expect(filedialogcustomize.getControlState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setControlState', () {
    expect(filedialogcustomize.setControlState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.getEditBoxText', () {
    expect(filedialogcustomize.getEditBoxText, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setEditBoxText', () {
    expect(filedialogcustomize.setEditBoxText, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.getCheckButtonState', () {
    expect(filedialogcustomize.getCheckButtonState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setCheckButtonState', () {
    expect(filedialogcustomize.setCheckButtonState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.addControlItem', () {
    expect(filedialogcustomize.addControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.removeControlItem', () {
    expect(filedialogcustomize.removeControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.removeAllControlItems', () {
    expect(filedialogcustomize.removeAllControlItems, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.getControlItemState', () {
    expect(filedialogcustomize.getControlItemState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setControlItemState', () {
    expect(filedialogcustomize.setControlItemState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.getSelectedControlItem', () {
    expect(filedialogcustomize.getSelectedControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setSelectedControlItem', () {
    expect(filedialogcustomize.setSelectedControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.startVisualGroup', () {
    expect(filedialogcustomize.startVisualGroup, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.endVisualGroup', () {
    expect(filedialogcustomize.endVisualGroup, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.makeProminent', () {
    expect(filedialogcustomize.makeProminent, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.setControlItemText', () {
    expect(filedialogcustomize.setControlItemText, isA<Function>());
  });
  free(ptr);
}
