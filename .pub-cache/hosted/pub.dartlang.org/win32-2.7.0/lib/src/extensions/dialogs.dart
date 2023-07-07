// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension methods to help set the dialog templates from memory.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../constants.dart';
import '../structs.g.dart';

import 'set_string.dart';

extension DialogTemplateHelper on Pointer<DLGTEMPLATE> {
  /// Sets the memory at the pointer location to the dialog supplied.
  ///
  /// Returns the number of WORDs written.
  int setDialog(
      {required int style,
      int dwExtendedStyle = 0,
      required int cdit,
      int x = 0,
      int y = 0,
      required int cx,
      required int cy,
      int windowSystemClass = 0,
      String windowClass = '',
      String title = '',
      String fontName = '',
      int fontSize = 0}) {
    /// Size in 16-bit WORDs of the DLGTEMPLATE struct
    const dlgTemplateSize = 9;

    final ptr = cast<Uint16>();

    var idx = 0; // 16-bit index offset

    /// Specifies the properties of the DLGTEMPLATE structure.
    ptr.cast<DLGTEMPLATE>().ref
      ..style = style
      ..dwExtendedStyle = dwExtendedStyle
      ..cdit = cdit
      ..x = x
      ..y = y
      ..cx = cx
      ..cy = cy;

    idx += dlgTemplateSize;

    // Immediately following the DLGTEMPLATE structure is a menu array that
    // identifies a menu resource for the dialog box. If the first element of
    // this array is 0x0000, the dialog box has no menu and the array has no
    // other elements. Since Dart does not currently support embedding a
    // resource file in a Windows executable, the other settings are moot.
    ptr[idx++] = 0x0000;

    // Following the menu array is a class array that identifies the window
    // class of the dialog box. If the first element of the array is 0x0000, the
    // system uses the predefined dialog box class for the dialog box and the
    // array has no other elements. If the first element is 0xFFFF, the array
    // has one additional element that specifies the ordinal value of a
    // predefined system window class. If the first element has any other value,
    // the system treats the array as a null-terminated Unicode string that
    // specifies the name of a registered window class.
    if (windowClass.isNotEmpty) {
      idx +=
          (ptr.elementAt(idx).cast<Utf16>().setString(windowClass) / 2).ceil();
    } else {
      if (windowSystemClass != 0) {
        ptr[idx++] = 0xFFFF;
        ptr[idx++] = windowSystemClass;
      } else {
        ptr[idx++] = 0x0000;
      }
    }

    /// Following the class array is a title array that specifies a
    /// null-terminated Unicode string that contains the title of the dialog
    /// box. If the first element of this array is 0x0000, the dialog box has no
    /// title and the array has no other elements.
    if (title.isEmpty) {
      ptr[idx++] = 0x0000;
    } else {
      idx += (ptr.elementAt(idx).cast<Utf16>().setString(title) / 2).ceil();
    }

    /// Following the title array is a 16-bit point size value and the typeface
    /// array, in that order, if the style member specifies the DS_SETFONT
    /// style. These are set for the dialog box. The typeface array is a
    /// null-terminated Unicode string.
    if ((style & DS_SETFONT == DS_SETFONT) && (fontName.isNotEmpty)) {
      ptr[idx++] = fontSize;
      idx += (ptr.elementAt(idx).cast<Utf16>().setString(fontName) / 2).ceil();
    }

    // Each DLGITEMTEMPLATE structure in the template must be aligned on a DWORD
    // boundary. Move idx forward so that it aligns to the next DWORD boundary.
    if ((ptr.address + idx) % 2 != 0) {
      ptr[idx++] = 0x0000;
    }
    return idx;
  }
}

extension DialogItemTemplateHelper on Pointer<DLGITEMTEMPLATE> {
  /// Sets the memory at the pointer location to the dialog item supplied.
  ///
  /// Returns the number of WORDs written.
  int setDialogItem({
    required int style,
    int dwExtendedStyle = 0,
    required int x,
    required int y,
    required int cx,
    required int cy,
    required int id,
    int windowSystemClass = 0,
    String windowClass = '',
    String text = '',
    List<int> creationDataBytes = const [],
  }) {
    /// Size in 16-bit WORDs of the DLGITEMTEMPLATE struct
    const dlgItemTemplateSize = 9;

    final ptr = cast<Uint16>();
    var idx = 0; // 16-bit index offset

    /// Specifies the properties of the DLGITEMTEMPLATE structure.
    ptr.cast<DLGITEMTEMPLATE>().ref
      ..style = style
      ..dwExtendedStyle = dwExtendedStyle
      ..x = x
      ..y = y
      ..cx = cx
      ..cy = cy
      ..id = id;
    idx += dlgItemTemplateSize;

    /// Immediately following each DLGITEMTEMPLATE structure is a class array
    /// that specifies the window class of the control. If the first element of
    /// this array is any value other than 0xFFFF, the system treats the array
    /// as a null-terminated Unicode string that specifies the name of a
    /// registered window class. If the first element is 0xFFFF, the array has
    /// one additional element that specifies the ordinal value of a predefined
    /// system class.
    ///
    /// The ordinal can be one of the following atom values: 0x0080: Button
    ///   0x0081: Edit 0x0082: Static 0x0083: List box 0x0084: Scroll bar
    ///   0x0085: Combo box
    if (windowClass.isNotEmpty) {
      idx +=
          (ptr.elementAt(idx).cast<Utf16>().setString(windowClass) / 2).ceil();
    } else {
      ptr[idx++] = 0xFFFF;
      ptr[idx++] = windowSystemClass;
    }

    // Following the class array is a title array that contains the initial text
    // or resource identifier of the control.
    idx += (ptr.elementAt(idx).cast<Utf16>().setString(text) / 2).ceil();

    // The creation data array begins at the next WORD boundary after the title
    // array. This creation data can be of any size and format. If the first
    // word of the creation data array is nonzero, it indicates the size, in
    // bytes, of the creation data (including the size word).
    if (creationDataBytes.isNotEmpty) {
      ptr[idx++] = creationDataBytes.length + 1;
      ptr
        ..elementAt(idx)
        ..cast<Uint8>()
        ..asTypedList(creationDataBytes.length).setAll(0, creationDataBytes);
      idx += (creationDataBytes.length / 2).ceil();
    } else {
      ptr[idx++] = 0x0000;
    }

    // Move idx forward so that it aligns to the next DWORD boundary
    if ((ptr.address + idx) % 2 != 0) {
      ptr[idx++] = 0x0000;
    }
    return idx;
  }
}
