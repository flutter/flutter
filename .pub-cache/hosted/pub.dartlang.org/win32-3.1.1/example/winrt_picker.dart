// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// File Open Picker from Dart

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/winrt.dart';

void main() async {
  winrtInitialize();
  final pIndex = calloc<Uint32>();

  final picker = FileOpenPicker()
    ..suggestedStartLocation = PickerLocationId.desktop
    ..viewMode = PickerViewMode.thumbnail;

  final filters = picker.fileTypeFilter;

  print('Vector has ${filters.size} elements.');
  print('Adding ".jpg" to the vector...');
  filters.append('.jpg');
  print('Vector has ${filters.size} elements.');
  print('Vector\'s first element is ${filters.getAt(0)}.');
  print('Adding ".jpeg" to the vector...');
  filters.append('.jpeg');
  print('Vector\'s second element is ${filters.getAt(1)}.');

  final vectorView = filters.getView();
  print('VectorView has ${vectorView.length} elements.');

  var containsElement = filters.indexOf('.jpeg', pIndex);
  print(containsElement
      ? 'The index of ".jpeg" is ${pIndex.value}.'
      : 'The ".jpeg" does not exists in the vector!');

  containsElement = filters.indexOf('.txt', pIndex);
  print(containsElement
      ? 'The index of ".txt" is ${pIndex.value}.'
      : 'The ".txt" does not exists in the vector!');

  print('Setting vector\'s first element to ".png"...');
  filters.setAt(0, '.png');
  print('Vector\'s first element is ${filters.getAt(0)}.');

  print('Inserting ".gif" to the vector\'s first index...');
  filters.insertAt(0, '.gif');
  print('Vector has ${filters.size} elements.');
  print('Vector\'s first element is ${filters.getAt(0)}.');

  print('Removing the vector\'s last element...');
  filters.removeAtEnd();
  print('Vector has ${filters.size} elements.');
  print('Vector\'s last element is ${filters.getAt(filters.size - 1)}.');

  var list = filters.getView();
  print(list.isNotEmpty ? 'Vector elements: $list' : 'Vector is empty!');

  print('Replacing vector\'s elements with [".jpg", ".jpeg", ".png"]...');
  filters.replaceAll(['.jpg', '.jpeg', '.png']);

  list = filters.getView();
  print(list.isNotEmpty ? 'Vector elements: $list' : 'Vector is empty!');

  print('Clearing the vector...');
  filters.clear();
  print('Vector has ${filters.size} elements.');

  free(pIndex);
  free(filters.ptr);
  winrtUninitialize();
}
