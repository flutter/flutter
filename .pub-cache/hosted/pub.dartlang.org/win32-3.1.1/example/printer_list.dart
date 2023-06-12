// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enumerates locally-connected printers.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class PrinterNames {
  final int _flags;

  PrinterNames(this._flags);

  Iterable<String> all() sync* {
    try {
      _getBufferSize();

      try {
        _readRawBuff();
        yield* parse();
      } finally {
        free(_rawBuffer);
      }
    } finally {
      free(_pBuffSize);
      free(_bPrinterLen);
    }
  }

  late Pointer<DWORD> _pBuffSize;
  late Pointer<DWORD> _bPrinterLen;

  void _getBufferSize() {
    _pBuffSize = calloc<DWORD>();
    _bPrinterLen = calloc<DWORD>();

    EnumPrinters(_flags, nullptr, 2, nullptr, 0, _pBuffSize, _bPrinterLen);

    if (_pBuffSize.value == 0) {
      throw 'Read printer buffer size fail';
    }
  }

  late Pointer<BYTE> _rawBuffer;

  void _readRawBuff() {
    _rawBuffer = malloc.allocate<BYTE>(_pBuffSize.value);

    final isRawBuffFail = EnumPrinters(_flags, nullptr, 2, _rawBuffer,
            _pBuffSize.value, _pBuffSize, _bPrinterLen) ==
        0;

    if (isRawBuffFail) {
      throw 'Read printer raw buffer fail';
    }
  }

  Iterable<String> parse() sync* {
    for (var i = 0; i < _bPrinterLen.value; i++) {
      final printer = _rawBuffer.cast<PRINTER_INFO_2>().elementAt(i);
      yield printer.ref.pPrinterName.toDartString();
    }
  }
}

void main() {
  final printerNames = PrinterNames(PRINTER_ENUM_LOCAL);
  try {
    for (final name in printerNames.all()) {
      print(name);
    }
  } catch (e) {
    stderr.writeln(e);
  }
}
