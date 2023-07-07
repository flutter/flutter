// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions to minimize ceremony when calling WinRT APIs.

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'combase.dart';

typedef ApplicationDataSetVersionHandler = Void Function(
    Pointer<COMObject> setVersionRequest);
typedef AsyncActionCompletedHandler = Void Function(
    Pointer<COMObject> asyncInfo, Int32 asyncStatus);
typedef EventHandler = Void Function(
    Pointer<COMObject> sender, Pointer<COMObject> args);
typedef TypedEventHandler = Void Function(
    Pointer<COMObject> sender, Pointer<COMObject> args);
