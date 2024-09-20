// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

// `entry-point` needed to make sure the class will be in the class hierarchy
// in programs without records.
@pragma('wasm:entry-point')
@patch
abstract class Record {
  _RecordType get _masqueradedRecordRuntimeType;
  _RecordType get _recordRuntimeType;

  bool _checkRecordType(WasmArray<_Type> types, WasmArray<String> names);

  @pragma("wasm:prefer-inline")
  static _RecordType _getRecordRuntimeType(Record record) =>
      record._recordRuntimeType;

  @pragma("wasm:prefer-inline")
  static _RecordType _getMasqueradedRecordRuntimeType(Record record) =>
      record._masqueradedRecordRuntimeType;
}
