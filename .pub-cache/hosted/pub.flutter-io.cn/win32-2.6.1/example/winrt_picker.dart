// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// File Open Picker from Dart

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() async {
  winrtInitialize();
  final pIndex = calloc<Uint32>();

  final object = CreateObject(
      'Windows.Storage.Pickers.FileOpenPicker', IID_IFileOpenPicker);

  final picker = IFileOpenPicker(object)
    ..SuggestedStartLocation = PickerLocationId.Desktop
    ..ViewMode = PickerViewMode.Thumbnail;

  final filters = picker.FileTypeFilter;

  print('Vector has ${filters.Size} elements.');
  print('Adding ".jpg" to the vector...');
  filters.Append('.jpg');
  print('Vector has ${filters.Size} elements.');
  print('Vector\'s first element is ${filters.GetAt(0)}.');
  print('Adding ".jpeg" to the vector...');
  filters.Append('.jpeg');
  print('Vector\'s second element is ${filters.GetAt(1)}.');

  final vectorView = filters.GetView;
  print('VectorView has ${vectorView.length} elements.');

  var containsElement = filters.IndexOf('.jpeg', pIndex);
  print(containsElement
      ? 'The index of ".jpeg" is ${pIndex.value}.'
      : 'The ".jpeg" does not exists in the vector!');

  containsElement = filters.IndexOf('.txt', pIndex);
  print(containsElement
      ? 'The index of ".txt" is ${pIndex.value}.'
      : 'The ".txt" does not exists in the vector!');

  print('Setting vector\'s first element to ".png"...');
  filters.SetAt(0, '.png');
  print('Vector\'s first element is ${filters.GetAt(0)}.');

  print('Inserting ".gif" to the vector\'s first index...');
  filters.InsertAt(0, '.gif');
  print('Vector has ${filters.Size} elements.');
  print('Vector\'s first element is ${filters.GetAt(0)}.');

  print('Removing the vector\'s last element...');
  filters.RemoveAtEnd();
  print('Vector has ${filters.Size} elements.');
  print('Vector\'s last element is ${filters.GetAt(filters.Size - 1)}.');

  var list = filters.GetView;
  print(list.isNotEmpty ? 'Vector elements: $list' : 'Vector is empty!');

  print('Replacing vector\'s elements with [".jpg", ".jpeg", ".png"]...');
  filters.ReplaceAll(['.jpg', '.jpeg', '.png']);

  list = filters.GetView;
  print(list.isNotEmpty ? 'Vector elements: $list' : 'Vector is empty!');

  print('Clearing the vector...');
  filters.Clear();
  print('Vector has ${filters.Size} elements.');

  free(pIndex);
  free(filters.ptr);
  winrtUninitialize();
}
