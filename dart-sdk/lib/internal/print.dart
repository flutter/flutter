// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/**
 * This function is set by the first allocation of a Zone.
 *
 * Once the function is set the core `print` function calls this closure instead
 * of [printToConsole].
 *
 * This decouples the core library from the async library.
 */
void Function(String)? printToZone = null;

external void printToConsole(String line);
