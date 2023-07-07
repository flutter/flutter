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
  test('Can instantiate IFileDialogCustomize.EnableOpenDropDown', () {
    expect(filedialogcustomize.EnableOpenDropDown, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddMenu', () {
    expect(filedialogcustomize.AddMenu, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddPushButton', () {
    expect(filedialogcustomize.AddPushButton, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddComboBox', () {
    expect(filedialogcustomize.AddComboBox, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddRadioButtonList', () {
    expect(filedialogcustomize.AddRadioButtonList, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddCheckButton', () {
    expect(filedialogcustomize.AddCheckButton, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddEditBox', () {
    expect(filedialogcustomize.AddEditBox, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddSeparator', () {
    expect(filedialogcustomize.AddSeparator, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddText', () {
    expect(filedialogcustomize.AddText, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetControlLabel', () {
    expect(filedialogcustomize.SetControlLabel, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.GetControlState', () {
    expect(filedialogcustomize.GetControlState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetControlState', () {
    expect(filedialogcustomize.SetControlState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.GetEditBoxText', () {
    expect(filedialogcustomize.GetEditBoxText, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetEditBoxText', () {
    expect(filedialogcustomize.SetEditBoxText, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.GetCheckButtonState', () {
    expect(filedialogcustomize.GetCheckButtonState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetCheckButtonState', () {
    expect(filedialogcustomize.SetCheckButtonState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.AddControlItem', () {
    expect(filedialogcustomize.AddControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.RemoveControlItem', () {
    expect(filedialogcustomize.RemoveControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.RemoveAllControlItems', () {
    expect(filedialogcustomize.RemoveAllControlItems, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.GetControlItemState', () {
    expect(filedialogcustomize.GetControlItemState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetControlItemState', () {
    expect(filedialogcustomize.SetControlItemState, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.GetSelectedControlItem', () {
    expect(filedialogcustomize.GetSelectedControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetSelectedControlItem', () {
    expect(filedialogcustomize.SetSelectedControlItem, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.StartVisualGroup', () {
    expect(filedialogcustomize.StartVisualGroup, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.EndVisualGroup', () {
    expect(filedialogcustomize.EndVisualGroup, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.MakeProminent', () {
    expect(filedialogcustomize.MakeProminent, isA<Function>());
  });
  test('Can instantiate IFileDialogCustomize.SetControlItemText', () {
    expect(filedialogcustomize.SetControlItemText, isA<Function>());
  });
  free(ptr);
}
