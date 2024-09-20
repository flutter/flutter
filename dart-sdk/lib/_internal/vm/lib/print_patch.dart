// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

// A print-closure gets a String that should be printed. In general the
// string is a line, but it may contain "\n" characters.
typedef void _PrintClosure(String line);

@patch
void printToConsole(String line) {
  _printClosure(line);
}

void _unsupportedPrint(String line) {
  throw new UnsupportedError("'print' is not supported");
}

// _printClosure can be overwritten by the embedder to supply a different
// print implementation.
@pragma("vm:entry-point")
_PrintClosure _printClosure = _unsupportedPrint;
