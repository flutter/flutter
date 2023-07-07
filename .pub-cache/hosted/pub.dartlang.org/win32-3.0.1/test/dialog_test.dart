// ignore_for_file: constant_identifier_names

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:test/test.dart';
import 'package:win32/win32.dart';

const ID_TEXT = 200;
const ID_EDITTEXT = 201;
const ID_PROGRESS = 202;

const dialogGolden = [
  // DLGTEMPLATE
  0x00c0, 0x80c8, 0x0000, 0x0000, 0x0004, 0x0000, 0x0000, 0x012c, 0x00c8,
  0x0000, 0x0000,

  // TEXT: Sample Dialog
  0x0053, 0x0061, 0x006d, 0x0070, 0x006c, 0x0065, 0x0020, 0x0064,
  0x0069, 0x0061, 0x006c, 0x006f, 0x0067, 0x0000,

  // FONT: 8pt MS Shell Dlg
  0x0008, 0x004d, 0x0053, 0x0020, 0x0053, 0x0068, 0x0065, 0x006c,
  0x006c, 0x0020, 0x0044, 0x006c, 0x0067, 0x0000, 0x0000,

  // DLGITEMTEMPLATE [OK]
  0x0001, 0x5001, 0x0000, 0x0000, 0x0064, 0x00a0, 0x0032, 0x000e,
  0x0001, 0xffff, 0x0080, 0x004f, 0x004b, 0x0000, 0x0000, 0x0000,

  // DLGITEMTEMPLATE [Cancel]
  0x0000, 0x5001, 0x0000, 0x0000, 0x00be, 0x00a0, 0x0032, 0x000e,
  0x0002, 0xffff, 0x0080, 0x0043, 0x0061, 0x006e, 0x0063, 0x0065,
  0x006c, 0x0000, 0x0000, 0x0000,

  // DLGITEMTEMPLATE [Static Text]
  0x0000, 0x5000, 0x0000, 0x0000, 0x000a, 0x000a, 0x003c, 0x0014,
  0x00c8, 0xffff, 0x0082, 0x0053, 0x006f, 0x006d, 0x0065, 0x0020,
  0x0073, 0x0074, 0x0061, 0x0074, 0x0069, 0x0063, 0x0020, 0x0077,
  0x0072, 0x0061, 0x0070, 0x0070, 0x0065, 0x0064, 0x0020, 0x0074,
  0x0065, 0x0078, 0x0074, 0x0020, 0x0068, 0x0065, 0x0072, 0x0065,
  0x002e, 0x0000, 0x0000, 0x0000,

  // DLGITEMTEMPLATE [Progress Bar]
  0x0001, 0x1080, 0x0000, 0x0000, 0x0006, 0x0031, 0x009e, 0x000c,
  0x00ca, 0x006d, 0x0073, 0x0063, 0x0074, 0x006c, 0x0073, 0x005f,
  0x0070, 0x0072, 0x006f, 0x0067, 0x0072, 0x0065, 0x0073, 0x0073,
  0x0033, 0x0032, 0x0000, 0x0000, 0x0000, 0x0000,

  // DLGITEMTEMPLATE [Text Box]
  0x0000, 0x5081, 0x0000, 0x0000, 0x0014, 0x0032, 0x0064, 0x0014,
  0x00c9, 0xffff, 0x0081, 0x0000, 0x0000, 0x0000
];

void main() {
  test('Dialog creation returns the right results', () {
    final ptr = calloc<Uint16>(1024);
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
        text: '');

    expect(idx, equals(dialogGolden.length));
    expect(ptr.cast<Uint16>().asTypedList(idx), equals(dialogGolden));

    free(ptr);
  });
}
