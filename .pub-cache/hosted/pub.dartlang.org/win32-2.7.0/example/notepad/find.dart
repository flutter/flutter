// find.dart

// Find and replace routines.

// ignore_for_file: constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const MAX_STRING_LEN = 256;

class NotepadFind {
  late Pointer<FINDREPLACE> find;

  late Pointer<Utf16> szFindText;
  late Pointer<Utf16> szReplText;

  NotepadFind() {
    szFindText = wsalloc(MAX_STRING_LEN);
    szReplText = wsalloc(MAX_STRING_LEN);
    find = calloc<FINDREPLACE>();
  }

  int showFindDialog(int hwnd) {
    find.ref.lStructSize = sizeOf<FINDREPLACE>();
    find.ref.hwndOwner = hwnd;
    find.ref.Flags = FR_HIDEUPDOWN | FR_HIDEMATCHCASE | FR_HIDEWHOLEWORD;
    find.ref.lpstrFindWhat = szFindText;
    find.ref.wFindWhatLen = MAX_STRING_LEN;

    return FindText(find);
  }

  int showReplaceDialog(int hwnd) {
    find.ref.lStructSize = sizeOf<FINDREPLACE>();
    find.ref.hwndOwner = hwnd;
    find.ref.Flags = FR_HIDEUPDOWN | FR_HIDEMATCHCASE | FR_HIDEWHOLEWORD;
    find.ref.lpstrFindWhat = szFindText;
    find.ref.lpstrReplaceWith = szReplText;
    find.ref.wFindWhatLen = MAX_STRING_LEN;
    find.ref.wReplaceWithLen = MAX_STRING_LEN;

    return ReplaceText(find);
  }

  bool findTextInEditWindow(
      int hwndEdit, Pointer<Uint32> piSearchOffset, Pointer<FINDREPLACE> pfr) {
    int iLength;

    // Read in the edit document
    iLength = GetWindowTextLength(hwndEdit);

    final pDoc = wsalloc(iLength + 1);
    GetWindowText(hwndEdit, pDoc, iLength + 1);
    final strDoc = pDoc.toDartString();
    free(pDoc);

    // Search the document for the find string
    final toFind = pfr.ref.lpstrFindWhat.toDartString();
    final startOffset = strDoc.indexOf(toFind, piSearchOffset.value);
    if (startOffset == -1) return false;
    final endOffset = startOffset + toFind.length;

    // Set the start for the next search to be the end of the current one
    piSearchOffset.value = endOffset;

    SendMessage(hwndEdit, EM_SETSEL, startOffset, endOffset);
    SendMessage(hwndEdit, EM_SCROLLCARET, 0, 0);

    return true;
  }

  bool findNextTextInEditWindow(int hwndEdit, Pointer<Uint32> piSearchOffset) {
    final fr = calloc<FINDREPLACE>()..ref.lpstrFindWhat = szFindText;

    return findTextInEditWindow(hwndEdit, piSearchOffset, fr);
  }

  bool replaceTextInEditWindow(
      int hwndEdit, Pointer<Uint32> piSearchOffset, Pointer<FINDREPLACE> fr) {
    if (!findTextInEditWindow(hwndEdit, piSearchOffset, fr)) {
      return false;
    }
    SendMessage(hwndEdit, EM_REPLACESEL, 0, fr.ref.lpstrReplaceWith.address);

    return true;
  }

  bool findValidFind() => szFindText.toDartString().isNotEmpty;
}
