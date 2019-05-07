// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of zircon;

// ignore_for_file: native_function_body_in_non_sdk_code
// ignore_for_file: public_member_api_docs

@pragma('vm:entry-point')
class Handle extends NativeFieldWrapperClass2 {
  // No public constructor - this can only be created from native code.
  @pragma('vm:entry-point')
  Handle._();

  // Create an invalid handle object.
  factory Handle.invalid() {
    return _createInvalid();
  }
  static Handle _createInvalid() native 'Handle_CreateInvalid';

  int get _handle native 'Handle_handle';

  @override
  String toString() => 'Handle($_handle)';

  @override
  bool operator ==(Object other) =>
      (other is Handle) && (_handle == other._handle);

  @override
  int get hashCode => _handle.hashCode;

  // Common handle operations.
  bool get isValid native 'Handle_is_valid';
  int close() native 'Handle_Close';
  HandleWaiter asyncWait(int signals, AsyncWaitCallback callback)
      native 'Handle_AsyncWait';

  Handle duplicate(int rights) native 'Handle_Duplicate';
}
