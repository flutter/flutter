// font.dart

// Font selection

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class NotepadFont {
  final logfont = calloc<LOGFONT>();
  late int hFont;

  NotepadFont(int hwndEdit) {
    final hSysFont = GetStockObject(SYSTEM_FONT);
    GetObject(hSysFont, sizeOf<LOGFONT>(), logfont);

    hFont = CreateFontIndirect(logfont);
    SendMessage(hwndEdit, WM_SETFONT, hFont, 0);
  }

  bool notepadChooseFont(int hwnd) {
    final cf = calloc<CHOOSEFONT>()
      ..ref.lStructSize = sizeOf<CHOOSEFONT>()
      ..ref.hwndOwner = hwnd
      ..ref.lpLogFont = logfont
      ..ref.Flags = CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS | CF_EFFECTS;

    final result = ChooseFont(cf);
    return result == TRUE;
  }

  void notepadSetFont(int hwndEdit) {
    int hFontNew;
    final rect = calloc<RECT>();

    hFontNew = CreateFontIndirect(logfont);

    SendMessage(hwndEdit, WM_SETFONT, hFontNew, FALSE);
    DeleteObject(hFont);
    hFont = hFontNew;

    GetClientRect(hwndEdit, rect);
    InvalidateRect(hwndEdit, rect, TRUE);

    free(rect);
  }

  void dispose() {
    DeleteObject(hFont);
  }
}
