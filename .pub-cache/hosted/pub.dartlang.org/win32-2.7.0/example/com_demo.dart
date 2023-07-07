// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates COM object creation and casting from Dart

import 'dart:ffi';

import 'package:win32/win32.dart';

/// Return the current reference count.
int refCount(IUnknown unk) {
  // Call AddRef() and Release(), which are inherited from IUnknown. Both return
  // the refcount after the operation, so by adding a reference and immediately
  // removing it, we can get the original refcount.

  unk.AddRef();
  final refCount = unk.Release();

  return refCount;
}

void main() {
  final pTitle = TEXT('Dart Open File Dialog');

  // Initialize COM
  var hr = CoInitializeEx(
      nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
  if (FAILED(hr)) throw WindowsException(hr);

  // Create an instance of the FileOpenDialog class w/ IFileDialog interface
  final fileDialog2 = IFileDialog2(
      COMObject.createFromID(CLSID_FileOpenDialog, IID_IFileDialog2));
  print('Created fileDialog2.\n'
      'fileDialog2.ptr is  ${fileDialog2.ptr.address.toHexString(64)}');
  print('refCount is now ${refCount(fileDialog2)}\n');

  // Use IFileDialog2.SetTitle, which is inherited from IFileDialog
  hr = fileDialog2.SetTitle(pTitle);
  if (FAILED(hr)) throw WindowsException(hr);

  // Get the IModalWindow interface, just to demonstrate it.
  final modalWindow = IModalWindow(fileDialog2.toInterface(IID_IModalWindow));
  print('Get IModalWindow interface.\n'
      'modalWindow.ptr is ${modalWindow.ptr.address.toHexString(64)}');
  print('refCount is now ${refCount(modalWindow)}\n');

  fileDialog2.Release();
  free(fileDialog2.ptr);
  print('Release fileDialog2.\n'
      'refCount is now ${refCount(modalWindow)}\n');

  // Now get the IFileOpenDialog interface.
  final fileOpenDialog =
      IFileOpenDialog(modalWindow.toInterface(IID_IFileOpenDialog));

  print('Get IFileOpenDialog interface.\n'
      'fileOpenDialog.ptr is ${fileOpenDialog.ptr.address.toHexString(64)}');
  print('refCount is now ${refCount(fileOpenDialog)}\n');

  modalWindow.Release();
  free(modalWindow.ptr);
  print('Release modalWindow.\n'
      'refCount is now ${refCount(fileOpenDialog)}\n');

  // Use IFileOpenDialog.Show, which is inherited from IModalWindow
  hr = fileOpenDialog.Show(NULL);
  if (FAILED(hr)) {
    if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
      print('Dialog cancelled.');
    } else {
      throw WindowsException(hr);
    }
  }

  fileOpenDialog.Release();
  free(fileOpenDialog.ptr);
  print('Released fileOpenDialog.\n');

  // Uninitialize COM now that we're done with it.
  CoUninitialize();

  // Clear up
  free(pTitle);
  print('All done!');
}
