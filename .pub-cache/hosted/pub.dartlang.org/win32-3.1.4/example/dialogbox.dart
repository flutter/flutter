// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Creates a custom dialog box from code.

// ignore_for_file: constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const ID_TEXT = 200;
const ID_EDITTEXT = 201;
const ID_PROGRESS = 202;

final hInstance = GetModuleHandle(nullptr);
String textEntered = '';

void main() {
  // Allocate 8KB, which is more than enough space for the dialog in memory.
  final ptr = calloc<Uint16>(4096);
  var idx = 0;

  idx += ptr.elementAt(idx).cast<DLGTEMPLATE>().setDialog(
      style: WS_POPUP |
          WS_BORDER |
          WS_SYSMENU |
          DS_MODALFRAME |
          DS_SETFONT |
          WS_CAPTION,
      title: 'Sample dialog',
      cdit: 4,
      cx: 300,
      cy: 200,
      fontName: 'MS Shell Dlg',
      fontSize: 8);

  idx += ptr.elementAt(idx).cast<DLGITEMTEMPLATE>().setDialogItem(
      style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON,
      x: 100,
      y: 160,
      cx: 50,
      cy: 14,
      id: IDOK,
      windowSystemClass: 0x0080, // button
      text: 'OK');

  idx += ptr.elementAt(idx).cast<DLGITEMTEMPLATE>().setDialogItem(
      style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,
      x: 190,
      y: 160,
      cx: 50,
      cy: 14,
      id: IDCANCEL,
      windowSystemClass: 0x0080, // button
      text: 'Cancel');

  idx += ptr.elementAt(idx).cast<DLGITEMTEMPLATE>().setDialogItem(
      style: WS_CHILD | WS_VISIBLE,
      x: 10,
      y: 10,
      cx: 60,
      cy: 20,
      id: ID_TEXT,
      windowSystemClass: 0x0082, // static
      text: 'Some static wrapped text here.');

  idx += ptr.elementAt(idx).cast<DLGITEMTEMPLATE>().setDialogItem(
      style: PBS_SMOOTH | WS_BORDER | WS_VISIBLE,
      x: 6,
      y: 49,
      cx: 158,
      cy: 12,
      id: ID_PROGRESS,
      windowClass: 'msctls_progress32' // progress bar
      );

  idx += ptr.elementAt(idx).cast<DLGITEMTEMPLATE>().setDialogItem(
      style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_BORDER,
      x: 20,
      y: 50,
      cx: 100,
      cy: 20,
      id: ID_EDITTEXT,
      windowSystemClass: 0x0081, // edit
      text: 'Enter text');

  final lpDialogFunc = Pointer.fromFunction<DlgProc>(dialogReturnProc, 0);

  final nResult = DialogBoxIndirectParam(
      hInstance, ptr.cast<DLGTEMPLATE>(), NULL, lpDialogFunc, 0);

  if (nResult <= 0) {
    print('Error: $nResult');
  } else {
    print('Entered: $textEntered');
  }
  free(ptr);
}

// Documentation on this function here:
// https://docs.microsoft.com/en-us/windows/win32/dlgbox/using-dialog-boxes
int dialogReturnProc(int hwndDlg, int message, int wParam, int lParam) {
  switch (message) {
    case WM_INITDIALOG:
      {
        SendDlgItemMessage(hwndDlg, ID_PROGRESS, PBM_SETPOS, 35, 0);
        break;
      }
    case WM_COMMAND:
      {
        switch (LOWORD(wParam)) {
          case IDOK:
            print('OK');
            final textPtr = wsalloc(256);
            GetDlgItemText(hwndDlg, ID_EDITTEXT, textPtr, 256);
            textEntered = textPtr.toDartString();
            free(textPtr);
            EndDialog(hwndDlg, wParam);
            return TRUE;
          case IDCANCEL:
            print('Cancel');
            EndDialog(hwndDlg, wParam);
            return TRUE;
        }
      }
  }

  return FALSE;
}
