// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' show Blob, Event, ImageData, Node, Window, WorkerGlobalScope;
import 'dart:indexed_db' show KeyRange;
import 'dart:_internal' show patch;
import 'dart:_foreign_helper' show JS;

@patch
bool isBrowserObject(dynamic o) =>
    o is Blob ||
    o is Event ||
    o is KeyRange ||
    o is ImageData ||
    o is Node ||
    o is Window ||
    o is WorkerGlobalScope;

@patch
Object convertFromBrowserObject(dynamic o) =>
    JS('Blob|Event|KeyRange|ImageData|Node|Window|WorkerGlobalScope', '#', o);
