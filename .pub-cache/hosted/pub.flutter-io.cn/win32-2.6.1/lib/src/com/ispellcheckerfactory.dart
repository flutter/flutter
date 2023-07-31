// ISpellCheckerFactory.dart

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

import 'iunknown.dart';

/// @nodoc
const IID_ISpellCheckerFactory = '{8E018A9D-2415-4677-BF08-794EA61F94BB}';

/// {@category Interface}
/// {@category com}
class ISpellCheckerFactory extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  ISpellCheckerFactory(Pointer<COMObject> ptr) : super(ptr);

  Pointer<COMObject> get SupportedLanguages {
    final retValuePtr = calloc<Pointer<COMObject>>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Pointer<COMObject>> value,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Pointer<COMObject>> value,
          )>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int IsSupported(
    Pointer<Utf16> languageTag,
    Pointer<Int32> value,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> languageTag,
            Pointer<Int32> value,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> languageTag,
            Pointer<Int32> value,
          )>()(
        ptr.ref.lpVtbl,
        languageTag,
        value,
      );

  int CreateSpellChecker(
    Pointer<Utf16> languageTag,
    Pointer<Pointer<COMObject>> value,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> languageTag,
            Pointer<Pointer<COMObject>> value,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> languageTag,
            Pointer<Pointer<COMObject>> value,
          )>()(
        ptr.ref.lpVtbl,
        languageTag,
        value,
      );
}

/// @nodoc
const CLSID_SpellCheckerFactory = '{7AB36653-1796-484B-BDFA-E74F1DB7C1DC}';

/// {@category com}
class SpellCheckerFactory extends ISpellCheckerFactory {
  SpellCheckerFactory(Pointer<COMObject> ptr) : super(ptr);

  factory SpellCheckerFactory.createInstance() {
    final ptr = calloc<COMObject>();
    final clsid = calloc<GUID>()..ref.setGUID(CLSID_SpellCheckerFactory);
    final iid = calloc<GUID>()..ref.setGUID(IID_ISpellCheckerFactory);

    try {
      final hr = CoCreateInstance(clsid, nullptr, CLSCTX_ALL, iid, ptr.cast());

      if (FAILED(hr)) throw WindowsException(hr);

      return SpellCheckerFactory(ptr);
    } finally {
      free(clsid);
      free(iid);
    }
  }
}
