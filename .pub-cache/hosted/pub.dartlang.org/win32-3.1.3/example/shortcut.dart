// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates using the COM IShellLink interface to create a shell shortcut.

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:args/args.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void createShortcut(String path, String pathLink, String? description) {
  final shellLink = ShellLink.createInstance();
  final lpPath = path.toNativeUtf16();
  final lpPathLink = pathLink.toNativeUtf16();
  final lpDescription = description?.toNativeUtf16() ?? nullptr;
  final ptrIID_IPersistFile = convertToCLSID(IID_IPersistFile);
  final ppf = calloc<COMObject>();

  try {
    shellLink.setPath(lpPath);
    if (description != null) shellLink.setDescription(lpDescription);

    final hr = shellLink.queryInterface(ptrIID_IPersistFile, ppf.cast());
    if (SUCCEEDED(hr)) {
      IPersistFile(ppf)
        ..save(lpPathLink, TRUE)
        ..release();
    }
    shellLink.release();
  } finally {
    free(lpPath);
    free(lpPathLink);
    if (lpDescription != nullptr) free(lpDescription);
    free(ptrIID_IPersistFile);
    free(ppf);
  }
}

void main(List<String> args) {
  final parser = ArgParser(usageLineLength: 80)
    ..addOption('path',
        abbr: 'p',
        mandatory: true,
        help:
            r'Absolute path for which to create a shortcut (e.g. c:\test.txt).')
    ..addOption('shortcut',
        abbr: 's',
        mandatory: true,
        help: 'The name of the shortcut (e.g. shortcut.lnk).')
    ..addOption('description',
        abbr: 'd', help: 'Optional description for the shortcut.');

  try {
    final results = parser.parse(args);
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    createShortcut(results['path'] as String, results['shortcut'] as String,
        results['description'] as String?);
    CoUninitialize();
  } on FormatException {
    print('Creates a Windows shortcut to a given file.\n');
    print('Usage: shortcut [arguments]\n');
    print(parser.usage);
  }
}
