// ispellchecker2.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../guid.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';

import 'ispellchecker.dart';

/// @nodoc
const IID_ISpellChecker2 = '{E7ED1C71-87F7-4378-A840-C9200DACEE47}';

/// {@category Interface}
/// {@category com}
class ISpellChecker2 extends ISpellChecker {
  // vtable begins at 17, is 1 entries long.
  ISpellChecker2(super.ptr);

  int Remove(Pointer<Utf16> word) => ptr.ref.vtable
      .elementAt(17)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Utf16> word)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> word)>()(ptr.ref.lpVtbl, word);
}
