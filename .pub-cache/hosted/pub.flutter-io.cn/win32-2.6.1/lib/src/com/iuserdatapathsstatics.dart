// IUserDataPathsStatics.dart

// ignore_for_file: unused_import, camel_case_types, constant_identifier_names
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';

import '../winrt_constants.dart';

import 'iinspectable.dart';

/// @nodoc
const IID_IUserDataPathsStatics = '{01B29DEF-E062-48A1-8B0C-F2C7A9CA56C0}';

typedef _GetForUser_Native = Int32 Function(
    Pointer obj, Pointer user, Pointer<Pointer> result);
typedef _GetForUser_Dart = int Function(
    Pointer obj, Pointer user, Pointer<Pointer> result);

typedef _GetDefault_Native = Int32 Function(
    Pointer obj, Pointer<Pointer> result);
typedef _GetDefault_Dart = int Function(Pointer obj, Pointer<Pointer> result);

/// {@category Interface}
/// {@category winrt}
class IUserDataPathsStatics extends IInspectable {
  // vtable begins at 6, ends at 7

  IUserDataPathsStatics(Pointer<COMObject> ptr) : super(ptr);

  int GetForUser(Pointer user, Pointer<Pointer> result) => ptr.ref.lpVtbl.value
      .elementAt(6)
      .cast<Pointer<NativeFunction<_GetForUser_Native>>>()
      .value
      .asFunction<_GetForUser_Dart>()(ptr.ref.lpVtbl, user, result);

  int GetDefault(Pointer<Pointer> result) => ptr.ref.lpVtbl.value
      .elementAt(7)
      .cast<Pointer<NativeFunction<_GetDefault_Native>>>()
      .value
      .asFunction<_GetDefault_Dart>()(ptr.ref.lpVtbl, result);
}
