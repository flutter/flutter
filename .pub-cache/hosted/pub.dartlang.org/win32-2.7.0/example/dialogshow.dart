// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opens the File Open dialog box and shows results

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  var hr = CoInitializeEx(
      nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

  if (SUCCEEDED(hr)) {
    final fileDialog = FileOpenDialog.createInstance();

    final pfos = calloc<Uint32>();
    hr = fileDialog.GetOptions(pfos);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final options = pfos.value | FILEOPENDIALOGOPTIONS.FOS_FORCEFILESYSTEM;
    hr = fileDialog.SetOptions(options);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final defaultExtensions = TEXT('txt;csv');
    hr = fileDialog.SetDefaultExtension(defaultExtensions);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);
    free(defaultExtensions);

    final fileNameLabel = TEXT('Custom Label:');
    hr = fileDialog.SetFileNameLabel(fileNameLabel);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);
    free(fileNameLabel);

    final title = TEXT('Custom Title');
    hr = fileDialog.SetTitle(title);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);
    free(title);

    final okButtonLabel = TEXT('Go');
    hr = fileDialog.SetOkButtonLabel(okButtonLabel);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);
    free(okButtonLabel);

    final rgSpec = calloc<COMDLG_FILTERSPEC>(3);
    rgSpec[0]
      ..pszName = TEXT('JPEG Files')
      ..pszSpec = TEXT('*.jpg;*.jpeg');
    rgSpec[1]
      ..pszName = TEXT('Bitmap Files')
      ..pszSpec = TEXT('*.bmp');
    rgSpec[2]
      ..pszName = TEXT('All Files (*.*)')
      ..pszSpec = TEXT('*.*');
    hr = fileDialog.SetFileTypes(3, rgSpec);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    hr = fileDialog.Show(NULL);
    if (!SUCCEEDED(hr)) {
      if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        print('Dialog cancelled.');
      } else {
        throw WindowsException(hr);
      }
    } else {
      final ppsi = calloc<COMObject>();
      hr = fileDialog.GetResult(ppsi.cast());
      if (!SUCCEEDED(hr)) throw WindowsException(hr);

      final item = IShellItem(ppsi);
      final pathPtr = calloc<Pointer<Utf16>>();
      hr = item.GetDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtr);
      if (!SUCCEEDED(hr)) throw WindowsException(hr);

      // MAX_PATH may truncate early if long filename support is enabled
      final path = pathPtr.value.toDartString();

      print('Result: $path');

      hr = item.Release();
      if (!SUCCEEDED(hr)) throw WindowsException(hr);
    }

    hr = fileDialog.Release();
    if (!SUCCEEDED(hr)) throw WindowsException(hr);
  } else {
    throw WindowsException(hr);
  }
  CoUninitialize();

  print('All done!');
}
