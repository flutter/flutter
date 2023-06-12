// ispellchecker.dart

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
import '../structs.g.dart';
import '../utils.dart';
import '../variant.dart';
import '../win32/ole32.g.dart';
import 'iunknown.dart';

/// @nodoc
const IID_ISpellChecker = '{B6FD0B71-E2BC-4653-8D05-F197E412770B}';

/// {@category Interface}
/// {@category com}
class ISpellChecker extends IUnknown {
  // vtable begins at 3, is 14 entries long.
  ISpellChecker(super.ptr);

  factory ISpellChecker.from(IUnknown interface) =>
      ISpellChecker(interface.toInterface(IID_ISpellChecker));

  Pointer<Utf16> get languageTag {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<Utf16>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<Utf16>> value)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int check(Pointer<Utf16> text, Pointer<Pointer<COMObject>> value) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> text,
                              Pointer<Pointer<COMObject>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> text,
                      Pointer<Pointer<COMObject>> value)>()(
          ptr.ref.lpVtbl, text, value);

  int suggest(Pointer<Utf16> word, Pointer<Pointer<COMObject>> value) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> word,
                              Pointer<Pointer<COMObject>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> word,
                      Pointer<Pointer<COMObject>> value)>()(
          ptr.ref.lpVtbl, word, value);

  int add(Pointer<Utf16> word) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Utf16> word)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> word)>()(ptr.ref.lpVtbl, word);

  int ignore(Pointer<Utf16> word) => ptr.ref.vtable
      .elementAt(7)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Utf16> word)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> word)>()(ptr.ref.lpVtbl, word);

  int autoCorrect(Pointer<Utf16> from, Pointer<Utf16> to) => ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Utf16> from, Pointer<Utf16> to)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> from, Pointer<Utf16> to)>()(
      ptr.ref.lpVtbl, from, to);

  int getOptionValue(Pointer<Utf16> optionId, Pointer<Uint8> value) =>
      ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> optionId,
                          Pointer<Uint8> value)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> optionId,
                  Pointer<Uint8> value)>()(ptr.ref.lpVtbl, optionId, value);

  Pointer<COMObject> get optionIds {
    final retValuePtr = calloc<Pointer<COMObject>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<COMObject>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<COMObject>> value)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  Pointer<Utf16> get id {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<Utf16>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<Utf16>> value)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  Pointer<Utf16> get localizedName {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(12)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<Utf16>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<Utf16>> value)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int add_SpellCheckerChanged(
          Pointer<COMObject> handler, Pointer<Uint32> eventCookie) =>
      ptr.ref.vtable
              .elementAt(13)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> handler,
                              Pointer<Uint32> eventCookie)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> handler,
                      Pointer<Uint32> eventCookie)>()(
          ptr.ref.lpVtbl, handler, eventCookie);

  int remove_SpellCheckerChanged(int eventCookie) => ptr.ref.vtable
      .elementAt(14)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Uint32 eventCookie)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, int eventCookie)>()(ptr.ref.lpVtbl, eventCookie);

  int getOptionDescription(
          Pointer<Utf16> optionId, Pointer<Pointer<COMObject>> value) =>
      ptr.ref.vtable
              .elementAt(15)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> optionId,
                              Pointer<Pointer<COMObject>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> optionId,
                      Pointer<Pointer<COMObject>> value)>()(
          ptr.ref.lpVtbl, optionId, value);

  int comprehensiveCheck(
          Pointer<Utf16> text, Pointer<Pointer<COMObject>> value) =>
      ptr.ref.vtable
              .elementAt(16)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> text,
                              Pointer<Pointer<COMObject>> value)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> text,
                      Pointer<Pointer<COMObject>> value)>()(
          ptr.ref.lpVtbl, text, value);
}
