// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of zircon;

// ignore_for_file: native_function_body_in_non_sdk_code
// ignore_for_file: public_member_api_docs

@pragma('vm:entry-point')
class Handle extends NativeFieldWrapperClass1 {
  // No public constructor - this can only be created from native code.
  @pragma('vm:entry-point')
  Handle._();

  // Create an invalid handle object.
  factory Handle.invalid() {
    return _createInvalid();
  }
  static Handle _createInvalid() native 'Handle_CreateInvalid';

  int get handle native 'Handle_handle';

  int get koid native 'Handle_koid';

  @override
  String toString() => 'Handle($handle)';

  @override
  bool operator ==(Object other) {
    return other is Handle
        && other.handle == handle;
  }

  @override
  int get hashCode => handle.hashCode;

  // Common handle operations.
  bool get isValid native 'Handle_is_valid';
  int close() native 'Handle_Close';
  HandleWaiter asyncWait(int signals, AsyncWaitCallback callback)
      native 'Handle_AsyncWait';

  Handle duplicate(int rights) native 'Handle_Duplicate';

  Handle replace(int rights) native 'Handle_Replace';
}

@pragma('vm:entry-point')
class _OnWaitCompleteClosure {
  // No public constructor - this can only be created from native code.
  @pragma('vm:entry-point')
  _OnWaitCompleteClosure(this._callback, this._arg1, this._arg2);

  Function _callback;
  Object _arg1;
  Object _arg2;

  @pragma('vm:entry-point')
  Function get _closure => () => _callback(_arg1, _arg2);
}
