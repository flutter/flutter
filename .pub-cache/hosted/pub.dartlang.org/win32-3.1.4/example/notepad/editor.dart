// editor.dart

// Represents the main editor
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'file.dart';
import 'font.dart';
import 'notepad.dart';
import 'resources.dart';

class NotepadEditor {
  // Handles to window and edit control. These don't change after the controls
  // are instantiated, so we take a copy here to minimize ceremony while an
  // instance is being used.
  final int _hwnd;
  final int _hwndEdit;

  final NotepadFile file;
  final NotepadFont font;

  NotepadEditor(this._hwnd, this._hwndEdit)
      : file = NotepadFile(_hwnd, '', ''),
        font = NotepadFont(_hwndEdit);

  void dispose() {
    font.dispose();
  }

  /// Does the current file in memory contain unsaved changes?
  bool isFileDirty = false;

  bool get isTextSelected {
    bool result;

    final iSelBeg = calloc<DWORD>();
    final iSelEnd = calloc<DWORD>();

    SendMessage(_hwndEdit, EM_GETSEL, iSelBeg.address, iSelEnd.address);

    result = iSelBeg.value != iSelEnd.value;

    free(iSelBeg);
    free(iSelEnd);

    return result;
  }

  void newFile() {
    file
      ..title = ''
      ..path = '';
    isFileDirty = false;
    updateWindowTitle();
  }

  void openFile() {
    if (isFileDirty && offerSave() == IDCANCEL) {
      return;
    }

    if (file.showOpenDialog(_hwnd)) {
      file.readFileIntoEditControl(_hwndEdit);
    }

    updateWindowTitle();
    isFileDirty = false;
  }

  bool saveFile() {
    if (file.path.isNotEmpty) {
      file.writeFileFromEditControl(_hwndEdit);
      isFileDirty = false;
      return true;
    }

    return saveAsFile();
  }

  bool saveAsFile() {
    if (file.showSaveDialog(_hwnd)) {
      updateWindowTitle();

      file.writeFileFromEditControl(_hwndEdit);
      isFileDirty = false;
      return true;
    }

    return false;
  }

  void setFont() {
    if (font.notepadChooseFont(_hwnd)) {
      font.notepadSetFont();
    }
  }

  void updateWindowTitle() {
    final caption =
        '$APP_NAME - ${file.title.isNotEmpty ? file.title : '(untitled)'}';
    SetWindowText(_hwnd, TEXT(caption));
  }

  void showMessage(String szMessage) {
    MessageBox(
        _hwnd, TEXT(szMessage), TEXT(APP_NAME), MB_OK | MB_ICONEXCLAMATION);
  }

  int offerSave() {
    final buffer = TEXT(file.title.isNotEmpty
        ? 'Save current changes in ${file.title}?'
        : 'Save changes to file?');
    final res = MessageBox(
        _hwnd, buffer, TEXT(APP_NAME), MB_YESNOCANCEL | MB_ICONQUESTION);

    if (res == IDYES) {
      if (SendMessage(_hwnd, WM_COMMAND, IDM_FILE_SAVE, 0) == FALSE) {
        return IDCANCEL;
      }
    }

    return res;
  }
}
