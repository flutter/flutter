// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of zircon;

// ignore_for_file: native_function_body_in_non_sdk_code
// ignore_for_file: public_member_api_docs

@pragma('vm:entry-point')
class HandleDisposition extends NativeFieldWrapperClass1 {
  @pragma('vm:entry-point')
  HandleDisposition(int operation, Handle handle, int type, int rights) {
    _constructor(operation, handle, type, rights);
  }

  void _constructor(int operation, Handle handle, int type, int rights)
      native 'HandleDisposition_constructor';

  int get operation native 'HandleDisposition_operation';
  Handle get handle native 'HandleDisposition_handle';
  int get type native 'HandleDisposition_type';
  int get rights native 'HandleDisposition_rights';
  int get result native 'HandleDisposition_result';

  @override
  String toString() =>
      'HandleDisposition(operation=$operation, handle=$handle, type=$type, rights=$rights, result=$result)';
}
