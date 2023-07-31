// IToastNotificationFactory.dart

// ignore_for_file: unused_import, directives_ordering, camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../com/iinspectable.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';
import '../winrt_constants.dart';

/// @nodoc
const IID_IToastNotificationFactory = '{04124B20-82C6-4229-B109-FD9ED4662B53}';

typedef _CreateToastNotification_Native = Int32 Function(
    Pointer obj, Pointer content, Pointer<Pointer> result);
typedef _CreateToastNotification_Dart = int Function(
    Pointer obj, Pointer content, Pointer<Pointer> result);

/// {@category Interface}
/// {@category winrt}
class IToastNotificationFactory extends IInspectable {
  // vtable begins at 6, ends at 6

  IToastNotificationFactory(Pointer<COMObject> ptr) : super(ptr);

  int CreateToastNotification(Pointer content, Pointer<Pointer> result) =>
      ptr.ref.lpVtbl.value
              .elementAt(6)
              .cast<Pointer<NativeFunction<_CreateToastNotification_Native>>>()
              .value
              .asFunction<_CreateToastNotification_Dart>()(
          ptr.ref.lpVtbl, content, result);
}
